#!/usr/bin/env python

#
# Script template added to runcmsgrid.sh in order to add a displaced vertex for a heavy neutrino
# The WIDTH parameter for the heavy neutrino gets filled fixGridpackForDisplaced.sh before the script is being added to the gridpack
#

import sys, random

hbar  = 6.58211915e-25 # hbar in GeV s
c     = 299792458000 # speed of light in mm/s
width = WIDTH
ctau  = hbar*c/width
print 'ctau for width ' + str(width) + ' is ' + str(ctau) + 'mm'

lheFile = str(sys.argv[1])
with open(lheFile + 'temp', 'w') as new:
  with open(lheFile) as old:
    for l in old:
      tof = '%.4E' % float(c*random.expovariate(width/hbar))
      if '9900012' in l or '9990012' in l: new.write(l.replace('0.0000e+00 0.0000e+00', tof + ' 0.0000e+00')) # modifying ctau to 10mm
      else:                                new.write(l)

from shutil import move
move(lheFile + 'temp', lheFile)
