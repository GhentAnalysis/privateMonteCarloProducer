# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIIFall17DRPremix&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc481
cmsswRelease CMSSW_9_4_7

# Get new proxy to access pileup
/user/$USER/production/proxyExpect.sh
export X509_USER_PROXY=$HOME/private/personal/voms_proxy.cert
cmsDriver.py step1 --filein file:EXO-RunIIFall17wmLHEGS-heavyNeutrino.root --fileout file:EXO-RunIIFall17DR80Premix-heavyNeutrino_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW" --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 94X_mc2017_realistic_v11 --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:2e34v40 --nThreads 8 --datamix PreMix --era Run2_2017 --python_filename EXO-RunIIFall17DR80Premix-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
cmsRun -e -j EXO-RunIIFall17DR80Premix-heavyNeutrino_rt.xml EXO-RunIIFall17DR80Premix-heavyNeutrino_1_cfg.py || exit $? ; 
cmsDriver.py step2 --filein file:EXO-RunIIFall17DR80Premix-heavyNeutrino_step1.root --fileout file:EXO-RunIIFall17DR80Premix-heavyNeutrino.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 94X_mc2017_realistic_v11 --step RAW2DIGI,RECO,EI --nThreads 8 --era Run2_2017 --python_filename EXO-RunIIFall17DR80Premix-heavyNeutrino_2_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ; 
cmsRun -e -j EXO-RunIIFall17DR80Premix-heavyNeutrino_2_rt.xml EXO-RunIIFall17DR80Premix-heavyNeutrino_2_cfg.py || exit $? ; 


