#PBS -l nodes=1:ppn=1
#!/bin/bash

log(){
  python -c "import logging;logging.basicConfig(level = logging.INFO);logging.info('$1')"
}



events=1000

log "era:Autumn18"
log "gridpack:$gridpackDir/$gridpack"
log $promptOrDisplaced
log $spec

# Set default fragment
if [[ $spec == *"tauLeptonic"* ]]; then fragment='pythiaFragmentCP5_LO_tauLeptonic.py'
else                                    fragment='pythiaFragmentCP5_LO.py'
fi
log "Using fragment $fragment"

#
# Quit if file already exists
#
shortName="${gridpack%_slc*}$spec"
if [ -f /pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Autumn18/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root ]; then
  log "Skipping, outputfile already exists"
  sleep 1
  exit
fi

if [ -d /user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber/CMSSW_10_2_3 ]; then
  log "Directory still in use by other job"
  sleep 1
  exit
fi

mkdir -p /user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber$spec
cd /user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber$spec

#
# Find the gridpack
#
gridpackPath=$gridpackDir/${gridpack}_tarball.tar.xz
log "Using gridpack $gridpackPath"




#
# GEN-SIM
#
source $VO_CMS_SW_DIR/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc700
if [ -r CMSSW_10_2_16_patch1/src ] ; then 
 echo release CMSSW_10_2_16_patch1 already exists
else
scram p CMSSW CMSSW_10_2_16_patch1
fi
cd CMSSW_10_2_16_patch1/src
eval `scram runtime -sh`

export X509_USER_PROXY=$HOME/private/personal/voms_proxy.cert
mkdir -p Configuration/GenProduction/python
cp $fragmentDir/pythiaFragments/$fragment Configuration/GenProduction/python/EXO-RunIIAutumn18wmLHEGS-heavyNeutrino-fragment.py

sed -i "s!GRIDPACK!${gridpackPath}!g" Configuration/GenProduction/python/EXO-RunIIAutumn18wmLHEGS-heavyNeutrino-fragment.py

[ -s Configuration/GenProduction/python/EXO-RunIIAutumn18wmLHEGS-heavyNeutrino-fragment.py ] || exit $?;

scram b
cd ../../
cmsDriver.py Configuration/GenProduction/python/EXO-RunIIAutumn18wmLHEGS-heavyNeutrino-fragment.py --fileout file:EXO-RunIIAutumn18wmLHEGS-heavyNeutrino.root --mc --eventcontent RAWSIM,LHE --datatier GEN-SIM,LHE --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --step LHE,GEN,SIM --geometry DB:Extended --era Run2_2018 --python_filename EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py --no_exec -n $events || exit $? ;

echo "process.RandomNumberGeneratorService.generator.initialSeed = $productionNumber" >> EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
echo "process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = $productionNumber" >> EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
sed -i "s/process.source = cms.Source(\"EmptySource\")/process.source = cms.Source(\"EmptySource\",firstRun = cms.untracked.uint32(${productionNumber}))/g" EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_rt.xml EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py || exit $? ; 

sleep 1m




#
# DIGI-RECO + AOD
#
if [ -r CMSSW_10_2_5/src ] ; then 
 echo release CMSSW_10_2_5 already exists
else
scram p CMSSW CMSSW_10_2_5
fi
cd CMSSW_10_2_5/src
eval `scram runtime -sh`

scram b
cd ../../

# Get new proxy to access pileup
/user/$USER/production/proxyExpect.sh
cmsDriver.py step1 --filein file:EXO-RunIIAutumn18wmLHEGS-heavyNeutrino.root --fileout file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 102X_upgrade2018_realistic_v15 --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 --nThreads 4 --procModifiers premix_stage2 --datamix PreMix --era Run2_2018 --python_filename EXO-RunIIAutumn18DR80Premix-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
#because the above command suddenly stopped working on cream02, copy the default one
cp /user/$USER/production/EXO-RunIIAutumn18DR80Premix-heavyNeutrino_1_cfg.py .
cmsRun -e -j EXO-RunIIAutumn18DR80Premix-heavyNeutrino_rt.xml EXO-RunIIAutumn18DR80Premix-heavyNeutrino_1_cfg.py || exit $? ; 
cmsDriver.py step2 --filein file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino_step1.root --fileout file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 102X_upgrade2018_realistic_v15 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --nThreads 4 --era Run2_2018 --python_filename EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_cfg.py --no_exec --procModifiers premix_stage2 --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ; 
cmsRun -e -j EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_rt.xml EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_cfg.py || exit $? ; 

sleep 1m



#
# miniAOD
#
cd CMSSW_10_2_5/src
eval `scram runtime -sh`

scram b
cd ../../
cmsDriver.py step1 --filein file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino.root --fileout file:EXO-RunIIAutumn18MiniAODv2-heavyNeutrino.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 102X_upgrade2018_realistic_v15 --step PAT --nThreads 4 --geometry DB:Extended --era Run2_2018 --python_filename EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ; 
sed -i "/# Additional output definition/a process.MINIAODSIMoutput.outputCommands.append('keep recoTrack*_displaced*Muons__RECO')" EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_rt.xml EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py || exit $? ; 


# In order to get a new proxy
/user/$USER/production/proxyExpect.sh

gfal-mkdir -p -vvv srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Autumn18/$promptOrDisplaced/$shortName
gfal-copy -f -vvv file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber$spec/EXO-RunIIAutumn18MiniAODv2-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Autumn18/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root

gfal-mkdir -p srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Autumn18/$promptOrDisplaced/$shortName
gfal-copy -f file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber$spec/EXO-RunIIAutumn18DR80Premix-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Autumn18/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root


# clean up
cd ..
rm -r /user/$USER/production/${gridpack}_${promptOrDisplaced}_Autumn18/$productionNumber$spec
