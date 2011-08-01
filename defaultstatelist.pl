#!/usr/bin/perl -w

use strict;

while (<STDIN>) {

  if (/(lights_\S*) label word/) {
      if ($1 eq "lights_done") { exit; } else { print $1; }
  }
  if (/TEXTURE_DEF\s(\S*).*,\s+"([^"]*)"\s+;/) {
    print "\t" . $2 . "\t" . $1;
  }
  if (/TEXTURE_LIST_END/) {
    print "\n";
  }
}

