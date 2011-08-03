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
#   along with FS Tools.  If not, see <http://www.gnu.org/licenses/>.

# Function:
#   This script will translate a ColorSet.ini file like it was used with
#   the Light Material Editor into the brightcolors.csv as expected by the
#   fstools.sh script.
#
# Useage:
#   ./colini2csv.pl < "ColorSet.ini" > "brightcolors.csv"

use strict;

# Global Variables used in this script.
my $last_color_number = undef;
my $red = undef;
my $green = undef;
my $blue = undef;

# Read STDIN.
while (<>) {
  # Remove any Lineendings.
  $_ =~ s/\r?\n//g;
  
  # Match sections to find Color Number.
  if ($_ =~ /^\[color(\d+)\]/i) {
    # Remove leading zeros.
    $last_color_number = $1;
    $last_color_number =~ s/^0*[^1-9]//;
  }
  # Ignore other sections and reset color number.
  elsif ($_ =~ /^\[/) {
    $last_color_number = undef;
  } 
  # If last_color_number is set interpret R G B lines.
  elsif (defined $last_color_number) {
    if ($_ =~ /^R=(\d+)/) {
      $red = $1;
    }
    elsif ($_ =~ /^G=(\d+)/) {
      $green = $1;
    }
    elsif ($_ =~ /^B=(\d+)/) {
      $blue = $1;
    }

    if (defined $red && defined $green && defined $blue) {
      printf "%d\t%.6f\t%.6f\t%.6f\n", 900+$last_color_number, $red/255, $green/255, $blue/255;
      $last_color_number = undef;
      $red = undef;
      $green = undef;
      $blue = undef;
    }
  }
}

# Perl trim function to remove whitespace from the start and end of the string.
sub trim {
	my $string = shift;
	$string = &ltrim(&rtrim($string));
	return $string;
}

# Left trim function to remove leading whitespace.
sub ltrim {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace.
sub rtrim {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

