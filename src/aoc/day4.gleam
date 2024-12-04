import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array}
import simplifile

pub fn day4() {
  let assert Ok(input) = simplifile.read("./assets/day4.txt")
  io.println("Day4/part1: " <> { part1(input) |> int.to_string })
  io.println("Day4/part2: " <> { part2(input) |> int.to_string })
}

pub fn parse_input(input: String) -> Array(Array(String)) {
  input
  |> string.trim
  |> string.split(on: "\n")
  |> list.fold(glearray.new(), fn(matrix, row) {
    let next_row = row |> string.to_graphemes |> glearray.from_list
    matrix |> glearray.copy_push(next_row)
  })
}

fn dimensions(matrix: Array(Array(String))) -> #(Int, Int) {
  let rows = matrix |> glearray.length
  let assert Ok(first_row) = glearray.get(matrix, 0)
  #(rows, first_row |> glearray.length)
}

fn within_dimensions(rows: Int, cols: Int, x: Int, y: Int) -> Bool {
  x >= 0 && x < rows && y >= 0 && y < cols
}

pub fn read_rows(matrix: Array(Array(String))) -> List(String) {
  matrix
  |> glearray.to_list
  |> list.map(fn(row) { row |> glearray.to_list |> string.concat })
}

pub fn read_columns(matrix: Array(Array(String))) -> List(String) {
  let #(rows, cols) = dimensions(matrix)
  list.range(0, cols)
  |> list.fold([], fn(acc, y) {
    let next =
      list.range(0, rows)
      |> list.fold("", fn(column, x) {
        case within_dimensions(rows, cols, x, y) {
          True -> {
            let assert Ok(row) = glearray.get(matrix, x)
            let assert Ok(cell) = glearray.get(row, y)
            cell <> column
          }
          False -> column
        }
      })
    case next {
      "" -> acc
      _ -> [next, ..acc]
    }
  })
}

pub fn read_diagonals(matrix: Array(Array(String))) -> List(String) {
  let #(rows, cols) = dimensions(matrix)
  let first_set =
    list.range(0, rows + cols - 1)
    |> list.fold([], fn(acc, i) {
      let next =
        list.range(0, i + 1)
        |> list.fold("", fn(diagonal, j) {
          let x = i - j
          let y = j
          case within_dimensions(rows, cols, x, y) {
            True -> {
              let assert Ok(row) = glearray.get(matrix, x)
              let assert Ok(cell) = glearray.get(row, y)
              cell <> diagonal
            }
            False -> diagonal
          }
        })
      case next {
        "" -> acc
        _ -> [next, ..acc]
      }
    })
  list.range(0, rows + cols - 1)
  |> list.fold(first_set, fn(acc, i) {
    let next =
      list.range(0, i + 1)
      |> list.fold("", fn(diagonal, j) {
        let x = rows - 1 - i + j
        let y = j
        case within_dimensions(rows, cols, x, y) {
          True -> {
            let assert Ok(row) = glearray.get(matrix, x)
            let assert Ok(cell) = glearray.get(row, y)
            cell <> diagonal
          }
          False -> diagonal
        }
      })
    case next {
      "" -> acc
      _ -> [next, ..acc]
    }
  })
}

pub fn count_occurrences(line: String, target: String) -> Int {
  let length =
    line
    |> string.split(on: target)
    |> list.length
  length - 1
}

const target = "XMAS"

const target_backwards = "SAMX"

pub fn part1(input: String) -> Int {
  let matrix = parse_input(input)
  let rows = read_rows(matrix)
  let columns = read_columns(matrix)
  let diagonals = read_diagonals(matrix)
  // Can be optimized, no need to flatten but convenient
  let all = list.flatten([rows, columns, diagonals])
  all
  |> list.fold(0, fn(acc, line) {
    let count =
      count_occurrences(line, target)
      + count_occurrences(line, target_backwards)
    count + acc
  })
}

// Given a big matrix, return a list of 3x3 matrices that can be extracted from it
pub fn list_3x3_children(
  matrix: Array(Array(String)),
) -> List(Array(Array(String))) {
  let #(rows, cols) = dimensions(matrix)
  // Iterate over all 3x3 matrices
  list.range(0, rows - 2)
  |> list.fold([], fn(acc, x) {
    list.range(0, cols - 2)
    |> list.fold(acc, fn(acc, y) {
      let child =
        list.range(0, 2)
        |> list.fold(glearray.new(), fn(child, i) {
          let row = glearray.get(matrix, x + i) |> result.unwrap(glearray.new())
          let slice =
            list.range(0, 2)
            |> list.fold(glearray.new(), fn(slice, j) {
              case glearray.get(row, y + j) {
                Ok(cell) -> slice |> glearray.copy_push(cell)
                _ -> slice
              }
            })
          case glearray.length(slice) {
            3 -> child |> glearray.copy_push(slice)
            _ -> child
          }
        })
      case glearray.length(child) {
        3 -> acc |> list.append([child])
        _ -> acc
      }
    })
  })
}

const target_part2 = "MAS"

const target_backwards_part2 = "SAM"

pub fn is_xmas_cross(matrix_3x3: Array(Array(String))) -> Bool {
  let assert Ok(middle) =
    matrix_3x3
    |> glearray.get(1)
    |> result.map(glearray.get(_, 1))
    |> result.flatten
  // The first assert is not necessary, but it helps debugging as we only check the diagonals if the middle is an "A"
  middle == "A"
  && {
    let first_diagonal =
      list.range(0, 2)
      |> list.fold("", fn(acc, i) {
        let assert Ok(cell) =
          matrix_3x3
          |> glearray.get(i)
          |> result.map(glearray.get(_, i))
          |> result.flatten
        cell <> acc
      })
    let second_diagonal =
      list.range(0, 2)
      |> list.fold("", fn(acc, i) {
        let assert Ok(cell) =
          matrix_3x3
          |> glearray.get(i)
          |> result.map(glearray.get(_, 2 - i))
          |> result.flatten
        cell <> acc
      })
    {
      first_diagonal == target_part2 || first_diagonal == target_backwards_part2
    }
    && {
      second_diagonal == target_part2
      || second_diagonal == target_backwards_part2
    }
  }
}

pub fn part2(input: String) -> Int {
  let matrix = parse_input(input)
  let children = list_3x3_children(matrix)
  children
  |> list.count(is_xmas_cross)
}
