#! /usr/bin/env python3
import os, sys, subprocess, glob, time
from multiprocessing.pool import ThreadPool
#os.chdir(os.path.dirname(__file__))

start = time.time()
maxTime = 3600*3        # Keep the time this script is running limited

def system(command):
  try:
    return subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT).decode()
  except subprocess.CalledProcessError as e:
    print(e.output)
    return 'error'

def getPhysicalFileNames(datasetname):
  output = system('%s;dasgoclient -query="file dataset=%s"' % (setupCMSSW(), datasetname))
  filenames = [('root://xrootd-cms.infn.it/' + line) for line in output.split('\n')]
  return filenames

# The release does not matter too much as long as it can read the miniAOD files, but might need to be updated in the future when moving to new production eras
def setupCMSSW():
  #arch='slc6_amd64_gcc700'
  arch='slc7_amd64_gcc820'
  release='CMSSW_10_6_27'
  setupCommand  = 'export SCRAM_ARCH=' + arch + ';'
  setupCommand += 'source /cvmfs/cms.cern.ch/cmsset_default.sh;'
  if not os.path.exists(release):
    setupCommand += '/cvmfs/cms.cern.ch/common/scram project CMSSW ' + release + ';'
  setupCommand += 'cd ' + release + '/src;'
  setupCommand += 'eval `/cvmfs/cms.cern.ch/common/scram runtime -sh`;'
  setupCommand += 'cd ../../'
  return setupCommand

# See what is already available and load it, to avoid this script runs forever to do things which are already done
def loadExisting(filename):
  try: 
    with open(filename) as f: return {l.split()[0] : l for l in f if 'HeavyNeutrino' in l}
  except:
    return {}

system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/crossSectionsAndEvents.txt -O crossSectionsAndEventsOnGit.txt')
system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/eventCounters.txt.xz -O eventCountersOnGit.txt.xz')
currentLinesGit = loadExisting('crossSectionsAndEventsOnGit_official.txt')
currentLines    = loadExisting('crossSectionsAndEvents_bvermass.txt')

def getExistingLine(directory):
  existingLine = None
  if directory in currentLines and 'files' in currentLines[directory]:
    existingLine = currentLines[directory]
  if directory in currentLinesGit and 'files' in currentLinesGit[directory]:
    if not existingLine or int(currentLinesGit[directory].split('files')[0].split()[-1]) > int(existingLine.split('files')[0].split()[-1]):
      return currentLinesGit[directory]
  return existingLine


# If the cross section is not known yet, calculate it
def getCrossSection(directory):
  existingLine = getExistingLine(directory)
  if existingLine:
    splittedLine = existingLine.split()
    if splittedLine.count('pb')==1:  # if the line is already present (and correctly includes exactly one cross section, otherwise some formatting error might have occured)
      return '%s +- %s pb' % (splittedLine[1], splittedLine[3])
  if (time.time() - start) > maxTime:
    return -1
  print('getting xsec for: {}'.format(directory))
  output = system('%s;cmsRun xsecAnalyzer.py inputDir=%s' % (setupCMSSW(), directory))
  for line in output.split('\n'):
    if 'After filter: final cross section = ' in line:
      return line.split('= ')[-1].rstrip()
  else:
    return -1

# Store the number of events per file
system('unxz eventCounters.txt.xz;unxz eventCountersOnGit.txt.xz')
eventCounters = loadExisting('eventCounters_official.txt')
#eventCounters.update(loadExisting('eventCountersOnGit.txt'))
newEventCounters = {}
def eventsPerFile(filename):
  if filename in eventCounters:
    return eventCounters[filename].split()[-1]
  output = system('edmFileUtil %s | grep events' % (filename.replace('/pnfs/iihe/cms','')))
  try:
    events = int(str(output).split('events')[0].split()[-1])
    newEventCounters[filename] = '%-180s %8s\n' % (filename.replace('root://xrootd-cms.infn.it/',''), events)
    return events
  except:
    return None

#all privately produced files are just 1000 events and eventsPerFile takes a long time. Be careful if anyone changed number of events per file, should not use this in that case
def eventsPerFileQuickAndDirty():
    return 1000

# If the number of files is updated, recalculate the number of events
def getEvents(directory):
  if 'pnfs' in directory:
    files = glob.glob(os.path.join(directory, '*.root'))
    existingLine = getExistingLine(directory)
    if existingLine:
      if existingLine.count('files')==1 and int(existingLine.split('files')[0].split()[-1])==len(files) and not '?' in existingLine:
        return '%s files' % len(files), '%s events' % existingLine.split()[-2]
    events = []
    for f in files:
      if (time.time() - start) > maxTime: events += [None]
      else:                               events += [eventsPerFileQuickAndDirty()]
      #else:                               events += [eventsPerFile(f)]
    try:    events = sum([int(e) for e in events])
    except: events = '?'
    return '%s files' % len(files), '%s events' % events
  else:
    print('getting events for: {}'.format(directory))
    output = system('dasgoclient -query="dataset='+directory+' | grep dataset.nevents,dataset.nfiles"').split('\n')
    output = [line.strip().split() for line in output if line and not '[' in line][0]
    output = [line for line in output if line.isalnum()]
    if len(output) == 2:
        events = output[0]
        nfiles = output[1]
    else:
        print('WRONG dasgoclient output!')
        events = -1
        nfiles = -1
    print('events: {}, nfiles: {}'.format(events, nfiles))
    return '%s files' % nfiles, '%s events' % events

def getLine(directory):
  return '%-170s %30s %15s %15s\n' % ((directory, getCrossSection(directory)) + getEvents(directory))


done_files = [line.split()[0] for line in open('crossSectionsAndEvents_bvermass.txt') if line and line.startswith('/HeavyNeutrino')]

# Rewrite the file and calculate the x-sec for the new ones
with open('crossSectionsAndEvents_bvermass.txt',"a") as f:
  #for era in ['Fall17', 'Moriond17_aug2018_miniAODv3', 'Autumn18', 'Moriond17_aug2018']:
  #  for type in ['prompt', 'displaced']:
  #    f.write('%s %s\n\n' % (era, type))
  #    pool = ThreadPool(processes=16)
  #    directories = glob.glob('/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/' + era + '/' + type + '/*')
  #    linesToWrite = pool.map(getLine, directories) 
  #    pool.close()
  #    pool.join()
  #    for line in sorted(linesToWrite): f.write(line)
  #    f.write('\n')
  #f.write('Official Production\n\n')
  datasets = [dataset for dataset in open(sys.argv[1])]
  datasets = [dataset.split(':')[-1].strip('\n') for dataset in datasets if dataset and not dataset.startswith('#')]
  datasets = [dataset for dataset in datasets if not dataset in done_files]
  print(datasets)
  for dataset in datasets:
      f.write(getLine(dataset))
  f.write('\n')

eventCounters.update(newEventCounters)
with open('eventCounters_official.txt', 'w') as f:
  for line in sorted(eventCounters.values()):
    f.write(line)

#system('rm *OnGit.txt')
#system('xz -f eventCounters.txt')
#system('git add crossSectionsAndEvents.txt;git add eventCounters.txt.xz;git commit -m"Update of cross sections and events"') # make sure this are separate commits (the push you have to do yourself though)
