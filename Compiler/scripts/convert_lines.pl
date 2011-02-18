#!/usr/bin/perl
# Usage: convert_lines.pl inFile outFile
# The new file adds a #line directive to each existing line, using the comment
# in OpenModelica generated C code on the format /*#modelicaLine ABC.mo:12:13-12:14*/
# This makes it possible to use GDB with OMC generate source code. It will also
# make GCC errors spit out Modelica line numbers instead of C lines, which helps a lot.
# -- martin.sjolund@liu.se

use Cwd 'abs_path';

$inf = $ARGV[0];
$outf = $ARGV[1];
open(INP, "<$inf")  or die("Cannot open file '$inf' for reading\n");
open(OUTP, ">$outf") or die("Cannot open file '$outf' for writing\n");

$lnum = 1;
$inStmt = 0;
$inStmtFile = "";
$inStmtLine = 0;
while( $line = <INP> ){
  # regex is fun
  if ($line =~ /^ *..#modelicaLine .([A-Za-z.\/]*):([0-9]*):[0-9]*-[0-9]*:[0-9]*...$/) {
    $inStmtFile = abs_path($1); # Absolute paths makes GDB a _lot_ happier
    $inStmtLine = $2;
    $inStmt = 1;
  } elsif ($line =~ /^ *..#endModelicaLine/) {
    $inStmt = 0;
  } elsif ($inStmt) {
    print OUTP "#line $inStmtLine \"$inStmtFile\"\n$line";
  } else {
    print OUTP "#line $lnum \"$inf\"\n$line";
  }
  $lnum++;
}

close INP;
close OUTP;