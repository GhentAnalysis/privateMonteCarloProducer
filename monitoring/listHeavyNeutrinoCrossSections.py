#! /usr/bin/env python
#
# TODO:
#  - Check-out a CMSSW release if not yet available yet
#  - Make it possible to keep track of other user's also

import os, time, subprocess, sys, glob

def system(command):
  return subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)


try:
  with open('heavyNeutrinoCrossSections.txt') as f: currentLines = [l for l in f]
  os.system('rm heavyNeutrinoCrossSections.txt')
except:
  currentLines = []

with open('heavyNeutrinoCrossSections.txt',"w") as f:
  for era in ['Fall17', 'Moriond17_aug2018', 'Autumn18']:
    for type in ['prompt', 'displaced']:
      f.write((era if era!='' else 'old samples')+ ' ' + type + '\n')
      f.write('\n')
      for dir in sorted(glob.glob(os.path.expandvars('/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/' + era + '/' + type + '/*'))):
        for l in set(currentLines):
          try:
            if dir in l and l.count('pb')==1:  # if the line is already present (and correctly includes exactly one cross section, otherwise some formatting error might have occured)
              xsec = ' '.join(l.split()[1:])
              f.write('%-180s %-50s\n' % (dir, xsec))
              break
          except:
            pass
        else:
          try:
            output = system('./getCrossSection.py ' + dir)
            f.write('%-180s %-50s\n' % (dir, output.rstrip()))
          except:
            pass
      f.write('\n')
