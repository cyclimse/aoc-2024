import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import glearray

import simplifile

pub fn day5() {
  let assert Ok(input) = simplifile.read("./assets/day5.txt")
  io.println("Day5/part1: " <> { part1(input) |> int.to_string })
  io.println("Day5/part2: " <> { part2(input) |> int.to_string })
}

pub fn parse_input(input: String) -> #(Dict(Int, Set(Int)), List(List(Int))) {
  let assert [first, second] =
    input
    |> string.trim
    |> string.split(on: "\n\n")
  let rules = parse_page_ordering_rules(first)
  let updates = parse_updates_of_pages(second)
  #(rules, updates)
}

pub fn parse_page_ordering_rules(input: String) -> Dict(Int, Set(Int)) {
  let assert Ok(re) = regexp.from_string("(\\d+)\\|(\\d+)")
  let matches = regexp.scan(with: re, content: input)
  matches
  |> list.fold(dict.new(), fn(d, match) {
    let regexp.Match(_, groups) = match
    let assert [Some(a), Some(b)] = groups
    let #(numa, numb) = #(
      int.parse(a) |> result.unwrap(0),
      int.parse(b) |> result.unwrap(0),
    )
    dict.upsert(d, numa, fn(opt) {
      case opt {
        Some(after_thoses) -> after_thoses |> set.insert(numb)
        None -> set.from_list([numb])
      }
    })
  })
}

pub fn parse_updates_of_pages(input: String) -> List(List(Int)) {
  input
  |> string.split(on: "\n")
  |> list.map(fn(line) {
    line
    |> string.split(on: ",")
    |> list.map(fn(n) { int.parse(n) |> result.unwrap(0) })
  })
}

type State {
  State(is_valid: Bool, has_already_updated: Set(Int))
}

fn is_valid_update(rules: Dict(Int, Set(Int)), update: List(Int)) -> Bool {
  let initial_state = State(is_valid: True, has_already_updated: set.new())

  let State(is_valid, ..) =
    update
    |> list.reverse
    |> list.fold(initial_state, fn(state, page) {
      case state, set.is_empty(state.has_already_updated) {
        State(is_valid: False, ..), _ -> state
        _, True ->
          State(
            ..state,
            has_already_updated: state.has_already_updated |> set.insert(page),
          )
        State(is_valid: True, has_already_updated:), _ -> {
          // Lookup the rules for the previous pages
          has_already_updated
          |> set.fold(state, fn(state, previously_updated_page) {
            // If a page we've dealt with MUST be printed before the current page
            // Clearly, there's a problem as we're going in reverse order
            case dict.get(rules, previously_updated_page) {
              Ok(must_be_printed_after_previously_updated_page) -> {
                let must_be_printed_before =
                  must_be_printed_after_previously_updated_page
                  |> set.contains(page)
                State(
                  is_valid: state.is_valid && !must_be_printed_before,
                  has_already_updated: has_already_updated |> set.insert(page),
                )
              }
              _ ->
                State(
                  ..state,
                  has_already_updated: has_already_updated |> set.insert(page),
                )
            }
          })
        }
      }
    })
  is_valid
}

pub fn part1(input: String) -> Int {
  let #(rules, updates) = parse_input(input)

  let valid_updates =
    updates
    |> list.filter({ is_valid_update(rules, _) })

  valid_updates
  |> list.map(fn(update) {
    let n = update |> list.length
    // Get the middle element of the list
    let middle = n / 2
    update |> glearray.from_list |> glearray.get(middle) |> result.unwrap(0)
  })
  |> list.fold(0, int.add)
}

fn sort_update(rules: Dict(Int, Set(Int)), update: List(Int)) -> List(Int) {
  update
  |> list.sort(fn(a, b) {
    let must_be_printed_after_a = dict.get(rules, a) |> result.unwrap(set.new())
    let must_be_printed_after_b = dict.get(rules, b) |> result.unwrap(set.new())

    let page_a_after_b = must_be_printed_after_b |> set.contains(a)
    let page_b_after_a = must_be_printed_after_a |> set.contains(b)

    case page_a_after_b, page_b_after_a {
      True, True -> int.compare(a, b)
      True, False -> order.Lt
      False, True -> order.Gt
      False, False -> int.compare(a, b)
    }
  })
}

pub fn part2(input: String) -> Int {
  let #(rules, updates) = parse_input(input)

  let fixed_updates =
    updates
    |> list.filter_map(fn(update) {
      case is_valid_update(rules, update) {
        True -> Error(Nil)
        False -> Ok(sort_update(rules, update))
      }
    })

  fixed_updates
  |> list.map(fn(update) {
    let n = update |> list.length
    // Get the middle element of the list
    let middle = n / 2
    update |> glearray.from_list |> glearray.get(middle) |> result.unwrap(0)
  })
  |> list.fold(0, int.add)
}
