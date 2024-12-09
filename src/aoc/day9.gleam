import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/yielder.{Done, Next}

import simplifile

pub fn day9() {
  let assert Ok(input) = simplifile.read("./assets/day9.txt")
  io.println("Day9/part2: " <> { part2(input) |> int.to_string })
}

pub type Disk {
  Disk(
    infos: Dict(Int, DiskInfo),
    lookup_by_id: Dict(Int, #(Int, Int)),
    size: Int,
    maxid: Int,
  )
}

pub type DiskInfo {
  File(id: Int, length: Int)
  Free(length: Int)
}

pub fn parse_input(input: String) -> Disk {
  input
  |> string.trim
  |> string.to_graphemes
  |> list.index_fold(Disk(dict.new(), dict.new(), 0, 0), fn(disk, char, i) {
    let Disk(infos, lookup_by_id, size, maxid) = disk
    let num = case int.parse(char) {
      Ok(n) -> n
      Error(_) -> panic as { "Invalid input: " <> char }
    }
    case i % 2 {
      0 if num > 0 ->
        Disk(
          dict.insert(infos, size, File(id: i / 2, length: num)),
          dict.insert(lookup_by_id, i / 2, #(size, num)),
          num + size,
          int.max(maxid, i / 2),
        )
      1 if num > 0 ->
        Disk(
          dict.insert(infos, size, Free(length: num)),
          lookup_by_id,
          num + size,
          maxid,
        )
      // Ignore empty space of length 0
      _ -> disk
    }
  })
}

fn get_first_empty_with_min_length(
  disk: Disk,
  min_length: Int,
  upper_bound: Int,
) -> #(Int, Int) {
  let res =
    list.range(0, upper_bound)
    |> list.find_map(fn(i) {
      case dict.get(disk.infos, i) {
        Ok(Free(length:)) if length >= min_length -> Ok(#(i, length))
        _ -> Error(Nil)
      }
    })
  res
  |> result.unwrap(#(0, -1))
}

// move_file moves file with filenumber to the empty space
// Assumes that the empty space is big enough
fn move_file(disk: Disk, file: #(Int, Int, Int), empty: #(Int, Int)) -> Disk {
  let #(file_i, file_id, file_length) = file
  let #(empty_i, empty_length) = empty
  let infos = dict.delete(disk.infos, file_i)
  let infos = dict.delete(infos, empty_i)
  let infos =
    dict.insert(infos, empty_i, File(id: file_id, length: file_length))
  let infos = case empty_length - file_length {
    0 -> infos
    _ ->
      dict.insert(
        infos,
        empty_i + file_length,
        Free(length: empty_length - file_length),
      )
  }
  Disk(..disk, infos:)
}

fn defrag(disk: Disk) -> Disk {
  // The instructions say to attempt to move the files by reverse id and only once
  yielder.range(from: disk.maxid, to: 0)
  |> yielder.fold(disk, fn(disk, id) {
    // Get the length of the file to move
    let #(from, length) = case dict.get(disk.lookup_by_id, id) {
      Ok(pair) -> pair
      _ -> panic as "File not found"
    }
    // Find the first empty slot
    let #(empty_i, empty_length) =
      get_first_empty_with_min_length(disk, length, from - 1)
    // If the empty slot is big enough, move the file
    case empty_length >= length {
      True -> move_file(disk, #(from, id, length), #(empty_i, empty_length))
      False -> disk
    }
  })
}

pub fn checksum(disk: Disk) -> Int {
  let yield = fn(i) {
    case dict.get(disk.infos, i) {
      Ok(File(id:, length:)) ->
        Next(element: Some(#(i, id, length)), accumulator: i + length)
      Ok(Free(length:)) -> Next(element: None, accumulator: i + length)
      _ if i < disk.size -> Next(element: None, accumulator: i + 1)
      _ -> Done
    }
  }
  yielder.unfold(0, yield)
  |> yielder.fold(0, fn(sum, elem) {
    case elem {
      None -> sum
      Some(#(i, id, length)) -> {
        list.range(i, i + length - 1)
        |> list.fold(sum, fn(acc, j) { acc + j * id })
      }
    }
  })
}

pub fn part2(input: String) -> Int {
  input
  |> parse_input
  |> defrag
  |> checksum
}
