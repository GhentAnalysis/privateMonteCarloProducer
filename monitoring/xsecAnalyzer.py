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
  import glob
  for f in glob.glob(options.inputDir + '/*.root')[:30]: # limit to 30 files (typically 30000 events)
    options.inputFiles.append('dcap://maite.iihe.ac.be' + f)

process.source = cms.Source(
    "PoolSource",
    fileNames  = cms.untracked.vstring(options.inputFiles),
    duplicateCheckMode = cms.untracked.string('noDuplicateCheck')
)

process.dummy        = cms.EDAnalyzer("GenXSecAnalyzer")
process.xsecAnalyzer = cms.Path(process.dummy)
process.schedule     = cms.Schedule(process.xsecAnalyzer)
