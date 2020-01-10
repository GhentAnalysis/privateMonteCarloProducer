# Production of miniAOD samples

## Preparation of the expect script

In order to allow the production scripts to copy the (mini)AOD files to your pnfs disk (as your user disk will never have enough space to keep them),
the script needs to know how to create a new proxy, allowing for the gfal-mkdir and gfal-copy commands to be used.
You can create the needed file as:
```
mkdir ~/production
touch ~/production/proxyExpect.sh
chmod u=rwx,go-r ~/production/proxyExpect.sh
```

Of course, the permissions for this file should only allow you to read it, because you will open, edit and store your passphrase in this file:
```
#!/usr/bin/expect
set timeout 1000

spawn voms-proxy-init --voms cms
expect "Enter GRID pass phrase for this identity:"
send "<passphrase>\r"
expect eof
exit
```

## Preparation for automatic/emergency disk cleaning

The private monte carlo production could easily push you towards the quota in your user directory.
In order to clean-up old/finished working directories, as well as emergency clean-up in case your exceeding your quota,
put an hourly call foor the cleanProductionDir.py in your crontab:
```
# Minute Hour Day of Month Month Day of Week      Command    
  40     *    *            *     *                <path>/privateMonterCarloProducer/production/cleanProductionDir.py >> ~/production/log.txt 2>&1"
```


## Running the production
Simply run the production script with the era and the path to the gridpack:
```
  ./runProduction.sh Autumn18 ../gridpacks/displaced/<gridpack>
```

## Analysis of the log files
You could execute
```
  ./analyzeLogDir.py
```
in order to get an overview of finished jobs. If the output was correctly transferred to pnfs, the job will be listed as "DONE".
However, there are many reasons a job could fail. Some are random, or due to the always difficult access of the neutrino gun file access
through xrootd (don't bother asking for more copies through phedex, there is a stupid automatic script who will delete it pretty soon after).
If many jobs fail because of disk quota or the automatic disk clean-up, then you should killall the running runProduction.sh and reduce the maxRunningNewLastHour
parameter in the script before restarting it.
