# Automated creation of LFA configuration and format files
The following solution example shows how to automatically generate LFA configuration and format files for Log Analytics. It is particulary useful in case of streaming miltiple log files using single LFA.
We will show also how to enrich LFA log entries sent to Log Analytics with additional metadata.

# Adding metadata to log entries sent from LFA to Log Analytics
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

# Automation for LFA Configuration
1. Log File Agents deployed automatically using silent installation [script] (../LFA_silent_install)
