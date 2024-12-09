import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/task
import gleam/set
import gleam/string
import gleam/yielder

import simplifile

import aoc/scuffed/debug
import aoc/scuffed/grid.{type Grid}

pub fn day8() {
  let assert Ok(input) = simplifile.read("./assets/day8.txt")
  io.println("Day8/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day8/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub type Tile {
  Empty

  Antinode
  Antenna(frequency: String)
}

pub fn parse_input(input: String) -> Grid(Tile) {
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
            _ -> [Antenna(char), ..row]
          }
        })
        |> list.reverse
      [next_line, ..tiles]
    })
  tiles |> list.reverse |> grid.must_from_list
}

pub fn find_antennas_by_frequency(
  tiles: Grid(Tile),
) -> Dict(String, List(#(Int, Int))) {
  tiles
  |> grid.iterate_with_index
  |> yielder.fold(dict.new(), fn(d, x) {
    let #(#(i, j), tile) = x
    case tile {
      Antenna(frequency) ->
        dict.upsert(d, frequency, fn(x) {
          case x {
            Some(already) -> [#(i, j), ..already]
            None -> [#(i, j)]
          }
        })
      _ -> d
    }
  })
}

fn collinear(x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int) -> Bool {
  { y3 - y2 } * { x2 - x1 } == { y2 - y1 } * { x3 - x2 }
}

fn is_point_along_line(
  point: #(Int, Int),
  antenna1: #(Int, Int),
  antenna2: #(Int, Int),
) -> Bool {
  let #(x1, y1) = point
  let #(x2, y2) = antenna1
  let #(x3, y3) = antenna2
  collinear(x1, y1, x2, y2, x3, y3)
}

fn distance_squared_between_two_points(
  point1: #(Int, Int),
  point2: #(Int, Int),
) -> Int {
  let #(x1, y1) = point1
  let #(x2, y2) = point2
  let x_diff = x2 - x1
  let y_diff = y2 - y1
  x_diff * x_diff + y_diff * y_diff
}

fn is_point_antinode(
  point: #(Int, Int),
  antenna1: #(Int, Int),
  antenna2: #(Int, Int),
) -> Bool {
  let distance1 = distance_squared_between_two_points(point, antenna1)
  let distance2 = distance_squared_between_two_points(point, antenna2)
  // When one of the antennas is twice as far away as the other
  { distance1 / distance2 == 4 } || { distance2 / distance1 == 4 }
}

type Condition =
  fn(#(Int, Int), #(Int, Int), #(Int, Int)) -> Bool

pub fn find_antinodes_between_two_antennas(
  bounds: #(Int, Int),
  antenna1: #(Int, Int),
  antenna2: #(Int, Int),
  conditions: List(Condition),
) -> List(#(Int, Int)) {
  let #(rows, cols) = bounds
  list.range(0, rows - 1)
  |> list.fold([], fn(antinodes, i) {
    list.range(0, cols - 1)
    |> list.fold(antinodes, fn(antinodes, j) {
      let point = #(i, j)
      case
        list.all(conditions, fn(condition) {
          condition(point, antenna1, antenna2)
        })
      {
        True -> [#(i, j), ..antinodes]
        False -> antinodes
      }
    })
  })
}

fn solve(input: String, conditions: List(Condition)) -> Int {
  let tiles = parse_input(input)
  let bounds = grid.dimensions(tiles)
  let antennas_by_frequency = find_antennas_by_frequency(tiles)
  let antinodes =
    antennas_by_frequency
    |> dict.to_list
    |> list.fold(set.new(), fn(all, pair) {
      let #(_, antennas) = pair
      antennas
      |> list.combination_pairs
      |> list.map(fn(pair) {
        task.async(fn() {
          let #(antenna1, antenna2) = pair
          find_antinodes_between_two_antennas(
            bounds,
            antenna1,
            antenna2,
            conditions,
          )
        })
      })
      |> list.map(task.await_forever)
      |> list.fold(all, fn(all, antinodes) {
        antinodes |> set.from_list |> set.union(all)
      })
    })
  antinodes |> set.size
}

pub fn part1(input: String) -> Int {
  solve(input, [is_point_along_line, is_point_antinode])
}

pub fn part2(input: String) -> Int {
  solve(input, [is_point_along_line])
}
