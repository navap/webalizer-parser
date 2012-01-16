#!/usr/bin/perl
use warnings;
use strict;

use HTML::TableExtract;
use HTML::Parser;
use Data::Dumper;

my $te = HTML::TableExtract->new(  );

open FILE, "usage_201112.html" or die "Couldn't open file: $!"; 
my $html = join("", <FILE>); 
close FILE;

$te->parse($html);

my %stats = (
  hits => {
    total     => get_value(0,3,1),
    per_hour  => get_value(0,19,1),
  },
  response_codes => {
    '000' => get_value(0,30,1),
    200   => get_value(0,31,1) + get_value(0,32,1),
    300   => get_value(0,33,1) + get_value(0,34,1) + get_value(0,35,1) + get_value(0,36,1),
    400   => get_value(0,37,1) + get_value(0,38,1) + get_value(0,39,1) + get_value(0,40,1) + get_value(0,41,1) + get_value(0,42,1) + get_value(0,43,1) + get_value(0,44,1) + get_value(0,45,1) + get_value(0,46,1),
    500   => get_value(0,47,1) + get_value(0,48,1) + get_value(0,49,1) + get_value(0,50,1),
  },
  urls      => parse_table(3,9,1),
  countries => parse_table(13,11,1),
);

sub get_value {
  my ($table, $row, $col) = @_;

  return $te->table(0,$table)->cell($row, $col);
}

sub parse_table {
  my ($table, $key, $value) = @_;
  my %hash;
  my @rows = $te->table(0,3)->rows;

  my $count = 5;
  while ($count < (scalar @rows - 1)) {
    $hash{ get_value($table,$count,$key) } = get_value($table,$count,$value);
    $count++;
  }

  return \%hash;
}

print Dumper(\%stats);
