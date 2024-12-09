import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

import aoc/scuffed/debug

pub fn day2() {
  let assert Ok(input) = simplifile.read("./assets/day2.txt")
  io.println("Day2/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day2/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub fn parse_input(input: String) -> List(List(Int)) {
  let lines = input |> string.trim |> string.split(on: "\n")
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
}

// Copied from day1
fn dist(a: Int, b: Int) -> Int {
  int.absolute_value(a - b)
}

type Level {
  Increasing
  Decreasing
}

type State {
  Safe(level: Level, dampened: Bool)
  Unsafe
  Unknown
}

fn report_is_safe(report: List(Int)) -> Bool {
  let final =
    list.window_by_2(report)
    |> list.fold(Unknown, fn(state, pair) {
      let #(a, b) = pair
      let d = dist(a, b)
      case state, d {
        Unsafe, _ -> Unsafe
        _, _ if d == 0 || d > 3 -> Unsafe
        Safe(Decreasing, ..), _ if a - b > 0 -> Safe(Decreasing, False)
        Safe(Increasing, ..), _ if b - a > 0 -> Safe(Increasing, False)
        Unknown, _ if a - b > 0 -> Safe(Decreasing, False)
        Unknown, _ if b - a > 0 -> Safe(Increasing, False)
        _, _ -> Unsafe
      }
    })
  case final {
    Safe(..) -> True
    _ -> False
  }
}

pub fn part1(input: String) -> Int {
  parse_input(input)
  // With part2, I realize now that I'm reading the reports right to left
  // Thankfully, it doesn't affect the results as there's no asymmetry between inc/dec
  |> list.count(fn(report) { report_is_safe(report) })
}

type State2 {
  State2(front: List(Int), safe: Bool)
}

// This has to be the worst possible way to do this
// Not only this is brute-force, but the implementation of this brute-force is bad
fn report_is_safe2(report: List(Int)) -> Bool {
  report_is_safe(report)
  || {
    let final =
      list.index_fold(report, State2([], False), fn(state, item, index) {
        case state {
          State2(front, True) -> State2(front, True)
          State2(front, False) -> {
            let tail = list.drop(report, index + 1)
            let rmed = list.append(list.reverse(front), tail)
            case report_is_safe(rmed) {
              True -> State2(front, True)
              False -> State2([item, ..front], False)
            }
          }
        }
      })
    case final {
      State2(_, True) -> True
      _ -> False
    }
  }
}

pub fn part2(input: String) -> Int {
  parse_input(input)
  |> list.count(fn(report) { report_is_safe2(report) })
}
