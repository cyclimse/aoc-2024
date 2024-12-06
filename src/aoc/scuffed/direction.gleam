pub type Direction {
  North
  East
  South
  West
}

pub fn step(direction: Direction, i: Int, j: Int) -> #(Int, Int) {
  case direction {
    North -> #(i - 1, j)
    East -> #(i, j + 1)
    South -> #(i + 1, j)
    West -> #(i, j - 1)
  }
}

pub fn turn_right(direction: Direction) -> Direction {
  case direction {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}

pub fn turn_left(direction: Direction) -> Direction {
  case direction {
    North -> West
    East -> North
    South -> East
    West -> South
  }
}
