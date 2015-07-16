#/bin/sh
# Enable SSL for all LFA conf files - QA, BENCH, PROD
# Script assume that LFA is installed in /apps/scala and runs as user scala

for conf in /apps/scala/config/lo/*.conf
do 
	if grep "^ServerSSL=YES" $conf > /dev/null
	then
		echo "$conf SSL already enabled"
	else
		echo "ServerSSL=YES" >> $conf
		echo "$conf SSL enabled"
	fi
done

cp /apps/scala/config/lo_scala1.config /apps/scala/config/lo_scala1.config.backup

if grep "^KDEBE_KEYRING_FILE" /apps/scala/config/lo_scala1.config >/dev/null
then
echo "lo_scala1.config already configured for SSL"
else
cat <<EOT >> /apps/scala/config/lo_scala1.config
#
# LFA EIF SSL
#
#no by default
KDEBE_FIPS_MODE_ENABLED='N'
#no by default
ITM_AUTHENTICATE_SERVER_CERTIFICATE='N'

#as needed for debugging
# RAS1 tracing in the KEF library (SSL stuff)
#KEF_DEBUG='A'
#KEF_DEBUG=N
#KDE_DEBUG=D
#KBB_RAS1=ERROR


#default ciphers
#KDEBE_V3_CIPHER_SPECS=nn (see defaults and options above)
#The following TLS and SSL ciphers are supported by the monitoring agent by default:
#    TLS_RSA_WITH_AES_256_CBC_SHA
#    TLS_RSA_WITH_AES_128_CBC_SHA
#    SSL_RSA_WITH_3DES_EDE_CBC_SHA

#ITM_AUTHENTICATE_SERVER_CERTIFICATE='N'  (No by default)
KDEBE_KEYRING_FILE='/apps/scala/aix526/gs/bin/lfa-logstash-prod.p12'
KDEBE_KEYRING_STASH='/apps/scala/aix526/gs/bin/lfa-logstash-prod.sth'
KDEBE_KEY_LABEL='logstashys0-5 for LFA prod'
EOT

fi

cp lfa-logstash-prod.sth /apps/scala/aix526/gs/bin/lfa-logstash-prod.sth
cp lfa-logstash-prod.p12 /apps/scala/aix526/gs/bin/lfa-logstash-prod.p12
chown scala:scala  /apps/scala/aix526/gs/bin/lfa-logstash*

/apps/scala/bin/itmcmd agent -o scala1 stop lo
chown -R scala:scala /apps/scala
/apps/scala/bin/secureMain -g scala lock
su - scala -c /apps/scala/bin/itmcmd agent -o scala1 start lo
