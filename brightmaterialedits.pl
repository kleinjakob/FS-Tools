#!/usr/bin/perl -w

use strict;

# Useage: ./brightmaterialedits.pl "brightmaterials.csv" "subfile.asm" > "subfile_mod"

my $brightmaterials="$ARGV[0]";
my $asmfile="$ARGV[1]";

open my $matfile, "<", $brightmaterials or die "Can not open file $brightmaterials! $!";
open my $infile, "<", $asmfile or die "Can not open file $asmfile! $!";

# Slurp whole material file into array.
my @mattable = <$matfile>;

close $matfile;

# Make state-substitution hash.
my $subhash = {};

# Work on each line (= state) in the material file.
foreach my $_ (@mattable) {
  chomp $_;
  # Remove Quotes from fields if any.
  s/^\"//g; s/\"$//g; s/\"\t/\t/g; s/\t\"/\t/g;
  my @fields = split("\t", $_);
  
  # Check if is header.
  unless ($fields[0] =~ m/^#/) {
    $subhash->{$fields[0]} = [$fields[1], $fields[2], $fields[3]];
  }
}


while (<$infile>) {
  if (/MATERIAL_DEF\s+(\d.*\d)\s*;\s*(\d*)/) {
    my @floats = split(",", $1);
    my $materialnumber = $2;
    
    my $diff_r      = sprintf "%.6f", $floats[0];
    my $diff_g      = sprintf "%.6f", $floats[1];
    my $diff_b      = sprintf "%.6f", $floats[2];

    my $trans       = sprintf "%.6f", $floats[3];
    
    my $amb_r       = sprintf "%.6f", $floats[4];
    my $amb_g       = sprintf "%.6f", $floats[5];
    my $amb_b       = sprintf "%.6f", $floats[6];
    
    my $spec_r      = sprintf "%.6f", $floats[7];
    my $spec_g      = sprintf "%.6f", $floats[8];
    my $spec_b      = sprintf "%.6f", $floats[9];

    my $emm_r       = sprintf "%.6f", $floats[10];
    my $emm_g       = sprintf "%.6f", $floats[11];
    my $emm_b       = sprintf "%.6f", $floats[12];
    
    my $specpower   = sprintf "%g", $floats[13];

    # Check if Material confirms to modification requirements.
    if ($diff_r == 1 && $diff_g == 1 && $diff_b == 1 && 
        $specpower >= 900 && $specpower <= 999) {
      
      if ($specpower == 999) {
        # Emmisive Color should be taken from the Diffuse Channel.
        printf "    MATERIAL_DEF %.6f,%.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f ; %g #MODIFIED by Jakob Klein\n",
            $spec_r, $spec_g, $spec_b, 0, $spec_r, $spec_g, $spec_b, $spec_r, $spec_g, $spec_b, $spec_r, $spec_g, $spec_b, 0, $materialnumber;
      }
      else {
        # Emmissive Color should be taken from settings file.
        
        # Load Specular Color from settingsfile hash.
        $emm_r = $subhash->{$specpower}->[0];
        $emm_g = $subhash->{$specpower}->[1];
        $emm_b = $subhash->{$specpower}->[2];
        
        # Print Modified Material String.
        printf "    MATERIAL_DEF %.6f,%.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f ; %g #MODIFIED by Jakob Klein\n",
            $emm_r, $emm_g, $emm_b, 0, $emm_r, $emm_g, $emm_b, $emm_r, $emm_g, $emm_b, $emm_r, $emm_g, $emm_b, 0, $materialnumber;
      }
      ##printf "##  MATERIAL_DEF %.6f,%.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f,%.6f,%.6f,  %.6f ; %g\n",
      ##    $diff_r, $diff_g, $diff_b, $trans, $amb_r, $amb_g, $amb_b, $spec_r, $spec_g, $spec_b, $emm_r, $emm_g, $emm_b, $specpower, $materialnumber;
    }
    else {
      print;
    }
  }
  else {
    print;
  }
}

close $infile;
