# Heavy neutrino gridpack creation

## Setup

In order to have the correct genproductions setup, run the followin script:
```
./setupGenProductions.sh
```

It currently checks out the mg242legacy branch of the cms-sw genproduction repository. This corresponds with Madgraph\_aMC@NLO 2.4.2, which was the stable release when we started our first heavy neutrino simulations.
At the moment you are reading this, there might be more recent releases available. If you change the release, make sure you understand the setup and verify if everything still works as expected.

There are a few updates over the mg242legacy branch, these are automatically copied over to genproductions/bin/MadGraph5_aMCatNLO by the setupGenProductions.sh script immediately following the git clone.
These include:
- Updated makeHeavyNeutrinoCards.py in the cards/production/2017/13TeV/exo_heavyNeutrino_LO directory (adding the dirac HNL cc option)
- The modifications (fixGridpackForDisplacedLO.sh and addDisplacedVertex.py) to modify a gridpack for displaced vertices
- A script to fix a typo in the output LHE file (fixGridpack.sh) because Madgraph\_aMC@NLO 2.4.2 generates this typo when MadSpin is used

# Creating a gridpack
Because we produce heavy neutral leptons with low masses and hadronic decay channels, the gridpacks are created using a model with massive quarks/leptons and including off-diagonal CKM entries. As a result,
only LO gridpacks have been created in the recent years (NLO would conflict with these settings).

You can create new gridpacks using the following script:
```
./createHeavyNeutrinoGridpack_LO.py --help
```
Use the --help option to show the optional arguments.
