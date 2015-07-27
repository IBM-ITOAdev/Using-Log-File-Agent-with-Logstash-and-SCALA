#!/bin/perl
#
#author: rafal.szypulka@pl.ibm.com
#version 1.0

use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use Archive::Tar;

my $i;
my @files;

#hash array that will be used to detect duplicate last_subdir-logfile combinantions for LFA conf/fmt
my %seen;

getopts('hf:t');
our($opt_h, $opt_f, $opt_t);

print_help() if ($opt_h || !$opt_f);

#static part of LFA config file
my $conf = <<"END_MSG";
FileComparisonMode=CompareByLastUpdate
ServerLocation=server.name
ServerPort=5530
FQDomain=yes
BufferEvents=YES
BufEvtMaxSize=102400
EventMaxSize=32768
ConnectionMode=CO
PollInterval=3
NumEventsToCatchUp=-1
ServerSSL=YES
END_MSG

#static part of LFA format file
my $fmt = <<"END_MSG";
REGEX AllRecords
(.*)
hostname LABEL
-file FILENAME
RemoteHost DEFAULT
logpath PRINTF("%s",file)
text \$1
env PROD
type WAS
functional PRINTF("%s",hostname)
END_MSG

open(LOGFILE_LIST,"<$opt_f") or die "Cannot open file: $!";

while(<LOGFILE_LIST>) {
	chomp;
	#my ($path, @tags) = split /,/;
	my ($path) = split /,/;
	my $file = basename($path);
	my $dirname = dirname($path);
	$dirname =~ /.*\/(\S+)\/(\S+)/;  	#extract last subdirectory name
	my $cluster = $1;
	my $subdir = $2;
	$file =~ s/\.log//g;  		        #strip .log extension 
	$file = $subdir . "-" .$file;  		# fmt/conf name convention is: last_subdir_name-log_file_name
	
	#additional check if there are no duplicates for the 'last_subdir_name-log_file_name' naming convention
	#first 15 characters has to be unique
	#if duplicate detected, unique number is added at the beginning of the log file name
	my $first15 = substr $file, 0, 15;
	$file = ++$i . $file if $seen{$first15}++; 
	
	push @files, "${file}_was.conf" if $opt_t;		#add files to array that will be used by tar function
	open(CONF,">${file}_was.conf") or die "Cannot open file: $!";
	binmode CONF;			              #binmode is used to create proper UNIX text files even on Windows
	if($file =~ /TextLog/) {
		print  CONF "LogSources=${path}\*\012";     #\012 is the UNIX line ending
	} else {
		print CONF "LogSources=${path}\012";		#\012 is the UNIX line ending
	}
	print CONF "BufEvtPath=/apps/scala/logs/${file}_was.cache\012";
	$conf =~ s/\015//g;			                    #strip windows CR if script is executed on windows
	print CONF $conf;
	close CONF;
	
	push @files, "${file}_was.fmt" if $opt_t;
	open(FMT,">${file}_was.fmt") or die "Cannot open file: $!";;
	binmode FMT;
	$fmt =~ s/\015//g;
	print FMT $fmt;
	print FMT "cluster NONE\012";
	if ($file =~ /SystemOut/) {
		print FMT "module SystemOut.log\012";
	} elsif ($file =~ /SystemErr/) {
		print FMT "module SystemErr.log\012";
	} elsif ($file =~ /native_stdout/) {
		print FMT "module native_stdout.log\012";
	} elsif ($file =~ /native_stderr/) {
		print FMT "module native_stderr.log\012";
	} elsif ($file =~ /TextLog/) {
		print FMT "module SystemOut.log\012";
	}
	print FMT "instance $subdir\012";
	
	print FMT "END\012";
	close FMT;
}
close LOGFILE_LIST;
Archive::Tar->create_archive( 'lfa_config.tar.gz', COMPRESS_GZIP, @files ) if $opt_t;


sub print_help {
my $USAGE =<<USAGE;

     Usage:
         lfa_config_gen.pl [-h] -f <input_file_name> [-t]

         where:
           -f <input_file_name>: specifies input file name 
                                with list of log files 
                                and corresponding tag definitions
           -t create gzipped tar
           -h Prints out this helpful message

USAGE
print "$USAGE\n";
exit 0;
}
