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
1. Log File Agents deployed automatically using silent installation [script] (../LFA_silent_install)
2. LFA configuration automation
- Determine list of log files on local server, based on rules like paths, file name patterns, modification date, etc.
- Clear previous LFA configuration
- Generate pair of configuration files (.conf and .fmt) for each log file based on the rules defined for each log type. Enrich LFA format files with metadata based on logic defined in script code.
- Set proper file permissions
- Restart Log File Agent

The process described above can be automated using scripts.
**Example:**

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


