#!/usr/bin/env nu

def main [...args] {
  print "Deprecated install entrypoint."
  print ""
  print "Use the guided installer:"
  print "  nu scripts/install/bootstrap.nu"
  print ""
  print "Use the disk-only helper:"
  print "  nu scripts/install/disko.nu /dev/disk/by-id/<reviewed-disk>"
}
