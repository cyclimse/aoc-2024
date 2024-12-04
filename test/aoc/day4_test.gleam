import glearray.{type Array}
import gleeunit/should

import aoc/day4

const dummy_input = "..X...
.SAMX.
.A..A.
XMAS.S
.X...."

const example_input = "MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
"

fn get_simple_matrix() -> Array(Array(String)) {
  glearray.from_list([
    glearray.from_list(["a", "b", "c"]),
    glearray.from_list(["d", "e", "f"]),
    glearray.from_list(["g", "h", "i"]),
  ])
}

pub fn parse_input_test() {
  let got = day4.parse_input(dummy_input)
  let expected =
    glearray.from_list([
      glearray.from_list([".", ".", "X", ".", ".", "."]),
      glearray.from_list([".", "S", "A", "M", "X", "."]),
      glearray.from_list([".", "A", ".", ".", "A", "."]),
      glearray.from_list(["X", "M", "A", "S", ".", "S"]),
      glearray.from_list([".", "X", ".", ".", ".", "."]),
    ])
  got |> should.equal(expected)
}

pub fn read_rows_test() {
  let got = day4.read_rows(get_simple_matrix())
  let expected = ["abc", "def", "ghi"]
  got |> should.equal(expected)
}

pub fn read_columns_test() {
  let got = day4.read_columns(get_simple_matrix())
  let expected = ["ifc", "heb", "gda"]
  got |> should.equal(expected)
}

pub fn read_diagonals_test() {
  let got = day4.read_diagonals(get_simple_matrix())
  let expected = ["c", "fb", "iea", "hd", "g", "i", "fh", "ceg", "bd", "a"]
  got |> should.equal(expected)
}

pub fn part1_test() {
  day4.part1(example_input) |> should.equal(18)
}

pub fn list_3x3_children_test() {
  // First case: should behave as identity when provided a 3x3 matrix
  let matrix = get_simple_matrix()
  let got = day4.list_3x3_children(matrix)
  let expected = [
    glearray.from_list([
      glearray.from_list(["a", "b", "c"]),
      glearray.from_list(["d", "e", "f"]),
      glearray.from_list(["g", "h", "i"]),
    ]),
  ]
  got |> should.equal(expected)

  // Second case: should return 4 3x3 matrices when provided a 4x4 matrix
  let matrix =
    glearray.from_list([
      glearray.from_list(["a", "b", "c", "d"]),
      glearray.from_list(["e", "f", "g", "h"]),
      glearray.from_list(["i", "j", "k", "l"]),
      glearray.from_list(["m", "n", "o", "p"]),
    ])
  let got = day4.list_3x3_children(matrix)
  let expected = [
    glearray.from_list([
      glearray.from_list(["a", "b", "c"]),
      glearray.from_list(["e", "f", "g"]),
      glearray.from_list(["i", "j", "k"]),
    ]),
    glearray.from_list([
      glearray.from_list(["b", "c", "d"]),
      glearray.from_list(["f", "g", "h"]),
      glearray.from_list(["j", "k", "l"]),
    ]),
    glearray.from_list([
      glearray.from_list(["e", "f", "g"]),
      glearray.from_list(["i", "j", "k"]),
      glearray.from_list(["m", "n", "o"]),
    ]),
    glearray.from_list([
      glearray.from_list(["f", "g", "h"]),
      glearray.from_list(["j", "k", "l"]),
      glearray.from_list(["n", "o", "p"]),
    ]),
  ]
  got |> should.equal(expected)
}

pub fn part2_test() {
  day4.part2(example_input) |> should.equal(9)
}
