# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIFall18wmLHEGS&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc700
cmsswRelease CMSSW_10_2_16_patch1 prepareFragment

cmsDriver.py Configuration/GenProduction/python/heavyNeutrino-fragment.py --fileout file:EXO-RunIIAutumn18wmLHEGS-heavyNeutrino.root --mc --eventcontent RAWSIM,LHE --datatier GEN-SIM,LHE --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --step LHE,GEN,SIM --geometry DB:Extended --era Run2_2018 --python_filename EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py --no_exec -n $events || exit $? ;

echo "process.RandomNumberGeneratorService.generator.initialSeed = $productionNumber" >> EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
echo "process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = $productionNumber" >> EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
sed -i "s/process.source = cms.Source(\"EmptySource\")/process.source = cms.Source(\"EmptySource\",firstRun = cms.untracked.uint32(${productionNumber}))/g" EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_rt.xml EXO-RunIIAutumn18wmLHEGS-heavyNeutrino_1_cfg.py || exit $? ;


