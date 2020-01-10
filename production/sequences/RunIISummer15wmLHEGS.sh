# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIISummer15wmLHEGS&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc481
cmsswRelease CMSSW_7_1_45_patch3 prepareFragment

cmsDriver.py Configuration/GenProduction/python/heavyNeutrino-fragment.py --fileout file:EXO-RunIISummer15wmLHEGS-heavyNeutrino.root --mc --eventcontent RAWSIM,LHE --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM,LHE --conditions MCRUN2_71_V1::All --beamspot Realistic50ns13TeVCollision --step LHE,GEN,SIM --magField 38T_PostLS1 --python_filename EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py --no_exec -n $events || exit $? ;

# Putting in the random seeds
echo "process.RandomNumberGeneratorService.generator.initialSeed = $productionNumber" >> EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
echo "process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = $productionNumber" >> EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
sed -i "s/process.source = cms.Source(\"EmptySource\")/process.source = cms.Source(\"EmptySource\",firstRun = cms.untracked.uint32(${productionNumber}))/g" EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIISummer15wmLHEGS-heavyNeutrino_rt.xml EXO-RunIISummer15wmLHEGS-heavyNeutrino_1_cfg.py || exit $? ;
