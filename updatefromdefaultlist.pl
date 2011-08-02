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

use strict;

# Useage: ./updatefromdefaultlist.pl "statelabellist.csv" "subfile.asm" > "subfile_mod"

my $statetablelist="$ARGV[0]";
my $asmfile="$ARGV[1]";

open my $stfile, "<", $statetablelist or die "Can not open file $statetablelist! $!";
open my $infile, "<", $asmfile or die "Can not open file $asmfile! $!";

# Slurp whole statetable file into array.
my @statetable = <$stfile>;

close $stfile;

# Make state-substitution hash.
my $subhash = {};

# Work on each line (= state) in the statetable.
foreach my $_ (@statetable) {
  chomp $_;
  # Remove Quotes from fields if any.
  s/^\"//g; s/\"$//g; s/\"\t/\t/g; s/\t\"/\t/g;
  my @fields = split("\t", $_);
  my @texture_names;
  my @texture_types;
  
  # Check if is header.
  unless ($fields[0] =~ m/^#/) {
    my $state_label = shift @fields;
    
    while (scalar(@fields) >= 2) {
      # Move texture name to texturename array
      push @texture_names, shift @fields;

      # Move texture type to texturetype array
      push @texture_types, shift @fields;
    }
    
    $subhash->{$state_label} = [\@texture_names, \@texture_types];
  }
}

# Set section variable to undef to indicate we are currently in no section.
my $section = undef;

# Read asm file line by line.
while (<$infile>) {
  # If line is a lights_... label set section variable for substitution.
  if (/(lights_\S*)\s+label\s+word/) {
    unless ($1 eq "lights_done") {
      $section = $1;
    }
  }
  
  # Reset section variable on end of texture list.
  if (/TEXTURE_LIST_END/) {
    $section = undef;
  }
  
  # If texture def line is found, start modifications according to section.
  if (/TEXTURE_DEF/) {
    # Get Texture Number.
    m/;\s*(\d+)\s*$/;
    my $texturenum = $1;

    # Get Colorsettings between type and Texture Name.
    m/(\s*,.*,\s*\")/;
    my $settings_string = $1;

    # Load and test texturename for length.    
    my $texturename = uc($subhash->{$section}->[0]->[$texturenum]);
    die "ERROR! $texturename too long (" . length $texturename . " of max 63 characters).\n" if (length $texturename > 63);
    
    # Load texturetype.
    my $texturetype = $subhash->{$section}->[1]->[$texturenum];
    
    # Print modified line.
    print "    TEXTURE_DEF ";
    print $texturetype;
    print $settings_string;
    print $texturename;
    print "\"  ; $texturenum\n";
    
    # Skip default printing line as we have already printed the modification.
    next;
  }
  
  print;
}

close $infile;
