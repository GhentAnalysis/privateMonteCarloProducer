#! /usr/bin/env python3
import os,glob, tarfile
os.chdir(os.path.dirname(__file__))

def getWidth(gridpack):
  width = None

  # Still no decent python3 with lmza support available in CMSSW/T2_BE_IIHE, so we cannot use the lines below
  # with tarfile.open(gridpack, 'r:xz') as tf:
  #   for line in tf.extractfile('process/Cards/param_card.dat' if 'NLO' in gridpack else 'process/madevent/Cards/param_card.dat'):
  #     if 'DECAY' in line and ('9900012' in line or '9990012' in line): 
  #       width = line.split('#')[0].split()[-1]
  #       break

  # Dirty workaround
  if 'NLO' in gridpack:
    tempFile = 'temp_' + gridpack.split('/')[-1].split('_NLO')[0] + '.txt'
    os.system('tar xafO ' + gridpack + ' process/Cards/param_card.dat &> ' + tempFile)
  else:
    tempFile = 'temp_' + gridpack.split('/')[-1].split('_LO')[0] + '.txt'
    os.system('tar xafO ' + gridpack + ' process/madevent/Cards/param_card.dat &> ' + tempFile)

  with open(tempFile) as f:
    for line in f: 
      if 'DECAY' in line and ('9900012' in line or '9990012' in line): 
        width = line.split('#')[0].split()[-1]
        break

  os.system('rm ' + tempFile)
  # End dirty workaround

  try:
    return float(width)
  except:
    print('Something wrong with gridpack %s, width %s' % (gridpack, width))
    return -1


def updateWidths(file, storages):
  try:
    with open(file) as f: currentLines = [l.split() for l in f]
    os.system('rm ' + file)
  except:
    currentLines = []

  with open(file,"w") as f:
    f.write('%-150s %20s %20s' % ('Gridpacks with displaced vertex', 'width', 'ctau (mm)\n'))
    f.write('%-150s %20s %20s' % ('-------------------------------', '-----', '---------\n'))
    for variation, gridpackStorage in storages:
      for gridpack in sorted(glob.glob(gridpackStorage), key = lambda x: x.split('/')[-1]):
        print(gridpack)
        shortName = gridpack.split('/')[-1].split('LO')[0] + 'LO'
        oldSetup  = 'oldSetup' in gridpack
        line      = next((l for l in currentLines if l[0]==shortName), None)
        width     = float(getWidth(gridpack)) if not line else float(line[1])
        ctau      = 6.58211915e-25*299792458000/width
        if ctau < 0.001: # No use for displaced gridpack, remove it and only keep the prompt
          os.system('rm ' +gridpack)
          continue
        else:
          f.write('%-150s %20e %20f %20s\n' % (shortName, width, ctau, (('(' + variation + ')') if variation else '')))

updateWidths('widths.txt', [(None,                     '/user/tomc/public/privateMonteCarloProducer/gridpacks/displaced/*.tar.xz'),
                            ('oldSetup-beforeNov2017', '/pnfs/iihe/cms/store/user/*/gridpacks/oldSetup-beforeNov2017/*isplaced/*.tar.xz'),
                            ('beforeApril2018',        '/pnfs/iihe/cms/store/user/*/gridpacks/beforeApril2018/*isplaced/*.tar.xz'),
                            ('beforeApril2019',        '/pnfs/iihe/cms/store/user/*/gridpacks/beforeApril2019/*isplaced/*.tar.xz'),
                            ('beforeSeptember2019',    '/pnfs/iihe/cms/store/user/*/gridpacks/beforeSeptember2019/*isplaced/*.tar.xz')])
 
system('git add widths.txt;git commit -m"Update of widths and ctaus"') # make sure this are separate commits (the push you have to do yourself though)
