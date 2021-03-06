#!/usr/bin/perl
#===============================================================================
#
#         FILE:  check_file_content.pl
#
#        USAGE:  ./check_file_content.pl
#
#  DESCRIPTION:  Nagios plugin to check file content
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pierre Mavro (), pierre@mavro.fr
#      COMPANY:
#      VERSION:  0.1
#      CREATED:  10/05/2010 09:25:56
#     REVISION:  ---
#===============================================================================

use warnings;
use strict;
use Getopt::Long;

my %RETCODES = ('OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3);

# Help
sub help
{
  print "Usage : check_file_content.pl -f file -i include -e exclude -n lines_number [-h]\n\n";
  print "Options :\n";
  print " -f\n\tFull path to file to analyze\n";
  print " -n\n\tNumber of lines to find (default is 1)\n";
  print " -i\n\tInclude pattern (can add multiple include)\n";
  print " -e\n\tExclude pattern (can add multiple include)\n";
  print " -a\n\tCheck if file content is not in file\n";
  print " -h, --help\n\tPrint this help screen\n";
  print "\nExample : check_file_content.pl -f /etc/passwd -i 0 -e root -n 5\n";
  exit $RETCODES{"UNKNOWN"};
}

sub check_args
{
  help if !@ARGV;

  my ($file,@include,@exclude,$absent);
  my $num=1;

  # Set options
  GetOptions( 	"help|h"    => \&help,
  "f=s"   	=> \$file,
  "i=s"		=> \@include,
  "e=s"		=> \@exclude,
  "n=i"       => \$num,
  "a"       => \$absent);

  unless (($file) and (@include))
  {
    &help;
  }
  else
  {
    check_soft($file,$num,\@include,\@exclude,$absent);
  }
}

sub check_soft
{
  my $file=shift;
  my $num=shift;
  my $ref_include=shift;
  my $ref_exclude=shift;
  my $absent=shift;
  my @include = @$ref_include;
  my @exclude = @$ref_exclude;
  my $i=0;

  if (!open(FILER, "<$file"))
  {
    print "Can't open $file: $!\n";
    exit $RETCODES{"CRITICAL"};
  }

  while(<FILER>)
  {
    chomp($_);
    my $line=$_;
    my $found=0;

    # Should match
    foreach (@include)
    {
      if ($line =~ /$_/)
      {
        $found=1;
        last;
      }
    }

    # Shouldn't match
    if (@exclude)
    {
      foreach (@exclude)
      {
        if ($line =~ /$_/)
        {
          $found=0;
          last;
        }
      }
    }

    $i++ if ($found == 1);
  }
  close(FILER);
  if ($absent)
  {
    if ($i <= $num)
    {
      print "OK for $file ($i found)\n";
      exit $RETCODES{"OK"};
    }
    else
    {
      print "FAILED on $file. Found pattern $i times\n";
      exit $RETCODES{"CRITICAL"};
    }
  }else
  {
    if ($i > 0)
    {
      if ($i >= $num)
      {
        print "OK for $file ($i found)\n";
        exit $RETCODES{"OK"};
      }
      else
      {
        print "FAILED on $file. Found only $i on $num\n";
        exit $RETCODES{"CRITICAL"};
      }
    }
    else
    {
      print "FAILED on $file\n";
      exit $RETCODES{"CRITICAL"};
    }
  }
}

check_args;
