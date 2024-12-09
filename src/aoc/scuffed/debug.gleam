import birl
import birl/duration.{MilliSecond}
import gleam/int

pub fn run_and_time(
  run: fn(a) -> b,
  with arg: a,
  stringify str: fn(b) -> String,
) -> String {
  let start = birl.now()
  let result = run(arg)
  let end = birl.now()
  { result |> str }
  <> " in "
  <> {
    birl.difference(end, start)
    |> duration.blur_to(MilliSecond)
    |> int.to_string
  }
  <> "ms"
}
