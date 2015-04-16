# Streaming Logs using IBM C&SI Log File Agent (LFA) to Logstash and Smart Cloud Analytics Log Analysis (SCALA)

# What's Included?

1. A sample logstash configuration **(lfa-logstash.conf)**
2. A logstash grok pattern file for default LFA log messages **(LFALOGSTASH)**
3. LFA unattended install script
4. logstash and LFA SSL configuration procedure and automation scripts

# Deploying the Content Pack

1. Review the sample logstash configuration **lfa-logstash.conf** and determine how you will use the inputs, filters and outputs.  You can use this example or just copy the needed parts into your main logstash configuration file. Pay close attention to the NOTES within the **lfa-logstash.conf** and **LFALOGSTASH** files.

2. Update the TCP input as needed, especially the port number you will use. The default EIF Receiver port that LFAs normally point to for use with SCALA is TCP 5529.  Use a different port if you plan on running logstash on the same server.

3. Review the filters section and determine if any changes are needed based upon how you use logstash, which version you use, etc.

4. Review the output section and update based on your current logstash integration with SCALA. This example configuration will only work with the upcoming release of the SCALA-Logstash Integration.  If you do not have this, contact Doug McClure for assistance.

5. Place the logstash GROK pattern file **LFALOGSTASH** into the appropriate location.  If you are using logstash 1.4.2, you may place this into the /patterns directory and you'll be all set. If you are using logstash 1.5 beta, you can place it into the same /patterns directory, but you will need to use the patterns_dir setting to this location in each filter using the GROK patterns (eg multiline, grok).

6. Create a SCALA datasource which uses the host and path values to match what you're setting in your logstash configuration. 

7. Update your LFA configuration (.conf) files to point to your logstash server and TCP input port. Restart LFAs as needed.

8. Start up logstash and verify connections from LFAs are established. Watch for activity in logstash stdout or within SCALA search results.

# Need Help?

This is a community contributed content pack and no explicit support, guarantee or warranties are provided by IBM nor the contributor. Feel free to engage the community on the ITOAdev forum if you need help!
