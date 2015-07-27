#!/bin/sh

#Please note that script has to be executed in /apps/scala/config/lo directory
#script lfa_config_gen_ihs.pl must be present in /apps/scala/config/lo directory


find /path -name "*access_log*"|sed 's/access_log.*/access_log/' > logfiles_ihs.txt
find /path -name "*error_log*"|sed 's/error_log.*/error_log/' >> logfiles_ihs.txt
uniq logfiles_ihs.txt logfiles_ihs_uniq.txt

rm *_ihs.conf *_ihs.fmt
echo "Creating config files..."
chmod 755 *.pl
./lfa_config_gen_ihs.pl -f logfiles_ihs_uniq.txt

/apps/scala/bin/itmcmd agent -o scala1 stop lo

chown -R scala:scala /apps/scala

/apps/scala/bin/secureMain -g scala lock

su - scala -c /apps/scala/bin/itmcmd agent -o scala1 start lo