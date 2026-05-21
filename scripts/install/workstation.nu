#!/usr/bin/env nu

def main [...args] {
  nu scripts/install/bootstrap.nu ...$args
}
