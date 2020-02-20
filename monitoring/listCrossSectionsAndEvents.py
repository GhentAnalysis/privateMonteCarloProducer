#! /usr/bin/env python3
import os, subprocess, glob, time
from multiprocessing.pool import ThreadPool
os.chdir(os.path.dirname(__file__))


start = time.time()
maxTime = 3600*3        # Keep the time this script is running limited


def system(command):
  try:
    return subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT).decode()
  except subprocess.CalledProcessError as e:
    print(e.output)
    return 'error'

# The release does not matter too much as long as it can read the miniAOD files, but might need to be updated in the future when moving to new production eras
def setupCMSSW():
  arch='slc6_amd64_gcc700'
  release='CMSSW_10_2_20'
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
    with open(filename) as f: return {l.split()[0] : l for l in f if 'pnfs' in l}
  except:
    return {}

system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/crossSectionsAndEvents.txt -O crossSectionsAndEventsOnGit.txt')
system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/eventCounters.txt -O eventCountersOnGit.txt')
currentLinesGit = loadExisting('crossSectionsAndEventsOnGit.txt')
currentLines    = loadExisting('crossSectionsAndEvents.txt')


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
  output = system('%s;cmsRun xsecAnalyzer.py inputDir=%s' % (setupCMSSW(), directory))
  for line in output.split('\n'):
    if 'After filter: final cross section = ' in line:
      return line.split('= ')[-1].rstrip()
  else:
    return -1

# Store the number of events per file
eventCounters = loadExisting('eventCounters.txt')
eventCounters.update(loadExisting('eventCountersOnGit.txt'))
newEventCounters = {}
def eventsPerFile(filename):
  if filename in eventCounters:
    return eventCounters[filename].split()[-1]
  output = system('%s;edmFileUtil %s | grep events' % (setupCMSSW(), filename.replace('/pnfs/iihe/cms','')))
  try:
    events = int(str(output).split('events')[0].split()[-1])
    newEventCounters[filename] = '%-180s %8s\n' % (filename, events)
    return events
  except:
    return None

# If the number of files is updated, recalculate the number of events
def getEvents(directory):
  files = glob.glob(os.path.join(directory, '*.root'))
  existingLine = getExistingLine(directory)
  if existingLine:
    if existingLine.count('files')==1 and int(existingLine.split('files')[0].split()[-1])==len(files) and not '?' in existingLine:
      return '%s files' % len(files), '%s events' % existingLine.split()[-2]
  events = []
  for f in files:
    if (time.time() - start) > maxTime: events += [None]
    else:                               events += [eventsPerFile(f)]
  try:    events = sum([int(e) for e in events])
  except: events = '?'
  return '%s files' % len(files), '%s events' % events

def getLine(directory):
  return '%-170s %30s %15s %15s\n' % ((directory, getCrossSection(directory)) + getEvents(directory))

# Rewrite the file and calculate the x-sec for the new ones
with open('crossSectionsAndEvents.txt',"w") as f:
  for era in ['Fall17', 'Moriond17_aug2018_miniAODv3', 'Autumn18', 'Moriond17_aug2018']:
    for type in ['prompt', 'displaced']:
      f.write('%s %s\n\n' % (era, type))
      pool = ThreadPool(processes=16)
      directories = glob.glob('/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/' + era + '/' + type + '/*')
      linesToWrite = pool.map(getLine, directories) 
      pool.close()
      pool.join()
      for line in sorted(linesToWrite): f.write(line)
      f.write('\n')

eventCounters.update(newEventCounters)
with open('eventCounters.txt', 'w') as f:
  for line in sorted(eventCounters.values()):
    f.write(line)

system('rm *OnGit.txt')
system('git add crossSectionsAndEvents.txt;git add eventCounters.txt;git commit -m"Update of cross sections and events"') # make sure this are separate commits (the push you have to do yourself though)
