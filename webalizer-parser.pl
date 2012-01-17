#!/usr/bin/perl
use warnings;
use strict;

use HTML::TableExtract;
use HTML::Parser;
use Data::Dumper;

# Use your own path!
my $path = '/home/navap/www/webalizer-parser/logs';

my %stats;

opendir (DIR, $path) or die "Couldn't open file: $!";
my @files = grep {/usage_[0-9]{6}\.html/}  readdir DIR;
close DIR;
foreach my $month (@files) {
  open (FILE, $path . "/" . $month) or die "$!";
  while (<FILE>){ 
    my $html = join ("", <FILE>);
    $month =~ s/usage_([0-9]{6})\.html/$1/g;
    $stats{$month} = parse_html($html);
  }
  close (FILE);
}

sub parse_html {
  my $html = shift;
  my $te = HTML::TableExtract->new;

  $te->parse($html);

  my %stats = (
    hits => {
      total     => get_value($te, 0,3,1),
      per_hour  => get_value($te, 0,19,1),
    },
    response_codes => {
      '000' => get_value($te, 0,30,1),
#      200   => get_value(0,31,1) + get_value(0,32,1),
#      300   => get_value(0,33,1) + get_value(0,34,1) + get_value(0,35,1) + get_value(0,36,1),
#      400   => get_value(0,37,1) + get_value(0,38,1) + get_value(0,39,1) + get_value(0,40,1) + get_value(0,41,1) + get_value(0,42,1) + get_value(0,43,1) + get_value(0,44,1) + get_value(0,45,1) + get_value(0,46,1),
#      500   => get_value(0,47,1) + get_value(0,48,1) + get_value(0,49,1) + get_value(0,50,1),
    },
    urls      => parse_table($te,3,9,1),
    countries => parse_table($te,13,11,1),
  );

  return \%stats;
}

sub get_value {
  my ($te, $table, $row, $col) = @_;

  return $te->table(0,$table)->cell($row, $col);
}

sub parse_table {
  my ($te, $table, $key, $value) = @_;
  my %hash;
  my @rows = $te->table(0,3)->rows;

  my $count = 5;
  while ($count < (scalar @rows - 1)) {
    $hash{ get_value($te,$table,$count,$key) } = get_value($te,$table,$count,$value);
    $count++;
  }

  return \%hash;
}

print Dumper(\%stats);