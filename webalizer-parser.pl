#!/usr/bin/perl
use warnings;
use strict;

use HTML::TableExtract;
use HTML::Parser;
use Data::Dumper;
$Data::Dumper::Sortkeys = \&sort_filter;


# Use your own path!
my $year = '2011';
my $path = '/home/navap/www/webalizer-parser/logs/';

my %monthly;
my %annualy;

initialize();

## Output annual values
#compile_annual();

## Output stats by month
#print Dumper(\%monthly);

## Output the important stats as a tab separated table
generate_report();

sub initialize {
  opendir (DIR, $path) or die "Couldn't open file: $!";
  my @files = grep {/usage_$year[0-9]{2}\.html/}  readdir DIR;
  close DIR;
  foreach my $month (@files) {
    open (FILE, $path . "/" . $month) or die "$!";
    while (<FILE>){
      my $html = join ("", <FILE>);
      $month =~ s/usage_([0-9]{6})\.html/$1/g;
      $monthly{$month} = parse_html($html);
    }
    close (FILE);
  }
}

sub compile_annual {
  foreach my $month (sort keys %monthly) {
    foreach my $group ( sort keys %{ $monthly{$month} }) {
      foreach my $value ( sort {$monthly{$month}{$group}{$a} cmp $monthly{$month}{$group}{$b} } keys %{ $monthly{$month}{$group} }) {
        if( exists $annualy{$group}{$value} ) {
          # warn "Key [$value] is in both hashes!";
          $annualy{$group}{$value} += $monthly{$month}{$group}{$value};
          next;
        }
        else {
          $annualy{$group}{$value} = $monthly{$month}{$group}{$value};
        }
      }
    }
  }
  print Dumper(\%annualy);
}

sub generate_report {
  print join ("\t",('Month', 'Total Hits','Total WS Hits','ws/recording','ws/release','ws/release-group','ws/artist','Hits per Hour')) . "\n";

  foreach my $month (sort keys %monthly) {
    my $totalhits       = $monthly{$month}{'hits'}{'total'};
    my $hitsperhour     = $monthly{$month}{'hits'}{'per_hour'};
    my $webhits         = $monthly{$month}{'urls'}{'Web Service'};
    my $wsrecording     = $monthly{$month}{'urls'}{'/ws/1/track/'} + $monthly{$month}{'urls'}{'/ws/2/recording/'} +
                          $monthly{$month}{'urls'}{'/ws/1/track'} + $monthly{$month}{'urls'}{'/ws/2/recording'};
    my $wsrelease       = $monthly{$month}{'urls'}{'/ws/1/release/'} + $monthly{$month}{'urls'}{'/ws/2/release/'} +
                          $monthly{$month}{'urls'}{'/ws/1/release'} + $monthly{$month}{'urls'}{'/ws/2/release'};
    my $wsreleasegroup  = $monthly{$month}{'urls'}{'/ws/1/release-group/'} + $monthly{$month}{'urls'}{'/ws/2/release-group/'} +
                          $monthly{$month}{'urls'}{'/ws/1/release-group'} + $monthly{$month}{'urls'}{'/ws/2/release-group'};
    my $wsartist        = $monthly{$month}{'urls'}{'/ws/1/artist/'} + $monthly{$month}{'urls'}{'/ws/2/artist/'} +
                          $monthly{$month}{'urls'}{'/ws/1/artist'} + $monthly{$month}{'urls'}{'/ws/2/artist'};

    print join("\t",($month, $totalhits, $webhits, $wsrecording, $wsrelease, $wsreleasegroup, $wsartist, $hitsperhour));
    print "\n";
  }
}


#search('2011','Web Service');

sub search {
  my ($year, @items) = @_;
  my %search_results;

  foreach my $item (@items) {
    foreach my $month (keys %monthly) {
      foreach my $group (keys %{ $monthly{$month} }) {
        if ($monthly{$month}{$group}{$item}) {
          $search_results{$month}{$group}{$item} = $monthly{$month}{$group}{$item};
        }
      }
    }
  }
  print Dumper(\%search_results);
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
    response_codes => parse_table($te,0,0,1,30,50),
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
  my ($te, $table, $key, $value, $first_row, $last_row) = @_;
  my %hash;
  my @rows = $te->table(0,$table)->rows;

  # Check if doing a partial table lookup
  if ($first_row && $last_row) {
    my $count = $first_row;
    while ($count < $last_row - 1) {
      $hash{ get_value($te,$table,$count,$key) } = get_value($te,$table,$count,$value);
      $count++;
    }

    return \%hash;

  } else {
    my $count = 5;
    while ($count < (scalar @rows - 1)) {
      $hash{ get_value($te,$table,$count,$key) } = get_value($te,$table,$count,$value);
      $count++;
    }

    return \%hash;
  }
}

sub add_commas {
   (my $num = shift) =~ s/\G(\d{1,3})(?=(?:\d\d\d)+(?:\.|$))/$1,/g; 
   return $num; 
}

sub sort_filter {
  my ($hash) = @_;

  return [ (sort {$a cmp $b} keys %$hash) ];
}