#PBS -l nodes=1:ppn=1
#!/bin/bash

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

log "era:Moriond17"
log "gridpack:$gridpackDir/$gridpack"
log $promptOrDisplaced
log $spec

# Set default fragment
if [[ $spec == *"tauLeptonic"* ]]; then fragment='pythiaFragment_LO_tauLeptonic.py'
else                                    fragment='pythiaFragment_LO.py'
fi
log "Using fragment $fragment"

#
# Quit if file already exists
#
shortName="${gridpack%_slc*}$spec"
if [ -f /pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root ]; then
  log "Skipping, outputfile already exists"
  sleep 1
  exit
fi

if [ -d /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber/CMSSW* ]; then
  log "Directory still in use by other job"
  sleep 1
  exit
fi

mkdir -p /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec
cd /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec


#
# Find the gridpack
#
gridpackPath=$gridpackDir/${gridpack}_tarball.tar.xz
log "Using gridpack $gridpackPath"


source $VO_CMS_SW_DIR/cmsset_default.sh

# GEN-SIM, DIGI-RECO + AOD and miniAODv3 steps
source $fragmentDir/sequences/RunIISummer15wmLHEGS.sh
sleep 1m
source $fragmentDir/sequences/RunIISummer16DR80Premix.sh
sleep 1m
source $fragmentDir/sequences/RunIISummer16MiniAODv3.sh
sleep 1m


# In order to get a new proxy
/user/$USER/production/proxyExpect.sh

gfal-mkdir -p -vvv srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/$promptOrDisplaced/$shortName
gfal-copy -f -vvv file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec/EXO-RunIISummer16MiniAODv3-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root

gfal-mkdir -p srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName
gfal-copy -f file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec/EXO-RunIISummer16DR80Premix-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root


# clean up
cd ..
rm -r /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec
