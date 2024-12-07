import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string

import simplifile

pub fn day7() {
  let assert Ok(input) = simplifile.read("./assets/day7.txt")
  io.println("Day7/part1: " <> { part1(input) |> int.to_string })
  io.println("Day7/part2: " <> { part2(input) |> int.to_string })
}

pub fn parse_input(input: String) -> List(#(Int, List(Int))) {
  input
  |> string.trim
  |> string.split(on: "\n")
  |> list.map(fn(line) {
    let assert [out, equation_members] = line |> string.split(on: ":")
    #(
      out |> int.parse |> result.unwrap(0),
      equation_members
        |> string.trim
        |> string.split(on: " ")
        |> list.map(fn(member) {
          member |> string.trim |> int.parse |> result.unwrap(0)
        }),
    )
  })
}

fn concatenate(a: Int, b: Int) -> Int {
  let stra = a |> int.to_string
  let strb = b |> int.to_string
  { stra <> strb } |> int.parse |> result.unwrap(0)
}

// We need to test for all possible combinations of operators between the numbers
fn has_solution_inner(
  out: Int,
  members: List(Int),
  acc: Int,
  operators: List(fn(Int, Int) -> Int),
) -> Bool {
  case members {
    [] -> acc == out
    [member, ..rest] -> {
      operators
      |> list.map(fn(op) { op(acc, member) })
      |> list.map(fn(new_acc) {
        fn() { has_solution_inner(out, rest, new_acc, operators) }
      })
      |> list.find(fn(f) { f() })
      |> result.is_ok
    }
  }
}

fn has_solution(
  out: Int,
  members: List(Int),
  operators: List(fn(Int, Int) -> Int),
) -> Bool {
  case members {
    [] -> False
    // We can't use 0 as the first acc because if we choose multiplication as the first operator, the result will always be 0
    [member, ..rest] -> has_solution_inner(out, rest, member, operators)
  }
}

pub fn part1(input: String) -> Int {
  let equations = parse_input(input)
  equations
  |> list.map(fn(eq) {
    task.async(fn() {
      let #(out, members) = eq
      case has_solution(out, members, [int.add, int.multiply]) {
        True -> out
        False -> 0
      }
    })
  })
  |> list.map(task.await_forever)
  |> int.sum
}

pub fn part2(input: String) -> Int {
  let equations = parse_input(input)
  equations
  |> list.map(fn(eq) {
    task.async(fn() {
      let #(out, members) = eq
      case has_solution(out, members, [int.add, int.multiply, concatenate]) {
        True -> out
        False -> 0
      }
    })
  })
  |> list.map(task.await_forever)
  |> int.sum
}
