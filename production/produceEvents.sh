#PBS -l nodes=1:ppn=1
#!/bin/bash

# Make sure logging is captured on the T2 (echo/printf are not captured)
log(){
  python -c "import logging;logging.basicConfig(level = logging.INFO);logging.info('$1')"
}


# cmsswRelease RELEASE FUNCTION
#   checks out CMSSW RELEASE and applies FUNCTION with modifications to it
cmsswRelease(){
  if [ -r $1/src ] ; then
    echo release $1 already exists
  else
    scram p CMSSW $1
  fi
  cd $1/src
  eval `scram runtime -sh`

  if [ -n "$2" ]; then $2; fi

  scram b
  cd ../../
}

events=1000

log "era:$era"
log "gridpack:$gridpackDir/$gridpack"
log $promptOrDisplaced
log $spec

#
# Choosing the pythia fragment
#

#
# Setting directories
#
if [[ $era == "Moriond17" ]]; then
  pnfsAOD=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName/
  pnfsMiniAOD=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/$promptOrDisplaced/$shortName/
  prodDir=/user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber/
else
  pnfsAOD=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/$era/$promptOrDisplaced/$shortName/
  pnfsMiniAOD=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/$era/$promptOrDisplaced/$shortName/
  prodDir=/user/$USER/production/${gridpack}_${promptOrDisplaced}_$era/$productionNumber$spec/
fi

#
# Quit if file already exists
#
shortName="${gridpack%_slc*}$spec"
if [ -f $pnfsMiniAOD/heavyNeutrino_$productionNumber.root ]; then
  log "Skipping, outputfile already exists"
  sleep 1
  exit
fi

if [ -d $prodDir//CMSSW* ]; then
  log "Directory still in use by other job"
  sleep 1
  exit
fi

mkdir -p $prodDir
cd $prodDir


#
# Find the gridpack
#
gridpackPath=$gridpackDir/${gridpack}_tarball.tar.xz
log "Using gridpack $gridpackPath"

#
# Preparation of the pythia fragment (which get moved to the CMSSW release in the GEN-SIM snippets)
#
prepareFragment(){
  if [[ $era == "Moriond17" ]]; then
    if [[ $spec == *"tauLeptonic"* ]]; then fragment='pythiaFragment_LO_tauLeptonic.py'
    else                                    fragment='pythiaFragment_LO.py'
    fi
  else
    if [[ $spec == *"tauLeptonic"* ]]; then fragment='pythiaFragmentCP5_LO_tauLeptonic.py'
    else                                    fragment='pythiaFragmentCP5_LO.py'
    fi
  fi
  log "Using fragment $fragment"

  mkdir -p Configuration/GenProduction/python
  cp $fragmentDir/pythiaFragments/$fragment Configuration/GenProduction/python/heavyNeutrino-fragment.py
  sed -i "s!GRIDPACK!${gridpackPath}!g" Configuration/GenProduction/python/heavyNeutrino-fragment.py
  [ -s Configuration/GenProduction/python/heavyNeutrino-fragment.py ] || exit $?;
}


source $VO_CMS_SW_DIR/cmsset_default.sh

# GEN-SIM, DIGI-RECO + AOD and miniAODv3 steps
if [[ $era == "Moriond17" ]]; then
  source $fragmentDir/sequences/RunIISummer15wmLHEGS.sh
  sleep 1m
  source $fragmentDir/sequences/RunIISummer16DR80Premix.sh
  sleep 1m
  source $fragmentDir/sequences/RunIISummer16MiniAODv3.sh
elif [[ $era == "Fall17" ]]; then
  source $fragmentDir/sequences/RunIIFall17wmLHEGS.sh
  sleep 1m
  source $fragmentDir/sequences/RunIIFall17DRPremix.sh
  sleep 1m
  source $fragmentDir/sequences/RunIIFall17MiniAODv2.sh
elif [[ $era == "Autumn18" ]]; then
  source $fragmentDir/sequences/RunIIFall18wmLHEGS.sh
  sleep 1m
  source $fragmentDir/sequences/RunIIAutumn18DRPremix.sh
  sleep 1m
  source $fragmentDir/sequences/RunIIAutumn18MiniAOD.sh
fi
sleep 1m


# In order to get a new proxy
/user/$USER/production/proxyExpect.sh

gfal-mkdir -p -vvv srm://maite.iihe.ac.be:8443$pnfsMiniAOD
gfal-copy -f -vvv file://$prodDir/heavyNeutrinoMiniAOD.root srm://maite.iihe.ac.be:8443$pnfsMiniAOD/heavyNeutrino_$productionNumber.root

gfal-mkdir -p srm://maite.iihe.ac.be:8443$pnfsAOD
gfal-copy -f file://$prodDir/heavyNeutrinoAOD.root srm://maite.iihe.ac.be:8443$pnfsAOD/heavyNeutrino_$productionNumber.root


# clean up
cd ..
rm -r $prodDir
