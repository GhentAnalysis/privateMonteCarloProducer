# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIAutumn18MiniAOD&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc700
cmsswRelease CMSSW_10_2_5

cmsDriver.py step1 --filein file:heavyNeutrino.root --fileout file:heavyNeutrinoMiniAOD.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 102X_upgrade2018_realistic_v15 --step PAT --nThreads 4 --geometry DB:Extended --era Run2_2018 --python_filename EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
sed -i "/# Additional output definition/a process.MINIAODSIMoutput.outputCommands.append('keep recoTrack*_displaced*Muons__RECO')" EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_rt.xml EXO-RunIIAutumn18MiniAODv2-heavyNeutrino_1_cfg.py || exit $? ; 
