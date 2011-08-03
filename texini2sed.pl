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
#   This script will translate a Textures.ini file as used with the old
#   Texture Rename Tool into a substitution script which can be applied with
#   sed onto the _statelighttable.csvs to achieve the same result as with
#   the Texture Rename Tool (but working also on non default light system
#   csvs!).
#
# Useage:
#   ./texini2sed.pl < "Textures.ini" > "textures.sed"
# 
# Further Steps:
#   Apply this sed script onto the csv like this:
#   - When the main fstools.sh waits for you to finish the edit of the file
#     given change to another Console/Terminal Emulation Window or move the
#     process to the background (see you systems manuals for further detail,
#     e.g. man bash  under section "Job Control").
#   - go to the folder where you created the "textures.sed" and issue the
#     following command to invoke sed on your .csv
#       sed -f "textures.sed" "/tmp/xxxx.asm_statettablelist.csv" > result.csv
#     Then the substitute the old csv with the one you just applied your
#     edits to:
#       mv result.csv "/tmp/xxxx.asm_statettablelist.csv"
#     Where xxxx has to be substituted by the coorect name of course.
#   - Then you can go back to the main script fstools.sh and continue
#     execution by pressing Enter.

use strict;

# Global Variables used in this script.
my $mode = undef;
my $prefix = undef;

# Read Standard Input linewise into $_.
while (<>) {
  # Remove Standard Lineendings.
  chomp ($_);
  # Additonally remove any CR \r U+000d if present.
  $_ =~ s/\r//g;
  
  # Match sections to find out which mode the following lines are.
  if ($_ =~ /^\[Substitution\d+\]/i) {
    $mode = 'sub';
  }  
  elsif ($_ =~ /^\[Rename\d+\]/i) {
    $mode = 'ren';
  }
  # If section is not recognized, unset mode.
  elsif ($_ =~ /^\[/i) {
    $mode = undef;
  }
  # If mode is set and this is no section heading, process following lines.
  elsif ($mode) {
    # Mode is substitution.
    if ($mode eq 'sub') {
      # Match Prefix line and store in global variable $prefix.
      if ($_ =~ /^prefix=(.*)$/) {
        $prefix = $1;
        # Escape Slashes for sed.
        $prefix =~ s/\//\\\//g;
        next;
      }
      
      # Match textures.
      if ($_ =~ /^textures=(.*)$/) {
        # Textures are listed on one line,
        # separated by commas (U+002c) and surrounded by whitespace.
        my @textures = split (',', $1);

        # Work on each textture in this list.
        foreach my $texture (@textures) {
          # Remove any whitespace before or after the Texturename.
          $texture = trim ($texture);
          # Print sed substitution regex.
          print "s/$texture/${prefix}${texture}/gi\n";
        }
      }
    }
    # Mode is rename.
    if ($mode eq 'ren') {
      # Match Before and After Parts of lines.
      if ($_ =~ /^(.*)=(.*)$/) {
        # Escale Slashes for sed on both before and after.
        $1 =~ s/\//\\\//g;
        $2 =~ s/\//\\\//g;
        # Print sed substitution regex.
        print "s/$1/$2/gi\n";
      }
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

