#PBS -l nodes=1:ppn=1
#!/bin/bash

productionNumber="$1"
gridpack="$2"
gridpackDir="$3"
promptOrDisplaced="$4"
fragmentDir="$5"
era="$6"

export X509_USER_PROXY=/user/$USER/x509up_u`id -u`

# Make sure logging is captured on the T2 (echo/printf are not captured)
log(){
  echo $1
  #python -c "import logging;logging.basicConfig(level = logging.INFO);logging.info('$1')"
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
shortName="${gridpack%_slc*}$spec"
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
if [ -f $pnfsMiniAOD/heavyNeutrino_$productionNumber.root ]; then
  log "Skipping, outputfile already exists: $pnfsMiniAOD/heavyNeutrino_$productionNumber.root"
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
#/user/$USER/production/proxyExpect.sh
export X509_USER_PROXY=/user/$USER/x509up_u`id -u`

mkdir -p $pnfsMiniAOD
cp -f $prodDir/heavyNeutrinoMiniAOD.root $pnfsMiniAOD/heavyNeutrino_$productionNumber.root

## Do not store AOD anymore, T2BE is running out of disk space
#mkdir -p $pnfsAOD
#cp -f $prodDir/heavyNeutrinoAOD.root $pnfsAOD/heavyNeutrino_$productionNumber.root


# clean up
cd ..
rm -r $prodDir
