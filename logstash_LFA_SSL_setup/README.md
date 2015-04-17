**Configuration procedure below was tested on AIX with LFA 6.3. Requires GSKit 8.xx (tested on GSKit 08.00.50.05)**

# 1. SSL configuration on logstash server

The following procedure needs to be done if communication between LFA and logstash needs to be encrypted
On the logstash server, ensure you have the latest updates on the system. 
There have been a number of updates recently for SSL related security issues.  Run a system update.

On the logstash server:

```sh
mkdir -p /etc/pki/tls/myCA/signedcerts && mkdir /etc/pki/tls/myCA/private
cd /etc/pki/tls/myCA
echo '01' > serial && touch index.txt
```
Create file caconfig.cnf

```
# My sample caconfig.cnf file.
#
# Default configuration to use when one is not provided on the command line.
#
[ ca ]
default_ca      = local_ca
#
#
# Default location of directories and files needed to generate certificates.
#
[ local_ca ]
dir             = /etc/pki/tls/myCA
certificate     = $dir/cacert.pem
database        = $dir/index.txt
new_certs_dir   = $dir/signedcerts
private_key     = $dir/private/cakey.pem
serial          = $dir/serial
#       
#
# Default expiration and encryption policies for certificates.
#
default_crl_days        = 365
default_days            = 1825
default_md              = sha1
#       
policy          = local_ca_policy
x509_extensions = local_ca_extensions
#
# Copy extensions specified in the certificate request
#
copy_extensions = copy       
#
# Default policy to use when generating server certificates.  The following
# fields must be defined in the server certificate.
#
[ local_ca_policy ]
[ local_ca_policy ]
commonName              = supplied
stateOrProvinceName     = supplied
countryName             = supplied
emailAddress            = supplied
organizationName        = supplied
organizationalUnitName  = supplied
#
# x509 extensions to use when generating server certificates.
#
[ local_ca_extensions ]
basicConstraints        = CA:false
#
# The default root certificate generation policy.
#
[ req ]
default_bits    = 2048
default_keyfile = /etc/pki/tls/myCA/private/cakey.pem
default_md      = sha1
#       
prompt                  = no
distinguished_name      = root_ca_distinguished_name
x509_extensions         = root_ca_extensions
#
#
# Root Certificate Authority distinguished name.  Change these fields to match
# your local environment!
#
[ root_ca_distinguished_name ]
commonName              = MyOwn Root Certificate Authority
stateOrProvinceName     = GA
countryName             = US
emailAddress            = root@keepout.com
organizationName        = Mine
organizationalUnitName  = Dev
#       
[ root_ca_extensions ]
basicConstraints        = CA:true
```
```sh
export OPENSSL_CONF=/etc/pki/tls/myCA/caconfig.cnf
openssl req -x509 -newkey rsa:2048 -out cacert.pem -outform PEM -days 1825
openssl x509 -in cacert.pem -out cacert.crt
```
Create file logsashys0-5.cnf using the following template. Update marked lines.
```
#
# exampleserver.cnf
#

[ req ]
prompt                  = no
distinguished_name      = server_distinguished_name
req_extensions          = v3_req

[ server_distinguished_name ]
commonName              = 9.42.48.152  <-- update to logstash server IP
stateOrProvinceName     = GA
countryName             = US
emailAddress            = root@keepout.com
organizationName        = Mine
organizationalUnitName  = Dev

[ v3_req ]
basicConstraints        = CA:FALSE
keyUsage                = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName          = @alt_names

[ alt_names ]
DNS.0                   = nc048152  <-update
DNS.1                   = nc048152.tivlab.raleigh.ibm.com  <-update
```
```sh
export OPENSSL_CONF=/etc/pki/tls/myCA/logsashys0-5.cnf
openssl req -newkey rsa:1024 -keyout tempkey.pem -keyform PEM -out tempreq.pem -outform PEM
openssl rsa < tempkey.pem > server_key.pem
export OPENSSL_CONF=/etc/pki/tls/myCA/caconfig.cnf
openssl ca -in tempreq.pem -out server_crt.pem
rm -f tempkey.pem && rm -f tempreq.pem
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mycert.pem -out mycert.pem
openssl pkcs12 -export -out mycert.pfx -in mycert.pem -name "logstashys0-5 for LFA"
```
Transfer certifiacte mycert.pfx to server with LFA.

# 2. Sample logstash config for TCP with SSL:

```perl
tcp {
	port => 5530
	ssl_enable => true
	ssl_cert => "/etc/pki/tls/myCA/server_crt.pem"  
	ssl_key => "/etc/pki/tls/myCA/server_key.pem"
	ssl_cacert => "/etc/pki/tls/myCA/cacert.pem"
	ssl_verify => false
	type  => "LFA-EIF-RAW-SSL"
}
```
# 3. LFA SSL setup

Import self-signed certificate exported on logstash server and import to keystore on LFA server using the following steps.
It needs to be done on least one LFA box sending data to logstash server configured using steps above.
Keystore file created on one LFA box can be copied to other LFAs sending data to the same logstash server. Procedure and automation script described in chapter below.

On UNIX/Linux box where LFA is installed:
  
```sh
export LIBPATH=/opt/unity/LogAnalysis_BNP_LFA/aix526/gs/lib64  # update to reflect your install path
cd  /opt/unity/LogAnalysis_BNP_LFA/aix526/gs/bin               # update to reflect your install path
./gsk8capicmd_64 -keydb -create -type pkcs12 -populate -db lfa-logstash.p12 -pw logstash -stash
./gsk8capicmd_64 -cert -import -db /path/to/mycert.pfx -pw logstash -target lfa-logstash.p12 -target_pw logstash # update path to certificate
./gsk8capicmd_64 -cert -list -db lfa-logstash.p12 -pw logstash  # make sure you see your cert label
```

Add the following to the LFA "instance" .config (not the .conf)  (for ex /lfa_inst_path/config/lo_default_workload_instance.config)
```sh
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
KDEBE_KEYRING_FILE='/opt/IBM-LFA-6.30/lx8266/gs/bin/lfa-logstash.p12'  <-- update to your path to this file
KDEBE_KEYRING_STASH='/opt/IBM-LFA-6.30/lx8266/gs/bin/lfa-logstash.sth' <-- update to your path to this file
KDEBE_KEY_LABEL='Certificate for LFA' <-- update to your cert label
```
Add the following to each LFA .conf file:
```
# EIF SSL Settings
ServerSSL=YES
```

# LFA SSL setup replication

After at least one LFA is configured for SSL encrypted comunication with logstash, LFA SSL configuration can be easily replicated to other LFAs sending data to the same logstash server.

1. Copy files: 
* lfa-logstash.p12
* lfa-logstash.sth 

created on first LFA server together with script **lfa_ssl_enable.sh** to the <lfa_instt_dir>/config directory on target LFA server. 
2. Execute script **lfa_ssl_enable.sh**.
