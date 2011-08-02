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
use charnames qw();

use I18N::Langinfo qw(langinfo CODESET);
my $codeset = langinfo(CODESET);

use Encode qw(decode);
@ARGV = map { decode $codeset, $_ } @ARGV;

foreach my $input (@ARGV) {
  open my $handle, "<", $input or die "Can not open file $input! $!";

  my $first_line = <$handle>;

  close $handle;
  
  print STDERR "$input\n";

  my $semicolon_count = 0;
  my $tab_count = 0;
  my $comma_count = 0;

  $semicolon_count++ while ($first_line =~ m/;/g);
  $tab_count++ while ($first_line =~ m/\t/g);
  $comma_count++ while ($first_line =~ m/,/g);

  ##print "Semi:\t$semicolon_count\nTab:\t$tab_count\nComma:\t$comma_count\n";

  my $separator = "\t";

  if ($semicolon_count > $tab_count && $semicolon_count > $comma_count) {
    $separator = ";";
  }

  if ($comma_count > $tab_count && $comma_count > $semicolon_count) {
    $separator = ",";
  }

  my @fields = split($separator, $first_line);

  my $dquot_count = 0;
  my $quot_count = 0;

  foreach my $field (@fields) {
    $dquot_count++ while ($field =~ m/^"[^"]*"$/g);
    $quot_count++ while ($field =~ m/^'[^']*'$/g);
  }

  ##print "Doublequotes:\t$dquot_count\nSinglequotes:\t$quot_count\n";

  my $quotation = undef;

  if ($dquot_count > 0 || $quot_count > 0) {
    if ($quot_count > $dquot_count) {
	  $quotation = "'";
    }
    else {
	  $quotation = "\"";
    }
    
    printf "%03o\t%03o\n", ord($separator), ord($quotation);
    printf "U+%04x\tU+%04x\n", ord($separator), ord($quotation);
    print charnames::viacode(ord($separator)) . "\t" . charnames::viacode(ord($quotation)) . "\n";
  }
  else {
    printf "%03o\n", ord($separator);
    printf "U+%04x\n", ord($separator);
    print charnames::viacode(ord($separator)) . "\n";
  }
}
