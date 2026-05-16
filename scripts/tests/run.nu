#!/usr/bin/env nu

use std assert

def run-test [name: string, command: list<string>] {
  print $"running ($name)..."
  let result = (run-external ...$command | complete)
  assert equal $result.exit_code 0 $"($name) failed; stdout: ($result.stdout); stderr: ($result.stderr)"
}

def main [] {
  run-test "install unit tests" [ "nu" "scripts/tests/install.nu" ]
  run-test "generated installer config tests" [ "nu" "scripts/tests/install-generate.nu" ]

  print "all tests passed"
}
