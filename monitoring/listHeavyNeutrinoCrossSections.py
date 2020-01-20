#! /usr/bin/env python3
import os, time, subprocess, sys, glob
os.chdir(os.path.dirname(__file__))

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
    setupCommand += 'scramv1 project CMSSW ' + release + ';'
  setupCommand += 'cd ' + release + '/src;'
  setupCommand += 'eval `scramv1 runtime -sh`;'
  setupCommand += 'cd ../../'
  return setupCommand

# See what is already available and load it, to avoid this script runs forever
try:
  with open('heavyNeutrinoCrossSections.txt') as f: currentLines = [l for l in f]
  os.system('rm heavyNeutrinoCrossSections.txt')
except:
  currentLines = []

# Rewrite the file and calculate the x-sec for the new ones
maxNew, new = 100, 0
with open('heavyNeutrinoCrossSections.txt',"w") as f:
  for era in ['Fall17', 'Moriond17_aug2018', 'Autumn18']:
    for type in ['prompt', 'displaced']:
      f.write((era if era!='' else 'old samples')+ ' ' + type + '\n')
      f.write('\n')
      for dir in sorted(glob.glob('/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/' + era + '/' + type + '/*')):
        for l in set(currentLines):
          try:
            if dir in l.split() and l.count('pb')==1:  # if the line is already present (and correctly includes exactly one cross section, otherwise some formatting error might have occured)
              xsec = ' '.join(l.split()[1:])
              f.write('%-180s %-50s\n' % (dir, xsec))
              break
          except:
            pass
        else:
          if new > maxNew: continue
          new += 1
          output = system('%s;cmsRun xsecAnalyzer.py inputDir=%s' % (setupCMSSW(), dir))
          xsec = -1
          for line in output.split('\n'):
            if 'After filter: final cross section = ' in line:
              xsec = line.split('= ')[-1].rstrip()
          f.write('%-180s %-50s\n' % (dir, xsec))
      f.write('\n')
system('git add heavyNeutrinoCrossSections.txt;git commit -m"Update of gridpack cross sections"') # make sure this are separate commits (the push you have to do yourself though)
