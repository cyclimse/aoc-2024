import gleam/dict
import gleeunit/should

import aoc/day9.{Disk, File, Free}

const dummy_input = "12345"

const example_input = "2333133121414131402"

pub fn parse_input_test() {
  let got_disk = day9.parse_input(dummy_input)
  let expected_disk =
    Disk(
      infos: dict.from_list([
        #(0, File(id: 0, length: 1)),
        #(1, Free(length: 2)),
        #(3, File(id: 1, length: 3)),
        #(6, Free(length: 4)),
        #(10, File(id: 2, length: 5)),
      ]),
      lookup_by_id: dict.from_list([
        #(0, #(0, 1)),
        #(1, #(3, 3)),
        #(2, #(10, 5)),
      ]),
      size: 15,
      maxid: 2,
    )
  got_disk |> should.equal(expected_disk)
}

pub fn part2_test() {
  day9.part2(example_input) |> should.equal(2858)
}
