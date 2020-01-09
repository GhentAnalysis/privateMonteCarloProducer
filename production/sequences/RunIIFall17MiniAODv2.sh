# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIFall17MiniAODv2&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc481
cmsswRelease CMSSW_9_4_7

cmsDriver.py step1 --filein file:EXO-RunIIFall17DR80Premix-heavyNeutrino.root --fileout file:EXO-RunIIFall17MiniAODv2-heavyNeutrino.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 94X_mc2017_realistic_v14 --step PAT --nThreads 4 --scenario pp --era Run2_2017,run2_miniAOD_94XFall17 --python_filename EXO-RunIIFall17MiniAODv2-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ; 
sed -i "/# Additional output definition/a process.MINIAODSIMoutput.outputCommands.append('keep recoTrack*_displaced*Muons__RECO')" EXO-RunIIFall17MiniAODv2-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIIFall17MiniAODv2-heavyNeutrino_rt.xml EXO-RunIIFall17MiniAODv2-heavyNeutrino_1_cfg.py || exit $? ; 


