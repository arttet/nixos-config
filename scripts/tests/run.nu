#!/usr/bin/env nu

use std assert

def run-test [name: string, command: list<string>] {
  print $"running ($name)..."
  let result = (run-external ...$command | complete)
  assert equal $result.exit_code 0 $"($name) failed; stdout: ($result.stdout); stderr: ($result.stderr)"
}

def main [] {
  $env.NIX_CONFIG_NO_UI = "1"
  $env.NIX_CONFIG_INSTALL_PLAIN_UI = "1"
  $env.NO_COLOR = "1"

  run-test "install unit tests" [ "nu" "scripts/tests/install.nu" ]
  run-test "generated installer config tests" [ "nu" "scripts/tests/install-generate.nu" ]
  run-test "local template sync tests" [ "nu" "scripts/tests/local-sync.nu" ]

  if ($env.RUN_DISKO_LOOP_TEST? | default "") == "1" {
    run-test "real disko loopback tests" [ "nu" "scripts/tests/disko-loop.nu" ]
  }

  print "all tests passed"
}
