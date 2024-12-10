import gleeunit/should

import aoc/day10

const example_input = "89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"

pub fn part1_test() {
  day10.part1(example_input) |> should.equal(36)
}

pub fn part2_test() {
  day10.part2(example_input) |> should.equal(81)
}
