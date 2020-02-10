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
  setupCommand = 'export SCRAM_ARCH=' + arch + ';'
  if not os.path.exists(release):
    setupCommand += 'source $VO_CMS_SW_DIR/cmsset_default.sh;'
    setupCommand += '/cvmfs/cms.cern.ch/common/scram project CMSSW ' + release + ';'
  setupCommand += 'cd ' + release + '/src;'
  setupCommand += 'eval `/cvmfs/cms.cern.ch/common/scram runtime -sh`;'
  setupCommand += 'cd ../../'
  return setupCommand

# See what is already available and load it, to avoid this script runs forever to do things which are already done
def loadExisting(filename):
  try: 
    with open(filename) as f: return set(l for l in f)
  except:
    return set()

system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/crossSectionsAndEvents.txt -O crossSectionsAndEventsOnGit.txt')
system('wget https://raw.githubusercontent.com/GhentAnalysis/privateMonteCarloProducer/master/monitoring/eventCounters.txt -O eventCountersOnGit.txt')
currentLines = loadExisting('crossSectionsAndEvents.txt')
currentLines.update(loadExisting('crossSectionsAndEventsOnGit.txt'))

# If the cross section is not known yet, calculate it
def getCrossSection(directory):
  for l in currentLines:
    try:
      if directory in l.split() and l.count('pb')==1:  # if the line is already present (and correctly includes exactly one cross section, otherwise some formatting error might have occured)
        return '%s +- %s pb' % (l.split()[1], l.split()[3])
    except:
      pass
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
newEventCounters = set()
def eventsPerFile(filename):
  for line in eventCounters:
    if filename in eventCounters:
      return  line.split()[-1]
  output = system('%s;edmFileUtil %s | grep events' % (setupCMSSW(), filename.replace('/pnfs/iihe/cms','')))
  try:
    events = int(str(output).split('events')[0].split()[-1])
    newEventCounters.update('%-180s %8s\n' % (filename, events))
    return events
  except:
    return -99999999

# If the number of files is updated, recalculate the number of events
def getEvents(directory):
  files = glob.glob(os.path.join(directory, '*.root'))
  for l in currentLines:
    try:
      if directory in l.split() and l.count('files')==1 and int(l.split()[5])==len(files) and not '?' in l.split():
        return '%s files' % len(files), '%s events' % l.split()[-2]
    except:
      pass
  events = 0
  for f in files:
    if (time.time() - start) > maxTime:
      return '%s files' % len(files), '? events'
    events += eventsPerFile(f)
  return '%s files' % len(files), '%s events' % (events if events > 0 else '?')

def getLine(directory):
  return '%-170s %30s %15s %15s\n' % ((directory, getCrossSection(directory)) + getEvents(directory))

# Rewrite the file and calculate the x-sec for the new ones
with open('crossSectionsAndEvents.txt',"w") as f:
  for era in ['Fall17', 'Moriond17_aug2018_miniAODv3', 'Autumn18']:
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
  for line in eventCounters:
    f.write(line)

system('rm *OnGit.txt')
system('git add crossSectionsAndEvents.txt;git add eventCounters.txt;git commit -m"Update of cross sections and events"') # make sure this are separate commits (the push you have to do yourself though)
