#!/bin/sh

#Please note that script has to be executed in <LFA_HOME>/config/lo directory
#script lfa_config_gen_xxx.pl must be present in <LFA_HOME>/config/lo directory

## Genrate list of logfiles to monitor
find /path -name "*logfile.log" > logfiles_xxx.txt

# Remove existing LFA configuration
rm *_was.conf *_was.fmt
echo "Creating config files..."

chmod 755 *.pl

#Generate new config and format files
./lfa_config_gen_xxx.pl -f logfiles_xxx.txt


#Restart LFA and fix permisions
<LFA_HOME>/bin/itmcmd agent -o scala1 stop lo

chown -R scala:scala <LFA_HOME>

<LFA_HOME>/bin/secureMain -g scala lock

su - scala -c <LFA_HOME>/bin/itmcmd agent -o scala1 start lo