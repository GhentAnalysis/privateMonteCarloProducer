# Monitoring of gridpacks/miniAOD samples
This directory contains the scripts needed to collect information from the gridpacks and samples, and to place them on a website.

In order to get an up-to-date list of your gridpack's cross sections, events, etc... add these daily tasks in your crontab:
```
# Minute Hour Day of Month Month Day of Week      Command   
  30     0    *            *     *                zsh -c "<path>/privateMonteCarloProducer/monitoring/listCrossSectionsAndEvents.py"
  30     6    *            *     *                zsh -c "<path>/privateMonteCarloProducer/monitoring/listAvailableSamples.py"
```
(you can use bash instead zsh too of course)
