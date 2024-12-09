import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result

import gleam/regexp
import simplifile

import aoc/scuffed/debug

pub fn day3() {
  let assert Ok(input) = simplifile.read("./assets/day3.txt")
  io.println("Day3/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day3/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub fn part1(input: String) -> Int {
  let assert Ok(re) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")
  let matches = regexp.scan(with: re, content: input)
  matches
  |> list.fold(0, fn(acc, match) {
    let regexp.Match(_, groups) = match
    let assert [Some(a), Some(b)] = groups
    { int.parse(a) |> result.unwrap(0) }
    * { int.parse(b) |> result.unwrap(0) }
    + acc
  })
}

type State {
  State(acc: Int, enabled: Bool)
}

pub fn part2(input: String) -> Int {
  let assert Ok(re) =
    regexp.from_string("(mul\\((\\d+),(\\d+)\\)|don't\\(\\)|do\\(\\))")
  let matches = regexp.scan(with: re, content: input)
  let State(solution, ..) =
    matches
    |> list.fold(State(acc: 0, enabled: True), fn(state, match) {
      let regexp.Match(prop, groups) = match
      case prop, state {
        "do()", State(enabled: False, ..) -> State(..state, enabled: True)
        "don't()", State(enabled: True, ..) -> State(..state, enabled: False)
        "do()", _ -> state
        "don't()", _ -> state
        _, State(acc: acc, enabled: True) -> {
          let assert [_, Some(a), Some(b)] = groups
          let mul =
            { int.parse(a) |> result.unwrap(0) }
            * { int.parse(b) |> result.unwrap(0) }
            + acc
          State(..state, acc: mul)
        }
        _, _ -> state
      }
    })
  solution
}
