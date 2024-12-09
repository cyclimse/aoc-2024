import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

import aoc/scuffed/debug

pub fn day1() {
  let assert Ok(input) = simplifile.read("./assets/day1.txt")
  io.println("Day1/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day1/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub fn parse_input(input: String) -> #(List(Int), List(Int)) {
  let lines = input |> string.trim |> string.split(on: "\n")
  let matrix =
    lines
    |> list.map(fn(line) {
      line
      |> string.trim
      |> string.split(on: " ")
      |> list.fold([], fn(acc, num) {
        // Ignore whitespaces between numbers
        int.parse(num) |> result.map(fn(x) { [x, ..acc] }) |> result.unwrap(acc)
      })
    })
  let #(left, right) =
    matrix
    |> list.fold(#([], []), fn(acc, next) {
      // Note: would have been cleaner to use list.unzip
      let #(left_tail, right_tail) = acc
      let assert [left, right] = list.take(next, 2)
      #([left, ..left_tail], [right, ..right_tail])
    })
  // Don't look into this too much :sadge:
  #(list.reverse(right), list.reverse(left))
}

fn dist(a: Int, b: Int) -> Int {
  int.absolute_value(a - b)
}

pub fn part1(input: String) -> Int {
  let #(left, right) = parse_input(input)
  let #(lsorted, rsorted) = #(
    list.sort(left, by: int.compare),
    list.sort(right, by: int.compare),
  )
  // Slightly overkill
  list.zip(lsorted, rsorted)
  |> list.fold(0, fn(acc, pair) { dist(pair.0, pair.1) + acc })
}

pub fn part2(input: String) -> Int {
  let #(left, right) = parse_input(input)
  // It looks like this can be solved with an histogram
  let hist =
    right
    |> list.fold(dict.new(), fn(hist, num) {
      // Genuinely amazed by this function
      dict.upsert(hist, num, fn(x) {
        case x {
          Some(i) -> i + 1
          None -> 1
        }
      })
    })
  left
  |> list.fold(0, fn(acc, num) {
    acc + num * { dict.get(hist, num) |> result.unwrap(0) }
  })
}
