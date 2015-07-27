# Automated creation of LFA configuration and format files
The following solution example shows how to automatically generate LFA configuration and format files for Log Analytics. It is particulary useful in case of streaming miltiple log files using single LFA.
We will show also how to enrich LFA log entries sent to Log Analytics with additional metadata.

## Adding metadata to log entries sent from LFA to Log Analytics
Metadata is added using the LFA format file. For example, metadata can tell us where each record came from (like server, cluster, application_instance, logfile_name, etc.) 
```
REGEX AllRecords
(.*)
hostname LABEL
-file FILENAME
RemoteHost DEFAULT
logpath PRINTF("%s",file)
text $1
env DEV
app application_name
cluster cluster_name
module module_name
instance instance_name
END
```

## Automation for LFA Configuration
1. Log File Agents deployed automatically using silent installation [**script**] (../LFA_silent_install)
2. LFA configuration automation
- Determine list of log files on local server, based on rules like paths, file name patterns, modification date, etc.
- Clear previous LFA configuration
- Generate pair of configuration files (.conf and .fmt) for each log file based on the rules defined for each log type. Enrich LFA format files with metadata based on logic defined in script code.
- Set proper file permissions
- Restart Log File Agent

The process described above can be automated using scripts.

**Example:**

lfa_config_gen_was.sh
- generate list of log files to monitor
- clear previous LFA configuration
- execute perl script that generates pair of configuration files (.conf and .fmt) for each log file from the list
- set proper file permissions
- restart Log File Agent

```sh
#!/bin/sh

#Please note that script has to be executed in <LFA_HOME>/config/lo directory
#script lfa_config_gen_was.pl must be present in <LFA_HOME>/config/lo directory


find /path -name SystemOut.log > logfiles_was.txt
find /path/WebSphere85/profiles/logs/node -name SystemOut.log|grep -v nodeagent>> logfiles_was.txt
find /path -name SystemErr.log >> logfiles_was.txt
find /path/WebSphere85/profiles/logs/node -name SystemErr.log|grep -v nodeagent>> logfiles_was.txt
find /path -name native_stdout.log/node >> logfiles_was.txt
find /path/WebSphere85/profiles/logs/node -name native_stdout.log|grep -v nodeagent>> logfiles_was.txt
find /path -name native_stderr.log >> logfiles_was.txt
find /path/WebSphere85/profiles/logs/node -name native_stderr.log|grep -v nodeagent>> logfiles_was.txt
echo '/path/WebSphere/profiles85/logs/node/nodeagent/TextLog' >>logfiles_was.txt
echo '/path/WebSphere/profiles85/logs/dmgr/dmgr/TextLog' >>logfiles_was.txt


rm *_was.conf *_was.fmt
echo "Creating config files..."
chmod 755 *.pl
./lfa_config_gen_was.pl -f logfiles_was.txt

<LFA_HOME>/bin/itmcmd agent -o scala1 stop lo

chown -R scala:scala <LFA_HOME>

<LFA_HOME>/bin/secureMain -g scala lock

su - scala -c <LFA_HOME>/bin/itmcmd agent -o scala1 start lo
```

lfa_config_gen_was.pl
- generates pair of configuration files (.conf and .fmt) for each log file from the input list
- adds metadata to LFA fmt file

```perl
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
ServerLocation=server.net
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
	$dirname =~ /.*\/(\S+)\/(\S+)/;  	      #extract last subdirectory name
	my $cluster = $1;
	my $subdir = $2;
	$file =~ s/\.log//g;  		              #strip .log extension 
	$file = $subdir . "-" .$file;  		      # fmt/conf name convention is: last_subdir_name-log_file_name
	
	#additional check if there are no duplicates for the 'last_subdir_name-log_file_name' naming convention 
	#(first 15 characters has to be unique)
	#if duplicate detected, unique number is added at the beginning of the log file name
	
	my $first15 = substr $file, 0, 15;
	$file = ++$i . $file if $seen{$first15}++; 
	
	push @files, "${file}_was.conf" if $opt_t;		  #add files to array that will be used by tar function
	open(CONF,">${file}_was.conf") or die "Cannot open file: $!";
	binmode CONF;			              #binmode is used to create proper UNIX text files even on Windows
	if($file =~ /TextLog/) {
		print  CONF "LogSources=${path}\*\012";       #\012 is the UNIX line ending
	} else {
		print CONF "LogSources=${path}\012";		  #\012 is the UNIX line ending
	}
	print CONF "BufEvtPath=/apps/scala/logs/${file}_was.cache\012";
	$conf =~ s/\015//g;			                      #strip windows CR if script is executed on windows
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

#create gzipped tar file from all generated files
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
```

See attached scripts for examples for Websphere Application Server logs, Oracle alert log and IBM HTTP Server access and error logs.
Scripts can be easily imported end executed on target servers by configuration management tools.