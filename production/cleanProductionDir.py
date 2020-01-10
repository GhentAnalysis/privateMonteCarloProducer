#!/usr/bin/env python3
import subprocess,glob,os,time,datetime

def log(string):
  print(str(datetime.datetime.now()).split('.')[0] + '   ' + string)

def system(command):
  return subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT).decode()

def getUsage():
  usageLine = system('quota -Qs').splitlines()[-1]
  try:    return float(usageLine.split()[0].replace('G',''))/float(usageLine.split()[1].replace('G', ''))
  except: return 100 # assume output failed because we ran out of disk space

def clean(hours):
  for gridpack in glob.glob('/user/$USER/production/*CMSSW*'):
    for run in glob.glob(gridpack+'/*'):
      for file in glob.glob(run+'/*wmLHEGS*.py'): # check start of the wmLHEGS production
        st = os.stat(file)
        if (time.time() - st.st_mtime)/3600 > hours:
          log('rm -r -f ' + run)
          system('rm -r -f ' + run)
          usage = getUsage()
          if usage < 0.95: return # quit when below safe threshold


# Cleans first the very old ones (probably done or stuck)
# Then, clean as much is needed to get the usage below 0.95
def run():
  clean(30)
  hours = 25
  while True:
    usage = getUsage()
    if usage < 0.95: break
    if usage > 0.97: hours = (20 if hours > 20 else hours)
    if usage > 0.98: hours = (15 if hours > 15 else hours)
    if usage > 0.99: hours = (10 if hours > 10 else hours)
    log(('Usage is %d %%, start cleaning old directories which are older than ' % int(usage*100)) + str(hours) + ' hours')
    #clean(hours)
    if   hours > 20: hours = hours - 2
    elif hours > 15: hours = hours - 1
    elif hours > 10: hours = hours - 0.5
    elif hours > 5:  hours = hours - 0.25
    else:
      log('Deleting a lot --> maybe something is else is taking up the disk space, clean manually')
      break
    time.sleep(10)
  return getUsage()



#
# Main loop
#
start = time.time()
while True:
  if (time.time() - start) > 3599: break # next cron job will take over
  usage = run()
  print(usage)
  if   usage < 0.75: break               # safe, no need to check further, increase checks when we approach our disk quota
  elif usage < 0.8:  time.sleep(1000)
  elif usage < 0.85: time.sleep(500)
  elif usage < 0.9:  time.sleep(200)
  else:              time.sleep(10)

#
# After each job: cleaning empty directories and those who haven't changed in the last 30 hours
#
for dir in glob.glob('/user/$USER/production/HeavyNeutrino*/*'):
  try:
    st = os.stat(dir)
    if (time.time() - st.st_mtime)/3600 > 30:
      system('rm -r -f ' + dir)
  except:
    pass
system('find . -maxdepth 1 -type d -empty -delete')


log('Done')
