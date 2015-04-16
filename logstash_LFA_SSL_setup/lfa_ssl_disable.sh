#/bin/sh
# Disable SSL for all LFA conf files
# Script assume that LFA is installed in /apps/scala and runs as user scala

for conf in /apps/scala/config/lo/*.conf
do 
	if grep "^ServerSSL=YES" $conf > /dev/null
	then
		perl -pi -e 's/ServerSSL=YES\n//' $conf
		echo "$conf SSL disabled"
	else
		echo "$conf SSL already disabled"
	fi
done

su - scala -c /apps/scala/bin/itmcmd agent -o scala1 stop lo
su - scala -c /apps/scala/bin/itmcmd agent -o scala1 start lo
