#!/usr/bin/env python

#
# Creates both the cards and the prompt/displaced gridpacks, and moves them to some directory
#
import os, argparse
argParser = argparse.ArgumentParser(description = "Argument parser")
argParser.add_argument('--channel',      action='store',      default='trilepton',          help='Specify trilepton or lljj channel', choices=['trilepton', 'lljj'])
argParser.add_argument('--mass',         action='store',      default='1',                  help='Specify mass point')
argParser.add_argument('--coupling',     action='store',      default='predefined',         help='Specify mass coupling [default uses predefined ones]')
argParser.add_argument('--flavor',       action='store',      default='e',                  help='Select flavor for HNL coupling', choices=['e', 'mu', 'tau', '2l', '3l'])
argParser.add_argument('--hnlType',      action='store',      default='majorana',           help='Select HNL type', choices=['majorana', 'dirac', 'dirac_cc'])
argParser.add_argument('--queue',        action='store',      default='cream02',            help='Select cluster or local resources', choices=['cream02', 'local'])
argParser.add_argument('--pre2017',      action='store_true', default=False,                help='Use pre2017 settings')
argParser.add_argument('--onlyPrompt',   action='store_true', default=False,                help='Only generate a prompt gridpack')
args = argParser.parse_args()


workDir            = os.path.join(os.getcwd(), 'genproductions/bin/MadGraph5_aMCatNLO')
cardsPath          = './cards/production/2017/13TeV/exo_heavyNeutrino_LO' # relative with workDir
promptGridpacks    = os.path.join(os.getcwd(), 'prompt')
displacedGridpacks = os.path.join(os.getcwd(), 'displaced')

def intOrFloat(str):
  try:    return int(str)
  except: return float(str)

#
# Predefined points, gridpacks will be created for each coupling in couplings
#
if args.coupling=='predefined':
  if args.flavor=='2l': # new points
    if   intOrFloat(args.mass) == 10: v2s = [1.5e-8, 3.3e-7]
    elif intOrFloat(args.mass) == 8:  v2s = [6e-8, 1.2e-6, 5.2e-6]
    elif intOrFloat(args.mass) == 6:  v2s = [3.5e-7, 2.3e-6]
    elif intOrFloat(args.mass) == 5:  v2s = [1e-6, 3e-6]
    elif intOrFloat(args.mass) == 1:  v2s = [0.02, 0.004]
  elif args.flavor!='tau': # new points
    if   intOrFloat(args.mass) == 14: v2s = [1e-6, 3e-7]
    elif intOrFloat(args.mass) == 12: v2s = [1e-6, 4e-7]
    elif intOrFloat(args.mass) == 10: v2s = [2e-7, 6e-8]
    elif intOrFloat(args.mass) == 8:  v2s = [4e-7, 2e-7]
  elif 'dirac' in args.hnlType and args.flavor=='tau':
    if intOrFloat(args.mass) == 1:    vs  = [4.66e-1]
    elif intOrFloat(args.mass) == 2:  vs  = [5.00e-2]
    elif intOrFloat(args.mass) == 3:  vs  = [1.35e-2]
    elif intOrFloat(args.mass) == 4:  vs  = [9.28e-3]
    elif intOrFloat(args.mass) == 5:  vs  = [9.04e-3]
    elif intOrFloat(args.mass) == 10: vs  = [1.52e-3]
  elif args.flavor=='tau':
    if intOrFloat(args.mass) == 1:    vs  = [3.29e-1]
    elif intOrFloat(args.mass) == 2:  vs  = [3.53e-2]
    elif intOrFloat(args.mass) == 3:  vs  = [9.57e-3]
    elif intOrFloat(args.mass) == 4:  vs  = [6.56e-3]
    elif intOrFloat(args.mass) == 5:  vs  = [6.39e-3]
    elif intOrFloat(args.mass) == 10: vs  = [1.08e-3]
  try:
    print vs
    couplings = vs
  except:
    print v2s
    import math
    couplings = [math.sqrt(v2) for v2 in v2s]
else:
  couplings = [args.coupling]



#
# Helper function
#
import fnmatch
def findGridpack(dir, baseName):
  for file in os.listdir(dir):
    if fnmatch.fnmatch(file, baseName + '*.tar.xz'):
      return file
  return None


#
# Create gridpack function for coupling (other parameters directly taken from the args)
#
import shutil, time, sys
def createGridpack(coupling):
  # First create the cards for chosen settings
  sys.path.append(cardsPath)
  from makeHeavyNeutrinoCards import makeHeavyNeutrinoCards
  os.chdir(cardsPath)
  baseName = makeHeavyNeutrinoCards(intOrFloat(args.mass), float(coupling), args.flavor, args.pre2017, args.channel, noZ=False, dirac=('dirac' in args.hnlType), cc=('cc' in args.hnlType))
  os.chdir(workDir)

  # Check if prompt gridpack already exists
  gridpack = findGridpack(promptGridpacks, baseName)
  if gridpack:
    print gridpack + ' already exist, skipping'
    return None
  elif os.path.exists(baseName):
    print 'Working directory genproductions/bin/MadGraph5_aMCatNLO/%s already exists, please check! (skipping)' % baseName
    return None
  else:
    print 'Creating ' + baseName

  # Check if gridpack already exists locally (i.e. maybe only the post-processing still needs to be done)
  gridpack = findGridpack('.', baseName)
  if gridpack: return gridpack

  # Create the gridpack with the standard CMSSW script
  os.system('CMSSW_BASE=;./gridpack_generation.sh ' + baseName + ' ' + os.path.join(cardsPath, baseName) + ' ' + args.queue)
  time.sleep(10)
  gridpack = findGridpack('.', baseName)

  # Clean-up and return
  if gridpack: shutil.rmtree(gridpack.split('_slc')[0])
  return gridpack


#
# Check the log files for problems
#
def logFilesOk(gridpack):
  try:
    with open(gridpack.split('LO')[0] + 'LO.log') as f:
      for line in f:
        if '+' in line: continue
        if 'tar: Error is not recoverable: exiting now' in line: return False
  except:
    return False
  return True


#
# Make sure gridpack directories exist
#
try:
  os.makedirs(promptGridpacks)
  os.makedirs(displacedGridpacks)
except:
  pass

#
# Loop over the couplings and post-gridpack processing
#
os.chdir(workDir)
for coupling in couplings:
  while True:
    gridpack = createGridpack(coupling)
    if (not gridpack) or logFilesOk(gridpack): break
    if gridpack: shutil.move(gridpack, gridpack + '_problem')
  time.sleep(10)

  if gridpack:
    print gridpack + ' --> fixing for Madspin bug'
    os.system('./fixGridpack.sh ' + gridpack)
    print gridpack + ' --> prompt done'

    if args.onlyPrompt:
      shutil.move(gridpack, os.path.join(promptGridpacks, gridpack))
    else:
      shutil.copyfile(gridpack, os.path.join(promptGridpacks, gridpack))
      print gridpack + ' --> fixing for displaced'
      os.system('./fixGridpackForDisplacedLO.sh ' + gridpack)
      shutil.move(gridpack, os.path.join(displacedGridpacks, gridpack))
      print gridpack + ' --> displaced done'

    try:    os.remove(gridpack.split('LO')[0] + 'LO.log')
    except: pass
