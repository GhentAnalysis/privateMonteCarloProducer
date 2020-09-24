# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIAutumn18DRPremix&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc700
cmsswRelease CMSSW_10_2_5

# Get new proxy to access pileup
/user/$USER/production/proxyExpect.sh
cmsDriver.py step1 --filein file:EXO-RunIIAutumn18wmLHEGS-heavyNeutrino.root --fileout file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 102X_upgrade2018_realistic_v15 --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 --nThreads 4 --procModifiers premix_stage2 --datamix PreMix --era Run2_2018 --python_filename EXO-RunIIAutumn18DR80Premix-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
cmsRun -e -j EXO-RunIIAutumn18DR80Premix-heavyNeutrino_rt.xml EXO-RunIIAutumn18DR80Premix-heavyNeutrino_1_cfg.py || exit $? ;
rm EXO-RunIIAutumn18wmLHEGS-heavyNeutrino.root
cmsDriver.py step2 --filein file:EXO-RunIIAutumn18DR80Premix-heavyNeutrino_step1.root --fileout file:heavyNeutrino.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 102X_upgrade2018_realistic_v15 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --nThreads 4 --era Run2_2018 --python_filename EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_cfg.py --no_exec --procModifiers premix_stage2 --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
cmsRun -e -j EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_rt.xml EXO-RunIIAutumn18DR80Premix-heavyNeutrino_2_cfg.py || exit $? ;
rm EXO-RunIIAutumn18DR80Premix-heavyNeutrino_step1.root
