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