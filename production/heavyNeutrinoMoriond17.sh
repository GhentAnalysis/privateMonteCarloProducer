#PBS -l nodes=1:ppn=1
#!/bin/bash

log(){
  python -c "import logging;logging.basicConfig(level = logging.INFO);logging.info('$1')"
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

if [ -d /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber/CMSSW_7_1_22 ]; then
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


#
# GEN-SIM
#
source $VO_CMS_SW_DIR/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481
if [ -r CMSSW_7_1_22/src ] ; then 
 echo release CMSSW_7_1_22 already exists
else
scram p CMSSW CMSSW_7_1_22
fi
cd CMSSW_7_1_22/src
eval `scram runtime -sh`

export X509_USER_PROXY=$HOME/private/personal/voms_proxy.cert
mkdir -p Configuration/GenProduction/python
cp $fragmentDir/pythiaFragments/$fragment Configuration/GenProduction/python/EXO-RunIISummer15wmLHEGS-heavyNeutrino-fragment.py

sed -i "s!GRIDPACK!${gridpackPath}!g" Configuration/GenProduction/python/EXO-RunIISummer15wmLHEGS-heavyNeutrino-fragment.py

[ -s Configuration/GenProduction/python/EXO-RunIISummer15wmLHEGS-heavyNeutrino-fragment.py ] || exit $?;

scram b
cd ../../
cmsDriver.py Configuration/GenProduction/python/EXO-RunIISummer15wmLHEGS-heavyNeutrino-fragment.py --fileout file:EXO-RunIISummer15wmLHEGS-heavyNeutrino.root --mc --eventcontent RAWSIM,LHE --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM,LHE --conditions MCRUN2_71_V1::All --beamspot Realistic50ns13TeVCollision --step LHE,GEN,SIM --magField 38T_PostLS1 --python_filename EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py --no_exec -n $events || exit $? ;

echo "process.RandomNumberGeneratorService.generator.initialSeed = $productionNumber" >> EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
echo "process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = $productionNumber" >> EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
sed -i "s/process.source = cms.Source(\"EmptySource\")/process.source = cms.Source(\"EmptySource\",firstRun = cms.untracked.uint32(${productionNumber}))/g" EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIISummer15wmLHEGS-heavyNeutrino_rt.xml EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py || exit $? ; 

sleep 1m




#
# DIGI-RECO + AOD
#
if [ -r CMSSW_8_0_21/src ] ; then
 echo release CMSSW_8_0_21 already exists
else
scram p CMSSW CMSSW_8_0_21
fi
cd CMSSW_8_0_21/src
eval `scram runtime -sh`

scram b
cd ../../

# Get new proxy to access pileup
#/user/$USER/production/proxyExpect.sh
#cmsDriver.py step1 --filein file:EXO-RunIISummer15wmLHEGS-heavyNeutrino.root --fileout file:EXO-RunIISummer16DR80Premix-heavyNeutrino_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISpring15PrePremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v2-v2/GEN-SIM-DIGI-RAW" --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:@frozen2016 --nThreads 4 --datamix PreMix --era Run2_2016 --python_filename EXO-RunIISummer16DR80Premix-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
#because the above command suddenly stopped working on cream02, copy the default one
cp /user/$USER/production/EXO-RunIISummer16DR80Premix-heavyNeutrino_1_cfg.py .
cmsRun -e -j EXO-RunIISummer16DR80Premix-heavyNeutrino_rt.xml EXO-RunIISummer16DR80Premix-heavyNeutrino_1_cfg.py || exit $? ; 
cmsDriver.py step2 --filein file:EXO-RunIISummer16DR80Premix-heavyNeutrino_step1.root --fileout file:EXO-RunIISummer16DR80Premix-heavyNeutrino.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step RAW2DIGI,RECO,EI --nThreads 4 --era Run2_2016 --python_filename EXO-RunIISummer16DR80Premix-heavyNeutrino_2_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ; 
cmsRun -e -j EXO-RunIISummer16DR80Premix-heavyNeutrino_2_rt.xml EXO-RunIISummer16DR80Premix-heavyNeutrino_2_cfg.py || exit $? ; 

sleep 1m



#
# miniAODv3
#
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_4_9/src ] ; then 
  echo release CMSSW_9_4_9 already exists
else
  scram p CMSSW CMSSW_9_4_9
fi
cd CMSSW_9_4_9/src
eval `scram runtime -sh`

scram b
cd ../../
cmsDriver.py step1 --filein file:EXO-RunIISummer16DR80Premix-heavyNeutrino.root --fileout file:EXO-RunIISummer16MiniAODv3-heavyNeutrino.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 94X_mcRun2_asymptotic_v3 --step PAT --nThreads 8 --era Run2_2016,run2_miniAOD_80XLegacy --python_filename EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
sed -i "/# Additional output definition/a process.MINIAODSIMoutput.outputCommands.append('keep recoTrack*_displaced*Muons__RECO')" EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIISummer16MiniAODv3-heavyNeutrino_rt.xml EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py || exit $? ; 



# In order to get a new proxy
/user/$USER/production/proxyExpect.sh

gfal-mkdir -p -vvv srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/$promptOrDisplaced/$shortName
gfal-copy -f -vvv file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec/EXO-RunIISummer16MiniAODv3-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root

gfal-mkdir -p srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName
gfal-copy -f file:///user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec/EXO-RunIISummer16DR80Premix-heavyNeutrino.root srm://maite.iihe.ac.be:8443/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoAOD/Moriond17_aug2018/$promptOrDisplaced/$shortName/heavyNeutrino_$productionNumber.root


# clean up
cd ..
rm -r /user/$USER/production/${gridpack}_${promptOrDisplaced}_Moriond17_aug2018/$productionNumber$spec
