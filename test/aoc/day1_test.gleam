import gleeunit/should

import aoc/day1

const example_input = "3   4
4   3
2   5
1   3
3   9
3   3"

pub fn parse_input_test() {
  let #(left, right) = day1.parse_input(example_input)
  left |> should.equal([3, 4, 2, 1, 3, 3])
  right |> should.equal([4, 3, 5, 3, 9, 3])
}

pub fn part1_test() {
  day1.part1(example_input) |> should.equal(11)
}

pub fn part2_test() {
  day1.part2(example_input) |> should.equal(31)
}
