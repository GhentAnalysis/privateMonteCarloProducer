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

## Running the production
Simply run the production script with the era and the path to the gridpack:
```
  ./runProduction.sh Autumn18 ../gridpacks/displaced/<gridpack>
```
