# Monitoring of gridpacks/miniAOD samples
This directory contains the scripts needed to collect information from the gridpacks and samples, and to place them on a website.

## Extraction of the cross sections
In order to get an up-to-date list of your gridpack's cross sections, add this daily task in your crontab:
```
# Minute Hour Day of Month Month Day of Week      Command   
  30     0    *            *     *                <path>/privateMonteCarloProducer/monitoring/listHeavyNeutrinoCrossSections.py
```
