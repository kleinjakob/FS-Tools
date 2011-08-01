#!/usr/bin/perl -w
#   FS Tools
#   Copyright (C) 2009-2011 Jakob Klein, mail@kleinjakob.at
#
#   This file is part of FS Tools.
#
#   FS Tools is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   FS Tools is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

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

