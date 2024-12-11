import gleeunit/should

import aoc/day11

const example_input = "125 17"

pub fn number_of_digits_test() {
  day11.number_of_digits(123) |> should.equal(3)
  day11.number_of_digits(0) |> should.equal(1)
}

pub fn split_number_in_two_test() {
  day11.split_number_in_two(1234) |> should.equal(#(12, 34))
  day11.split_number_in_two(12_345) |> should.equal(#(12, 345))
}

pub fn part1_test() {
  day11.part1(example_input) |> should.equal(55_312)
}
