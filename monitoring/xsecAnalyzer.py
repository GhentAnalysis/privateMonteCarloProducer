import os
import FWCore.ParameterSet.Config as cms
from FWCore.ParameterSet.VarParsing import VarParsing

options = VarParsing('analysis')
options.register("inputDir", None, VarParsing.multiplicity.singleton, VarParsing.varType.string, "inputDir")
options.parseArguments()

process = cms.Process('xsecAnalyzer')

process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'auto:mc', '')
process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(-1)
)

process.MessageLogger.cerr.FwkReport.reportEvery = 10000

if options.inputDir:
  if 'pnfs' in options.inputDir:
    import glob
    for f in glob.glob(options.inputDir + '/*.root')[:30]: # limit to 30 files (typically 30000 events)
      options.inputFiles.append('dcap://maite.iihe.ac.be' + f)
  else:
    os.system('dasgoclient -query="file dataset=' + options.inputDir+'" > xsecfiles.txt')
    with open('xsecfiles.txt','r') as f:
      counter = 0
      for line in f:
        counter += 1
        if counter > 4:
            options.inputFiles.append('root://xrootd-cms.infn.it/' + line)
        if counter == 8:#limit to 4 files (also typically around 30000 events, but large variations due to inconsistent filesize)
            break
    os.system('rm xsecfiles.txt')


process.source = cms.Source(
    "PoolSource",
    fileNames  = cms.untracked.vstring(options.inputFiles),
    duplicateCheckMode = cms.untracked.string('noDuplicateCheck')
)

process.dummy        = cms.EDAnalyzer("GenXSecAnalyzer")
process.xsecAnalyzer = cms.Path(process.dummy)
process.schedule     = cms.Schedule(process.xsecAnalyzer)
