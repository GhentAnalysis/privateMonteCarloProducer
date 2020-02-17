#!/usr/bin/env python
import os, glob, fnmatch
os.chdir(os.path.dirname(__file__))

def getCtau(dir):
  with open('widths.txt') as f:
    for l in f:
      if dir.replace('_tauLeptonic', '') in l:
        try:    return float(l.split()[2])
        except: pass
    return -1

def getXsecAndEvents(dir):
  with open('crossSectionsAndEvents.txt') as f:
    for l in f:
      if dir in l:
        try:    return ' '.join(l.split('pb')[0].split()[1:]) if 'pb' in l else 'not yet available', l.split('events')[0].split()[-1]
        except: pass
    return 'not yet available', '?'

# As calculated by the approximations in Phys Rev D 29, 2539 (1984)
# They are not as precise as our cross sections
def getCtauTheory(flavor, mass, v2):
  c = 299792458000 # speed of light in mm/s
  if flavor == 'e':   return c*4.15e-12*(mass**-5.17)*(1./v2)
  if flavor == 'mu':  return c*4.15e-12*(mass**-5.19)*(1./v2)
  if flavor == 'tau': return c*1.08e-11*(mass**-5.44)*(1./v2)


def getFlavor(dir):
  for i in ['e','mu','tau','2l','3l']:
    if ('_'+i+'_') in dir: return i


with open('availableHeavyNeutrinoSamples.txt', 'w') as f:
  with open('heavyNeutrinoFileList.txt', 'w') as ff:
    sampleInfos = []
    for sampleDir in ['/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3/*/Heavy*',
                      '/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/Fall17/*/Heavy*',
                      '/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/Autumn18/*/Heavy*',
                      '/pnfs/iihe/cms/store/user/*/heavyNeutrinoMiniAOD/Moriond17_aug2018/*/Heavy*']: # 2016 miniAODv2
      total = 0
      for dir in glob.glob(sampleDir):
        files  = fnmatch.filter(os.listdir(dir), '*.root')
        nfiles = len(files)
        if not nfiles: continue
        ff.write(dir + '\n')
        for file in sorted(files): ff.write(file + '\n')
        ff.write('\n')
        V            = float(dir.split('V-')[-1].split('_')[0])
        V2           = V**2
        mass         = float(dir.split('M-')[-1].split('_')[0])
        ctau         = getCtau(dir.split('/')[-1])
        ctauT        = None if 'prompt' in dir else getCtauTheory(getFlavor(dir), mass, V2)
        ratio        = ('%2.2f' % (ctau/ctauT)) if ctauT and ctau > 0 else '-'
        ctau         = '-' if 'prompt' in dir or ctau < 0 else '%10.4f' % ctau
        type         = 'dirac_cc' if '_cc_' in dir else ('dirac' if 'Dirac' in dir else 'majorana')
        xsec, events = getXsecAndEvents(dir)
        rec          = '*' if ('Moriond17_aug2018_miniAODv3' in sampleDir or 'Fall17' in sampleDir or 'Autumn18' in sampleDir) else '-'
        ver          = ('2018' if 'Autumn18' in sampleDir else ('2017' if 'Fall17' in sampleDir else ('2016v3' if 'miniAODv3' in sampleDir else '2016v2')))
        sampleInfos.append((rec, type, mass, V2, ctau, ratio, events, xsec, ver, dir))
        total += nfiles*1000
      f.write('%10s --> %d events\n' % (ver, total))



  out = '%11s %10s %7.1f %10.2g %12s %18s %8s %28s %8s %s\n'

  f.write('\n')
  f.write(out.replace('.2f','s').replace('.4f','s').replace('.1f','s').replace('d','s').replace('.2g','s') % ('recommended', 'type', 'mass','V2','ctau (mm)','ctauRatioToTheory', 'events', 'cross section', 'miniAOD', 'directory'))
  f.write(out.replace('.2f','s').replace('.4f','s').replace('.1f','s').replace('d','s').replace('.2g','s') % ('-----------', '----', '----','--','---------','-----------------', '------', '-------------', '-------', '---------'))
  for s in sorted(sampleInfos, key = lambda x : (x[0] != '*', x[1], 'lljj' in x[-1], x[3], x[4], x[-1])):
    f.write(out % s)
