# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIFall17wmLHEGS&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc481
cmsswRelease CMSSW_9_3_17 prepareFragment

cmsDriver.py Configuration/GenProduction/python/heavyNeutrino-fragment.py --fileout file:EXO-RunIIFall17wmLHEGS-heavyNeutrino.root --mc --eventcontent RAWSIM,LHE --datatier GEN-SIM,LHE --conditions 93X_mc2017_realistic_v3 --beamspot Realistic25ns13TeVEarly2017Collision --step LHE,GEN,SIM --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename EXO-RunIIFall17wmLHEGS-heavyNeutrino_1_cfg.py --no_exec -n $events || exit $? ;

log "process.RandomNumberGeneratorService.generator.initialSeed = $productionNumber" >> EXO-RunIIFall17wmLHEGS-heavyNeutrino_1_cfg.py
log "process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = $productionNumber" >> EXO-RunIIFall17wmLHEGS-heavyNeutrino_1_cfg.py
sed -i "s/process.source = cms.Source(\"EmptySource\")/process.source = cms.Source(\"EmptySource\",firstRun = cms.untracked.uint32(${productionNumber}))/g" EXO-RunIIFall17wmLHEGS-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIFall17wmLHEGS-heavyNeutrino_rt.xml EXO-RunIIFall17wmLHEGS-heavyNeutrino_1_cfg.py || exit $? ;
