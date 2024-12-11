{ pkgs, lib, config, inputs, ... }:

let
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in
{
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/

  # https://devenv.sh/languages/
  languages.gleam.enable = true;
  languages.gleam.package = pkgs-unstable.gleam;

  # devenv enables Erlang when using Gleam
  # problem: the OTP version is too old for Gleam
  languages.erlang.enable = true;
  languages.erlang.package = pkgs-unstable.erlang_27;

  # https://devenv.sh/processes/

  # https://devenv.sh/services/

  # https://devenv.sh/scripts/

  # https://devenv.sh/tasks/

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    gleam --version | grep "gleam 1.6.2"
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;
  git-hooks.hooks.gleam-fmt = {
    enable = true;
    name = "Gleam format";
    entry = "gleam format";
    files = "\\.gleam$";
  };

  git-hooks.hooks.gleam-test = {
    enable = true;
    name = "Gleam test";
    entry = "gleam test";
    files = "\\.gleam$";
  };

  # See full reference at https://devenv.sh/reference/options/
}
