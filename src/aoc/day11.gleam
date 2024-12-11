import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/yielder.{Done, Next}

import simplifile

import aoc/scuffed/debug

pub fn day11() {
  let assert Ok(input) = simplifile.read("./assets/day11.txt")
  io.println("Day11/part1: " <> debug.run_and_time(part1, input, int.to_string))
  io.println("Day11/part2: " <> debug.run_and_time(part2, input, int.to_string))
}

pub fn number_of_digits(n: Int) -> Int {
  use <- bool.guard(when: n == 0, return: 1)
  let yield = fn(acc) {
    case acc {
      0 -> Done
      _ -> Next(element: acc % 10, accumulator: acc / 10)
    }
  }
  yielder.unfold(n, yield) |> yielder.length
}

pub fn split_number_in_two(n: Int) -> #(Int, Int) {
  let yield = fn(acc) {
    case acc {
      0 -> Done
      _ -> Next(element: acc % 10, accumulator: acc / 10)
    }
  }
  let digits = yielder.unfold(n, yield) |> yielder.to_list |> list.reverse
  let len = list.length(digits)
  let half = len / 2
  let first_half =
    digits
    |> list.take(half)
    |> list.fold(0, fn(acc, d) { acc * 10 + d })
  let second_half =
    digits |> list.drop(half) |> list.fold(0, fn(acc, d) { acc * 10 + d })
  #(first_half, second_half)
}

pub fn blink_once(stones: List(Int)) -> List(Int) {
  stones
  |> list.fold([], fn(next_stones, stone) {
    use <- bool.guard(when: stone == 0, return: [1, ..next_stones])
    case number_of_digits(stone) % 2 {
      0 -> {
        let #(first_half, second_half) = split_number_in_two(stone)
        [first_half, second_half, ..next_stones]
      }
      _ -> [2024 * stone, ..next_stones]
    }
  })
  |> list.reverse
}

fn increment(stones: Dict(Int, Int), stone: Int, by: Int) -> Dict(Int, Int) {
  dict.upsert(stones, stone, fn(x) {
    case x {
      None -> by
      Some(n) -> n + by
    }
  })
}

pub fn dict_blink_once(stones: Dict(Int, Int)) -> Dict(Int, Int) {
  stones
  |> dict.fold(dict.new(), fn(next, stone, number_of_stones) {
    use <- bool.guard(
      when: stone == 0,
      return: increment(next, 1, number_of_stones),
    )
    case number_of_digits(stone) % 2 {
      0 -> {
        let #(first_half, second_half) = split_number_in_two(stone)
        increment(
          increment(next, first_half, number_of_stones),
          second_half,
          number_of_stones,
        )
      }
      _ -> increment(next, 2024 * stone, number_of_stones)
    }
  })
}

pub fn part1(input: String) -> Int {
  let stones = case
    {
      input
      |> string.trim
      |> string.split(on: " ")
      |> list.map(int.parse)
      |> result.all
    }
  {
    Ok(l) -> l
    Error(_) -> panic as "Unable to parse input"
  }
  list.range(1, 25)
  |> list.fold(stones, fn(acc, _) { blink_once(acc) })
  |> list.length
}

pub fn part2(input: String) -> Int {
  let stones = case
    {
      input
      |> string.trim
      |> string.split(on: " ")
      |> list.map(int.parse)
      |> result.all
    }
  {
    Ok(l) -> l
    Error(_) -> panic as "Unable to parse input"
  }
  let stones_dict =
    stones |> list.fold(dict.new(), fn(d, x) { increment(d, x, 1) })
  list.range(1, 75)
  |> list.fold(stones_dict, fn(acc, _) { dict_blink_once(acc) })
  |> dict.values
  |> int.sum
}
