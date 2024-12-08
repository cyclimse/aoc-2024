import gleam/list
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder, Done, Next}
import glearray.{type Array}

const out_of_bounds = "Index out of bounds"

/// Grid is a 2D grid of a of fixed size.
/// It's backed by a 1D array and provides convenience functions for 2D access.
pub opaque type Grid(a) {
  Grid(data: Array(a), width: Int, height: Int)
}

/// from_list creates a Grid from a List of Lists.
pub fn from_list(data: List(List(a))) -> Result(Grid(a), Nil) {
  let height = data |> list.length
  use width <- result.try(data |> list.first |> result.map(list.length))
  let data = data |> list.flatten |> glearray.from_list
  Ok(Grid(data, width, height))
}

/// must_from_list creates a Grid from a List of Lists.
/// Panics if the input is not a valid grid.
pub fn must_from_list(data: List(List(a))) -> Grid(a) {
  case from_list(data) {
    Ok(grid) -> grid
    Error(_) -> panic as "Provided data is a one dimensional list"
  }
}

/// get retrieves the element at the given row and column.
pub fn get(grid: Grid(a), row: Int, col: Int) -> Result(a, Nil) {
  case grid {
    // We need to check for bounds as otherwise we may return the wrong element
    _ if row < 0 || row >= grid.height || col < 0 || col >= grid.width ->
      Error(Nil)
    _ -> glearray.get(grid.data, row * grid.width + col)
  }
}

/// must_get retrieves the element at the given row and column.
pub fn must_get(grid: Grid(a), row: Int, col: Int) -> a {
  case get(grid, row, col) {
    Ok(value) -> value
    Error(_) -> panic as out_of_bounds
  }
}

/// set sets the element at the given row and column.
/// Returns an error if the index is out of bounds.
pub fn set(grid: Grid(a), row: Int, col: Int, value: a) -> Result(Grid(a), Nil) {
  let index = row * grid.width + col
  case glearray.copy_set(grid.data, index, value) {
    Ok(data) -> Ok(Grid(..grid, data:))
    Error(_) -> Error(Nil)
  }
}

/// must_set sets the element at the given row and column.
/// Panics if the index is out of bounds.
pub fn must_set(grid: Grid(a), row: Int, col: Int, value: a) -> Grid(a) {
  case set(grid, row, col, value) {
    Ok(grid) -> grid
    Error(_) -> panic as out_of_bounds
  }
}

/// dimensions returns the width and height of the grid.
pub fn dimensions(grid: Grid(a)) -> #(Int, Int) {
  #(grid.height, grid.width)
}

/// iterate returns an iterator over the elements of the grid.
/// The iterator yields the elements in row-major order.
pub fn iterate(grid: Grid(a)) -> Yielder(a) {
  let yield = fn(acc) {
    let #(row, col) = #(acc / grid.width, acc % grid.width)
    case get(grid, row, col) {
      Ok(value) -> Next(element: value, accumulator: acc + 1)
      Error(_) -> Done
    }
  }
  yielder.unfold(0, yield)
}

/// iterate_with_index returns an iterator over the elements of the grid with their indices.
pub fn iterate_with_index(grid: Grid(a)) -> Yielder(#(#(Int, Int), a)) {
  let yield = fn(acc) {
    let #(row, col) = #(acc / grid.width, acc % grid.width)
    case get(grid, row, col) {
      Ok(value) -> Next(element: #(#(row, col), value), accumulator: acc + 1)
      Error(_) -> Done
    }
  }
  yielder.unfold(0, yield)
}

/// print prints the grid to the console.
/// Handles adding newlines between rows and calling the provided show function.
pub fn print(
  grid: Grid(a),
  show show: fn(a) -> String,
  // The generic type b is used for io.debug which returns a String instead of Nil
  with with: fn(String) -> b,
) {
  let reversed: List(String) =
    iterate_with_index(grid)
    |> yielder.fold([], fn(tail, elem) {
      let #(#(_, col), value) = elem
      case col == grid.width - 1 {
        True -> ["\n", show(value), ..tail]
        False -> [show(value), ..tail]
      }
    })
  reversed
  |> list.reverse
  |> string.join("")
  |> with
}
