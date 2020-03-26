# privateMonteCarloProducer

Package to make gridpacks and produce miniAOD events with them.
Mainly oriented towards the heavy neutrino simulations, but parts of it could be used for other MC samples as well.

# [gridpacks](gridpacks)
In this directory you find the needed setup for the heavy neutrino gridpacks.

# [production](production)
In this directory you find the setup and scripts to produce AOD and miniAOD samples, which can be used
for each gridpack which is produced following CMS standards (also non-heavy neutrino gridpacks).
The setup and scripts are aimed for use at the Belgian T2 (qsub).

# [monitoring](monitoring)
Here you find some monitoring scripts, which can be controlled using cron jobs, in order to have a daily update
of cross sections, number of events, and other parameters.
