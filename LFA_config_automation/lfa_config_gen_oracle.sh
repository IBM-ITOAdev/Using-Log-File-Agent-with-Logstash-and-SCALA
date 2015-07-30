#!/bin/sh

#Please note that script has to be executed in /apps/scala/config/lo directory
#script lfa_config_gen_oracle.pl must be present in /apps/scala/config/lo directory


find /apps/oracle/diag/rdbms -name "alert_*.log" > logfiles_oracle.txt

rm *_oracle.conf *_oracle.fmt
echo "Creating config files..."

./lfa_config_gen_oracle.pl -f logfiles_oracle.txt

/apps/scala/bin/itmcmd agent -o scala1 stop lo

chown -R scala:scala /apps/scala

/apps/scala/bin/secureMain -g scala lock

su - scala -c /apps/scala/bin/itmcmd agent -o scala1 start lo