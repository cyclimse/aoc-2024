import gleeunit/should

import aoc/day6

const example_input = "....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#..."

pub fn part1_test() {
  day6.part1(example_input) |> should.equal(41)
}

pub fn part2_test() {
  day6.part2(example_input) |> should.equal(6)
}
