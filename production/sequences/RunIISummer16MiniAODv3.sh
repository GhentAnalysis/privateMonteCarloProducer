# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIISummer16MiniAODv3&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc630
cmsswRelease CMSSW_9_4_9

cmsDriver.py step1 --filein file:EXO-RunIISummer16DR80Premix-heavyNeutrino.root --fileout file:EXO-RunIISummer16MiniAODv3-heavyNeutrino.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 94X_mcRun2_asymptotic_v3 --step PAT --nThreads 8 --era Run2_2016,run2_miniAOD_80XLegacy --python_filename EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;

# Keep additional output
sed -i "/# Additional output definition/a process.MINIAODSIMoutput.outputCommands.append('keep recoTrack*_displaced*Muons__RECO')" EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py
cmsRun -e -j EXO-RunIISummer16MiniAODv3-heavyNeutrino_rt.xml EXO-RunIISummer16MiniAODv3-heavyNeutrino_1_cfg.py || exit $? ; 


