#!/usr/bin/env python

import os, glob

# Function checking the log file, and finding the era, gridpack and posible state
def checkLogFile(file):
  era      = 'Unknown'
  gridpack = 'logFile:%s' % file
  jobId    = file.split('/')[-1].replace('.txt', '')
  state    = 'Unknown'
  try:
    if os.path.getsize(file) > 100000000: 
      state = 'Output is too big, Geant4 probably entered infinite loop bug'
    else:
      with open(file) as f:
        era     ='Unknown'
        gridpack='Unknown'
        state   ='Unknown'
        for line in f:
          if 'INFO:root:era'                                                            in line: era      = line.split('era:')[-1].replace('\n','')
          if 'INFO:root:gridpack'                                                       in line: gridpack = line.split('gridpack:')[-1].split('_slc')[0] + '*'
          if 'gridftp session cache garbage collection'                                 in line: state    = 'DONE'
          elif 'Disk quota exceeded'                                                    in line: state    = 'Disk quota exceeded'
          elif 'Can not open file for writing'                                          in line: state    = 'Disk quota exceeded'
          elif 'Skipping, outputfile already exists'                                    in line: state    = 'Output file already exists'
          elif 'Directory still in use by other job'                                    in line: state    = 'Working directory in use by other job'
          elif '.tar.xz: Cannot open: No such file or directory'                        in line: state    = 'Gridpack does not exist'
          elif "'Input/output error' (error code 5)"                                    in line: state    = 'Input/output error'
          elif 'read() failed with system error'                                        in line: state    = 'Input/output error'
          elif 'open() failed with system error'                                        in line: state    = 'Input/output error'
          elif "An exception of category 'FallbackFileOpenError' occurred"              in line: state    = 'Input/output error'
          elif 'read failed ; remote I/O error'                                         in line: state    = 'Input/output error'
          elif "write() failed with system error 'Stale file handle' (error code 116)"  in line: state    = 'Input/output error'
          elif 'Stale file handle'                                                      in line: state    = 'Automatic disk clean-up - staleFileHandle'
          elif 'getcwd() failed'                                                        in line: state    = 'Automatic disk clean-up - getCwdFailed'
          elif 'EventCorruption'                                                        in line: state    = 'Automatic disk clean-up - eventCorruption'
          elif 'external termination request'                                           in line: state    = 'External termination'
          elif 'PBS: job killed: walltime'                                              in line: state    = 'Walltime exceeded (raise limit in runProduction.sh)'
          elif ' No more proxies'                                                       in line: state    = 'No more proxies'
          elif 'An empty physical file name specified in the fileNames parameter'       in line: state    = 'Problem with accessing the pile-up through xrootd'
          elif 'RootEmbeddedFileSequence no input files specified for secondary input'  in line: state    = 'Problem with accessing the pile-up through xrootd'
          elif 'Calling XrdAdaptor::RequestManager::OpenHandler::open()'                in line: state    = 'Problem with accessing the pile-up through xrootd'
          elif 'XrdAdaptor::RequestManager::requestFailure'                             in line: state    = 'Problem with accessing the pile-up through xrootd'
          elif 'LZMA compression'                                                       in line: state    = 'LZMA compression error (broken gridpack?)'
          elif 'gzip: ./Events/cmsgrid_decayed_1/events.lhe: No such file or directory' in line: state    = 'Corrupt gridpack - No LHE events'
          elif 'Killed'                                                                 in line: state    = 'Job killed'
          elif 'Aborted'                                                                in line: state    = 'Job aborted'
          elif 'A fatal system signal has occurred: segmentation violation'             in line: state    = 'Segmentation fault'
          elif 'Bus error'                                                              in line: state    = 'Bus error'
          elif 'Too many levels of symbolic links'                                      in line: state    = 'Too many levels of symbolic links'
          elif 'tar: Error is not recoverable: exiting now'                             in line: state    = 'Corrupt gridpack - Compression failed'
          elif 'fewer events than were requested'                                       in line: state    = 'Phase space issues in the gridpack - please check your model/madgraph parameters'
          elif "with open(src, 'rb') as fsrc:"                                          in line: state    = 'Corrupt gridpack - Read file error'
          elif 'No handlers could be found for logger "madevent.stdout"'                in line: state    = 'Corrupt gridpack - No log handlers found'
          elif 'ImportError: No module named models.check_param_card'                   in line: state    = 'Corrupt gridpack - ImportError'
          elif 'Unable to open script output file cmsgrid_final.lhe'                    in line: state    = 'Corrupt gridpack - Unable to open script output file cmsgrid_final.lhe'
          elif './runcmsgrid.sh: No such file or directory'                             in line: state    = 'Corrupt gridpack - No runcmsgrid.sh'
          elif './runcmsgrid.sh: line 107: ./run.sh: No such file or directory'         in line: state    = 'Corrupt gridpack - No run.sh'
          elif 'ImportError: No module named'                                           in line: state    = 'Corrupt gridpack - Import error (%s)' % line.split(': ')[-1]
          elif 'No module named GenProduction.fragment'                                 in line: state    = 'Corrupt gridpack - No genproduction fragment found'
          elif 'cmsDriver.py: command not found'                                        in line: state    = 'Setup error'
          elif 'Usage: cmsDriver.py'                                                    in line: state    = 'Wrong CMS driver command'
          elif '@SUB=TXMLEngine::ParseFile'                                             in line: state    = 'XML parse error'
          elif 'Module: OscarMTProducer:g4SimHits (crashed)'                            in line: state    = 'Crash of geant4'
          elif 'Fatal Root Error: @SUB=TBasket::Streamer'                               in line: state    = 'ROOT file corruption'
          elif 'scale error category'                                                   in line: state    = 'Scale error category in calibratedPhotonProducer'
          if state=='Input/output error':
            for line in f:
              if 'xrootd'                                                               in line: state    = 'Problem with accessing the pile-up through xrootd'
          elif state!='Unknown': break
  except:
    state = 'Unreadable logfile'
  return era, gridpack, jobId, state

# Loop over the logfiles and remove those one with identified state
print 'Analyzing the log files, this could take a while...'
results = {}
for file in glob.glob('log/*/*/*.txt'):
  era, gridpack, jobId, state = checkLogFile(file)
  if state in results: results[state].append((era, gridpack, jobId))
  else:                results[state] = [(era, gridpack, jobId)]
  if state!='Unknown': os.remove(file)
  else:                print 'Unkown state for logfile %s, please check manually!' % file

for state in sorted(set(results.keys())):
  title = '%s (%i)' % (state, len(results[state]))
  print('\n\n%s\n%s' % (title, '-'*len(title)))
  for era, gridpack, jobId in sorted(results[state]):
      print '%-10s %-4s %-120s' % (era, jobId, gridpack)

# Clean-up directories which were not touched or received a new logfile for more than 20 hours
import time
for dir in glob.glob('log/HeavyNeutrino*'):
  if (time.time() - os.stat(dir).st_mtime)/3600 > 20:
    os.rmdir(dir)
