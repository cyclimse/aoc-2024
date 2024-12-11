import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

import simplifile

import aoc/scuffed/debug
import aoc/scuffed/grid.{type Grid}

pub fn day10() {
  let assert Ok(input) = simplifile.read("./assets/day10.txt")
  io.println("Day10/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day10/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub fn parse_input_to_grid(input: String) -> Grid(Int) {
  let tiles =
    input
    |> string.trim
    |> string.split(on: "\n")
    |> list.fold([], fn(tiles, line) {
      let next_line =
        line
        |> string.to_graphemes
        |> list.fold([], fn(row, char) {
          [char |> int.parse |> result.unwrap(0), ..row]
        })
        |> list.reverse
      [next_line, ..tiles]
    })
  tiles |> list.reverse |> grid.must_from_list
}

pub fn build_adjacency_list(
  grid: Grid(Int),
) -> Dict(#(Int, Int), List(#(Int, Int))) {
  grid
  |> grid.iterate_with_index
  |> yielder.fold(dict.new(), fn(d, x) {
    let #(#(i, j), tile) = x
    let neighbors =
      grid
      |> grid.neighbors_of(i, j)
      |> list.filter_map(fn(neigh) {
        let #(neigh_tile, #(xx, yy)) = neigh
        // We can only go from a tile to a neighbor if neighbor - tile = 1
        // ie. we can only go from 1 to 2, 2 to 3, etc.
        case neigh_tile - tile {
          1 -> Ok(#(xx, yy))
          _ -> Error(Nil)
        }
      })
    dict.insert(d, #(i, j), neighbors)
  })
}

pub fn simple_dfs(
  grid: Grid(Int),
  adjacency_list: Dict(#(Int, Int), List(#(Int, Int))),
  start: #(Int, Int),
) -> Set(#(Int, Int)) {
  simple_dfs_inner(grid, adjacency_list, start, set.new())
}

fn simple_dfs_inner(
  grid: Grid(Int),
  adjacency_list: Dict(#(Int, Int), List(#(Int, Int))),
  start: #(Int, Int),
  visited: Set(#(Int, Int)),
) -> Set(#(Int, Int)) {
  let neighbors = adjacency_list |> dict.get(start)
  case neighbors {
    Error(_) -> visited
    Ok(neigh) -> {
      let visited = set.insert(visited, start)
      neigh
      |> list.fold(visited, fn(visited, neigh) {
        case set.contains(visited, neigh) {
          True -> visited
          False -> simple_dfs_inner(grid, adjacency_list, neigh, visited)
        }
      })
    }
  }
}

pub fn part1(input: String) -> Int {
  let heights = parse_input_to_grid(input)
  let adjacency_list = build_adjacency_list(heights)
  // For every 0 in the grid, go through the adjacency list and find all paths to 9
  heights
  |> grid.iterate_with_index
  |> yielder.fold(0, fn(acc, x) {
    let #(#(i, j), tile) = x
    case tile {
      0 -> {
        let visited = simple_dfs(heights, adjacency_list, #(i, j))
        let next =
          visited
          |> set.to_list
          |> list.count(where: fn(coords) {
            let #(i, j) = coords
            case grid.get(heights, i, j) {
              Ok(9) -> True
              _ -> False
            }
          })
        acc + next
      }
      _ -> acc
    }
  })
}

// In this search, we don't want to give up if we've already visited a node
// We want to count every path that leads to 9 from start
fn simple_dfs_with_loops(
  grid: Grid(Int),
  adjacency_list: Dict(#(Int, Int), List(#(Int, Int))),
  start: #(Int, Int),
) -> Int {
  let #(i, j) = start
  // If start is 9, we've found a path -> we can increment the counter and return
  case grid.get(grid, i, j) {
    Ok(9) -> 1
    _ -> {
      let neighbors = adjacency_list |> dict.get(start)
      case neighbors {
        Error(_) -> 0
        Ok(neigh) ->
          neigh
          |> list.map(simple_dfs_with_loops(grid, adjacency_list, _))
          |> int.sum
      }
    }
  }
}

pub fn part2(input: String) -> Int {
  let heights = parse_input_to_grid(input)
  let adjacency_list = build_adjacency_list(heights)
  heights
  |> grid.iterate_with_index
  |> yielder.fold(0, fn(acc, x) {
    let #(#(i, j), tile) = x
    case tile {
      0 -> acc + simple_dfs_with_loops(heights, adjacency_list, #(i, j))
      _ -> acc
    }
  })
}
