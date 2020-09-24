# Based on https://cms-pdmv.cern.ch/mcm/campaigns?prepid=RunIISummer16DR80Premix&page=0&shown=131135
export SCRAM_ARCH=slc6_amd64_gcc481
cmsswRelease CMSSW_8_0_31

# Get new proxy to access pileup
/user/$USER/production/proxyExpect.sh
cmsDriver.py step1 --filein file:EXO-RunIISummer15wmLHEGS-heavyNeutrino.root --fileout file:EXO-RunIISummer16DR80Premix-heavyNeutrino_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISpring15PrePremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v2-v2/GEN-SIM-DIGI-RAW" --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:@frozen2016 --nThreads 8 --datamix PreMix --era Run2_2016 --python_filename EXO-RunIISummer16DR80Premix-heavyNeutrino_1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
cmsRun -e -j EXO-RunIISummer16DR80Premix-heavyNeutrino_rt.xml EXO-RunIISummer16DR80Premix-heavyNeutrino_1_cfg.py || exit $? ;
rm EXO-RunIISummer15wmLHEGS-heavyNeutrino.root
cmsDriver.py step2 --filein file:EXO-RunIISummer16DR80Premix-heavyNeutrino_step1.root --fileout file:heavyNeutrinoAOD.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step RAW2DIGI,RECO,EI --nThreads 4 --era Run2_2016 --python_filename EXO-RunIISummer16DR80Premix-heavyNeutrino_2_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $events || exit $? ;
cmsRun -e -j EXO-RunIISummer16DR80Premix-heavyNeutrino_2_rt.xml EXO-RunIISummer16DR80Premix-heavyNeutrino_2_cfg.py || exit $? ;
rm EXO-RunIISummer16DR80Premix-heavyNeutrino_step1.root
