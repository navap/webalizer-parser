#!/usr/bin/perl
#use warnings;
use strict;

use HTML::TableExtract;
use HTML::Parser;
use Data::Dumper;
use JSON;
use Text::CSV::Slurp;
$Data::Dumper::Sortkeys = \&sort_filter;


# Use your own path!
my $year = '2012';
my $month = '201201';
my $path = 'logs/';

my %monthly;
my %annualy;

# Read in raw data from files
import_data();

## Output annual values
#compile_annual();

## Output stats by month
# print Dumper($monthly{201201});
# my $json_text = to_json(\%monthly);
# print $json_text;

output_csv();

sub import_data {
  opendir (DIR, $path) or die "Couldn't open file: $!";
  my @files = grep {/usage_[0-9]{6}\.html/}  readdir DIR;
  close DIR;

  my @sorted_files = sort @files;

  foreach my $month (@sorted_files) {
    open (FILE, $path . "/" . $month) or die "$!";
    while (<FILE>){
      my $html = join ("", <FILE>);
      $month =~ s/usage_([0-9]{6})\.html/$1/g;
      $monthly{$month}{'raw'} = parse_html($html);
    }
    close (FILE);

    my $totalhits       = $monthly{$month}{'raw'}{'hits'}{'total'};
    my $hitsperhour     = $monthly{$month}{'raw'}{'hits'}{'per_hour'};
    my $wstotal         = $monthly{$month}{'raw'}{'urls'}{'Web Service'};
    my $rdf             = $monthly{$month}{'raw'}{'urls'}{'/cgi-bin/mq_2_1.pl'} + 0;
    my $ws1recording    = $monthly{$month}{'raw'}{'urls'}{'/ws/1/track/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/1/track'};
    my $ws2recording    = $monthly{$month}{'raw'}{'urls'}{'/ws/2/recording/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/2/recording'};
    my $ws1release      = $monthly{$month}{'raw'}{'urls'}{'/ws/1/release/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/1/release'};
    my $ws2release      = $monthly{$month}{'raw'}{'urls'}{'/ws/2/release/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/2/release'};
    my $ws1releasegroup = $monthly{$month}{'raw'}{'urls'}{'/ws/1/release-group/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/1/release-group'};
    my $ws2releasegroup = $monthly{$month}{'raw'}{'urls'}{'/ws/2/release-group/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/2/release-group'};
    my $ws1artist       = $monthly{$month}{'raw'}{'urls'}{'/ws/1/artist/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/1/artist'};
    my $ws2artist       = $monthly{$month}{'raw'}{'urls'}{'/ws/2/artist/'} + $monthly{$month}{'raw'}{'urls'}{'/ws/2/artist'};

    my $s2xx = $monthly{$month}{'raw'}{'response_codes'}{'Code 200 - OK'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 206 - Partial Content'};
    my $s3xx = $monthly{$month}{'raw'}{'response_codes'}{'Code 301 - Moved Permanently'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 302 - Found'} +
        $monthly{$month}{'raw'}{'response_codes'}{'Code 303 - See Other'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 304 - Not Modified'};
    my $s4xx = $monthly{$month}{'raw'}{'response_codes'}{'Code 400 - Bad Request'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 401 - Unauthorized'} +
        $monthly{$month}{'raw'}{'response_codes'}{'Code 403 - Forbidden'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 404 - Not Found'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 405 - Method Not Allowed'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 408 - Request Timeout'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 411 - Length Required'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 413 - Request Entity Too Large'} +
        $monthly{$month}{'raw'}{'response_codes'}{'Code 415 - Unsupported Media Type'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 416 - Requested Range Not Satisfiable'};
    my $s5xx = $monthly{$month}{'raw'}{'response_codes'}{'Code 500 - Internal Server Error'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 502 - Bad Gateway'} +
        $monthly{$month}{'raw'}{'response_codes'}{'Code 503 - Service Unavailable'} + 
        $monthly{$month}{'raw'}{'response_codes'}{'Code 504 - Gateway Timeout'};
    my $s404 = $monthly{$month}{'raw'}{'response_codes'}{'Code 404 - Not Found'};
    my $s500 = $monthly{$month}{'raw'}{'response_codes'}{'Code 500 - Internal Server Error'};
    my $s503 = $monthly{$month}{'raw'}{'response_codes'}{'Code 503 - Service Unavailable'};

    $monthly{$month}{'derived'} = {
      'Hits' => {
        'Total'             => $totalhits,
        'Hits per Hour'     => $hitsperhour,
        'Hits per Second'   => int( ($hitsperhour / (60 * 60)) + 0.5),
        'Web'               => $totalhits - $wstotal,
        'WS'                => $wstotal,
        'WS %'              => int( ($wstotal / $totalhits * 100) + 0.5),
        'RDF'               => $rdf,
        'WS1' => {
          'Track'           => $ws1recording,
          'Release'         => $ws1release,
          'Release Group'   => $ws1releasegroup,
          'Artist'          => $ws1artist,
        },
        'WS2' => {
          'Recording'       => $ws2recording,
          'Release'         => $ws2release,
          'Release Group'   => $ws2releasegroup,
          'Artist'          => $ws2artist,
        },
        'WSX' => {
          'Recording'       => $ws1recording + $ws2recording,
          'Release'         => $ws1release + $ws2release,
          'Release Group'   => $ws1releasegroup + $ws2releasegroup,
          'Artist'          => $ws1artist + $ws2artist,
        }
      },
      'Status Codes' => {
        '2xx' => $s2xx,
        '3xx' => $s3xx,
        '4xx' => $s4xx,
        '5xx' => $s5xx,
        '404' => $s404,
        '500' => $s500,
        '503' => $s503
      }
    };
  }
}

sub output_csv {
  # Column headers
  print join (",",(
    'Month', 
    'Total Hits',

    'Web Hits',
    'Total WS Hits',
    'WS %',

    'ws/x/recording',
    'ws/x/release',
    'ws/x/artist',
    'ws/x/release-group',

    'ws/1/track',
    'ws/1/release',
    'ws/1/artist',
    'ws/1/release-group',

    'ws/2/recording',
    'ws/2/release',
    'ws/2/artist',
    'ws/2/release-group',

    'RDF',
    'Hits per Hour',
    'Hits per Second'
  ));
  print "\n";

  # Row data
  foreach my $month (sort keys %monthly) {
    print join (",",(
      $month,
      $monthly{$month}{'derived'}{'Hits'}{'Total'},

      $monthly{$month}{'derived'}{'Hits'}{'Web'},
      $monthly{$month}{'derived'}{'Hits'}{'WS'},
      $monthly{$month}{'derived'}{'Hits'}{'WS %'},

      $monthly{$month}{'derived'}{'Hits'}{'WSX'}{'Recording'},
      $monthly{$month}{'derived'}{'Hits'}{'WSX'}{'Release'},
      $monthly{$month}{'derived'}{'Hits'}{'WSX'}{'Release Group'},
      $monthly{$month}{'derived'}{'Hits'}{'WSX'}{'Artist'},

      $monthly{$month}{'derived'}{'Hits'}{'WS1'}{'Track'},
      $monthly{$month}{'derived'}{'Hits'}{'WS1'}{'Release'},
      $monthly{$month}{'derived'}{'Hits'}{'WS1'}{'Release Group'},
      $monthly{$month}{'derived'}{'Hits'}{'WS1'}{'Artist'},

      $monthly{$month}{'derived'}{'Hits'}{'WS2'}{'Recording'},
      $monthly{$month}{'derived'}{'Hits'}{'WS2'}{'Release'},
      $monthly{$month}{'derived'}{'Hits'}{'WS2'}{'Release Group'},
      $monthly{$month}{'derived'}{'Hits'}{'WS2'}{'Artist'},

      $monthly{$month}{'derived'}{'Hits'}{'RDF'},
      $monthly{$month}{'derived'}{'Hits'}{'Hits per Hour'},
      $monthly{$month}{'derived'}{'Hits'}{'Hits per Second'}
    ));
    print "\n";   
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

}


#search('2011','Web Service');

#sub search {
#  my ($year, @items) = @_;
#  my %search_results;
#
#  foreach my $item (@items) {
#    foreach my $month (keys %monthly) {
#      foreach my $group (keys %{ $monthly{$month} }) {
#        if ($monthly{$month}{$group}{$item}) {
#          $search_results{$month}{$group}{$item} = $monthly{$month}{$group}{$item};
#        }
#      }
#    }
#  }
#  print Dumper(\%search_results);
#}

sub parse_html {
  my $html = shift;
  my $te = HTML::TableExtract->new;

  $te->parse($html);

  my %stats = (
    'hits' => {
      'total'     => get_value($te, 0,3,1),
      'per_hour'  => get_value($te, 0,19,1),
    },
    'response_codes' => parse_table($te,0,0,1,30,50),
    'urls'      => parse_table($te,3,9,1),
    'countries' => parse_table($te,13,11,1),
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