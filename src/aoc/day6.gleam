import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/task
import gleam/result
import gleam/set.{type Set}
import gleam/string
import glearray.{type Array}

import simplifile

pub fn day6() {
  let assert Ok(input) = simplifile.read("./assets/day6.txt")
  io.println("Day6/part1: " <> { part1(input) |> int.to_string })
  io.println("Day6/part2: " <> { part2(input) |> int.to_string })
}

pub type Direction {
  North
  East
  South
  West
}

fn turn_right_90_degrees(direction: Direction) -> Direction {
  case direction {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}

pub type Tile {
  Empty
  Obstacle
  Guard(direction: Direction)
}

pub fn parse_input(input: String) -> Array(Array(Tile)) {
  let tiles =
    input
    |> string.trim
    |> string.split(on: "\n")
    |> list.fold([], fn(tiles, line) {
      let next_line =
        line
        |> string.to_graphemes
        |> list.fold([], fn(row, char) {
          case char {
            "." -> [Empty, ..row]
            "#" -> [Obstacle, ..row]
            "^" -> [Guard(North), ..row]
            ">" -> [Guard(East), ..row]
            "v" -> [Guard(South), ..row]
            "<" -> [Guard(West), ..row]
            _ -> row
          }
        })
        |> list.reverse
        |> glearray.from_list
      [next_line, ..tiles]
    })
  tiles |> list.reverse |> glearray.from_list
}

fn dimensions(matrix: Array(Array(a))) -> #(Int, Int) {
  let rows = matrix |> glearray.length
  let assert Ok(first_row) = glearray.get(matrix, 0)
  #(rows, first_row |> glearray.length)
}

fn find_initial_guard(tiles: Array(Array(Tile))) -> #(Int, Int, Direction) {
  let #(rows, cols) = dimensions(tiles)
  list.range(0, rows - 1)
  |> list.fold(#(0, 0, North), fn(pos, i) {
    let assert Ok(row) = glearray.get(tiles, i)
    list.range(0, cols - 1)
    |> list.fold(pos, fn(pos, j) {
      let assert Ok(tile) = glearray.get(row, j)
      case tile {
        Guard(direction:) -> #(i, j, direction)
        _ -> pos
      }
    })
  })
}

fn step_once(
  tiles: Array(Array(Tile)),
  i: Int,
  j: Int,
  direction: Direction,
) -> #(Int, Int, Direction, Bool) {
  let #(next_i, next_j) = case direction {
    North -> #(i - 1, j)
    East -> #(i, j + 1)
    South -> #(i + 1, j)
    West -> #(i, j - 1)
  }
  let maybe_next_tile =
    glearray.get(tiles, next_i)
    |> result.map(fn(row) { glearray.get(row, next_j) })
    |> result.flatten
  case maybe_next_tile {
    // I'm a bit lazy so I will not clean up the previous guard position
    Ok(Empty) | Ok(Guard(_)) -> #(next_i, next_j, direction, True)
    Ok(Obstacle) -> #(i, j, turn_right_90_degrees(direction), True)
    // In case of out of bounds; we're done
    Error(_) -> #(i, j, direction, False)
  }
}

fn step_until_done(
  tiles: Array(Array(Tile)),
  visited: Dict(#(Int, Int), Bool),
  i: Int,
  j: Int,
  direction: Direction,
) -> Dict(#(Int, Int), Bool) {
  let #(next_i, next_j, next_direction, continue) =
    step_once(tiles, i, j, direction)
  let updated_visited = dict.insert(visited, #(i, j), True)
  case continue {
    True -> {
      step_until_done(tiles, updated_visited, next_i, next_j, next_direction)
    }
    False -> updated_visited
  }
}

pub fn part1(input: String) -> Int {
  let tiles = parse_input(input)
  let #(i, j, direction) = find_initial_guard(tiles)
  let visited = step_until_done(tiles, dict.new(), i, j, direction)
  dict.size(visited)
}

fn do_update(
  visited: Dict(#(Int, Int), Set(Direction)),
  i: Int,
  j: Int,
  direction: Direction,
) -> Dict(#(Int, Int), Set(Direction)) {
  dict.upsert(visited, #(i, j), fn(x) {
    case x {
      Some(already) -> already |> set.insert(direction)
      None -> set.new() |> set.insert(direction)
    }
  })
}

// The twist is to identify when the guard is looping in a cycle
// To identify cycles, we add the direction to the visited dict
// -> If we've visited the same position with the same direction, we're in a cycle
fn step_until_done_part2(
  tiles: Array(Array(Tile)),
  visited: Dict(#(Int, Int), Set(Direction)),
  i: Int,
  j: Int,
  direction: Direction,
) -> #(Dict(#(Int, Int), Set(Direction)), Bool) {
  // print_tiles_with_guard(tiles, i, j, direction)
  let updated_visited = do_update(visited, i, j, direction)
  let #(next_i, next_j, next_direction, continue) =
    step_once(tiles, i, j, direction)
  case dict.get(visited, #(next_i, next_j)) {
    // We've visited the same position with the same direction -> cycle
    Ok(already) -> {
      case set.contains(already, next_direction) {
        True -> #(updated_visited, True)
        False if continue -> {
          step_until_done_part2(
            tiles,
            updated_visited,
            next_i,
            next_j,
            next_direction,
          )
        }
        False -> #(updated_visited, False)
      }
    }
    _ if continue -> {
      step_until_done_part2(
        tiles,
        updated_visited,
        next_i,
        next_j,
        next_direction,
      )
    }
    _ -> #(updated_visited, False)
  }
}

pub fn part2(input: String) -> Int {
  let tiles = parse_input(input)
  let #(initial_i, initial_j, direction) = find_initial_guard(tiles)

  // Map out the visited position with no obstruction
  let visited =
    step_until_done(tiles, dict.new(), initial_i, initial_j, direction)

  visited
  |> dict.to_list
  |> list.map(fn(x) {
    task.async(fn() {
      let #(#(i, j), _) = x
      // We update the tiles to place a potential obstacle
      let updated_tiles = {
        let assert Ok(row) = glearray.get(tiles, i)
        let assert Ok(updated_row) = glearray.copy_set(row, j, Obstacle)
        let assert Ok(updated_tiles) = glearray.copy_set(tiles, i, updated_row)
        updated_tiles
      }

      let #(_, is_looping) =
        step_until_done_part2(
          updated_tiles,
          dict.new(),
          initial_i,
          initial_j,
          direction,
        )

      is_looping
    })
  })
  |> list.map(task.await_forever)
  |> list.count(fn(x) { x })
}
