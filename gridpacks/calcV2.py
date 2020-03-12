#! /usr/bin/env python3

def getCtauTheory(flavor, mass, v2):
  c = 299792458000 # speed of light in mm/s
  if flavor == 'e':   return c*4.15e-12*(mass**-5.17)*(1./v2)
  if flavor == 'mu':  return c*4.15e-12*(mass**-5.19)*(1./v2)
  if flavor == 'tau': return c*1.08e-11*(mass**-5.44)*(1./v2)

def getV2Theory(flavor, mass, ctau):
  c = 299792458000 # speed of light in mm/s
  if flavor == 'e':   return c*4.15e-12*(mass**-5.17)*(1./ctau)
  if flavor == 'mu':  return c*4.15e-12*(mass**-5.19)*(1./ctau)
  if flavor == 'tau': return c*1.08e-11*(mass**-5.44)*(1./ctau)
  if flavor == '2l':  return (getV2Theory('e', mass, ctau)+getV2Theory('mu', mass, ctau))/4 

for mass, ctau in [(5, 24.61), (5, 69.66), (6, 12.53), (6, 82.25), (8, 108.86), (8, 5.46), (8, 1.25), (10, 137.80), (10, 6.28), (1, 14.84), (1, 74.22)]:
# v2 = getV2Theory('e', mass, ctau)
# print('e  %4d %3d %.4g' % (mass, ctau, v2/2))
# v2 = getV2Theory('mu', mass, ctau)
# print('mu %4d %3d %.4g' % (mass, ctau, v2/2))
  v2 = getV2Theory('2l', mass, ctau)
  print('2l %4d %3d %.4g' % (mass, ctau, v2/2))

print('\n')
for mass, v2 in [(12, 1e-5), (8, 5e-7), (8, 4e-7), (8, 3e-7), (8, 2e-7), (8, 1e-7), (10, 2e-7), (10, 1e-7), (10, 6e-8), (10, 5e-8)]:
  ctau = getCtauTheory('e', mass, v2)
  print('e  %4d GeV     V2=%.4g --> %10.4f mm (majorana fit)' % (mass, v2, ctau/2))
  ctau = getCtauTheory('mu', mass, v2)
  print('mu %4d GeV     V2=%.4g --> %10.4f mm (majorana fit)' % (mass, v2, ctau/2))



