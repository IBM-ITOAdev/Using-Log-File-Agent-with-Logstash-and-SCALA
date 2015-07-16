#!/bin/sh
#Script does unattended LFA installation in /apps/scala

tee /tmp/lo_silent_install.txt <<EOF
INSTALL_ENCRYPTION_KEY=IBMTivoliMonitoringEncryptionKey
INSTALL_PRODUCT=lo
MS_CMS_NAME=TEMS
DEFAULT_DISTRIBUTION_LIST=NEW
EOF
./install.sh -q -h /apps/scala -p /tmp/lo_silent_install.txt
tee /tmp/lo_silent_config.txt <<EOF
CMSCONNECT = NO
INSTANCE = scala1
KLO_SEND_EIF_EVENTS=Yes
KLO_SEND_ITM_EVENTS=No
KLO_AUTO_INIT_SYSLOG=USE_CONF_FILE_VALUE
KLO_PROCESS_PRIORITY_CLASS=USE_CONF_FILE_VALUE
KLO_FILE_DISCOVERY_DIR=$\{CANDLE_HOME\}/config/lo
KLO_PROCESS_MAX_CPU_PCT=10
EOF
/apps/scala/bin/itmcmd config -A -o scala1 -p /tmp/lo_silent_config.txt lo
/apps/scala/bin/itmcmd agent -o scala1 start lo