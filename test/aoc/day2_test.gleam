import gleeunit/should

import aoc/day2

const example_input = "7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9"

pub fn part1_test() {
  day2.part1(example_input) |> should.equal(2)
}

pub fn part2_test() {
  day2.part2(example_input) |> should.equal(4)
}
