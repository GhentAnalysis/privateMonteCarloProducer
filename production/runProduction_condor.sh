#!/bin/bash

#
# Usage: ./runProduction.sh era gridpackPath option
#   with "era" one of [Moriond17, Fall17, Autumn18]
#   with "gridpackPath simply the path to your gridpack
#   with "option" currently only "tauLeptonic" implemented or empty
gridpack=$(basename $2)
gridpack=${gridpack%_tarball.tar.xz}
#gridpackDir=$(dirname $(readlink -f $2))
gridpackDir=$(dirname $2)
fragmentDir=$PWD
era=$1
condorSubmitFile="condorSubmit_$gridpack"

if [[ $2 == *"prompt"* ]];      then promptOrDisplaced=prompt
elif [[ $2 == *"displaced"* ]]; then promptOrDisplaced=displaced
else                                 promptOrDisplaced=displaced
fi

if [[ $3 == *"tauLeptonic"* ]]; then
  spec='_tauLeptonic'
  echo "Will use leptonic tau decays"
fi

# Log directory
logDir=$PWD/log/$1/$gridpack$spec
mkdir -p $logDir

# Job submission limits
maxQueuing=5
maxRunning=45

# Output directory
if   [[ $1 == "Moriond17" ]]; then dir=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Moriond17_aug2018_miniAODv3
elif [[ $1 == "Fall17" ]];    then dir=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Fall17
elif [[ $1 == "Autumn18" ]];  then dir=/pnfs/iihe/cms/store/user/$USER/heavyNeutrinoMiniAOD/Autumn18
else
  echo "Unknown era"
  exit 1
fi

# Checking current status of the production for this gridpack
shortName="${gridpack%_slc*}$spec"
existing=$(ls -l $dir/$promptOrDisplaced/$shortName/*.root | wc -l)
printf "Already $existing existing root files for $shortName\n"

# Set a target, try to get to 100 first. Already running productions go up to a next target
target=999
#if (( existing < 100 ));   then target=100;
#elif (( existing < 101 )); then target=100;
#elif (( existing < 150 )); then target=150;
#elif (( existing < 151 )); then target=150;
#elif (( existing < 200 )); then target=200;
#elif (( existing < 201 )); then target=200;
#elif (( existing < 250 )); then target=250;
#elif (( existing < 251 )); then target=250;
#elif (( existing < 300 )); then target=300;
#elif (( existing < 301 )); then target=300;
#elif (( existing < 350 )); then target=350;
#elif (( existing < 351 )); then target=350;
#elif (( existing < 400 )); then target=400;
#elif (( existing < 401 )); then target=400;
#elif (( existing < 500 )); then target=500;
#elif (( existing < 501 )); then target=500;
#elif (( existing < 750 )); then target=750;
#elif (( existing < 751 )); then target=750;
#else                            target=999;
#fi

#
# Wait some additional time when munge is running
#
waitForMunge(){
  while 
    mungeRunning=$(ps -ef | grep munge | wc -l)
    (( $mungeRunning > 3 ))
  do
    sleep $((30*$mungeRunning))
  done
}


#
# Wait based on priority
#
path=$2
waitBeforeNextTry(){
  existing=$(ls -l $dir/$promptOrDisplaced/$shortName/*.root | wc -l)
  if [[ $path == *"highPriority"* ]]; then
    if ((existing < 5 && $i < 3)); then sleep 10;
    elif ((existing < 100));       then sleep $((100 + $1**(2/50)));
    elif ((existing < 250));       then sleep $((200 + $1**(2/30)));
    else                                sleep $((500 + $1**(2/20)));
    fi
  else
    if ((existing < 5));    then sleep 100;
    elif ((existing < 25)); then sleep $((300 + $1**(2/20)));
    else
      otherRunning=$(ps -ef | grep runProduction.sh | wc -l)
      if ((otherRunning > 50)); then sleep $((30*$otherRunning + $1**(2/10))); # If there so many other productions ongoing, sleep a long time
      elif ((existing < 250));  then sleep $((200 + $1**(2/20)));
      else                           sleep $((500 + $1**(2/10)));
      fi
    fi
  fi
}

writeSubmitFile(){
    echo "executable = container_produceEvents_condor.sh" > $8
    echo "arguments = $1 $2 $3 $4 $5 $6" >> $8
    echo "should_transfer_files = NO" >> $8
    echo "log = $7/$1.log" >> $8
    echo "output = $7/$1.out" >> $8
    echo "error = $7/$1.err" >> $8
    echo "request_cpus = 1" >> $8
    echo "request_disk = 1000" >> $8
    echo "request_memory = 2000" >> $8
    echo "queue 1" >> $8
}


printf "target is $target\n"
for i in $(seq 1 $target); do
  if [ -f $dir/$promptOrDisplaced/$shortName/heavyNeutrino_$i.root ]; then
    printf "Skipping $i of $shortName, outputfile already exists\n"
  else
    out=""
    while [[ $out != *"job(s) submitted to cluster"* ]]; do
      while
        waitForMunge
        condor_q=$(condor_q)
        jobs_summary=($(echo "$condor_q" | grep 'Total for '$USER ))
        queuing=${jobs_summary[9]}
        running=${jobs_summary[11]}
        echo "$queuing $running"
        [[ ! -n $running ]] || (( $queuing > $maxQueuing )) || (( $running > $maxRunning ))
      do
        waitBeforeNextTry $i
      done
      touch $logDir # resets mtime of directory, used for the cleanLogDir.py script
      writeSubmitFile $i $gridpack $gridpackDir $promptOrDisplaced $fragmentDir $era $logDir $condorSubmitFile
      out=$(condor_submit ${condorSubmitFile})
      echo $out
    done
    printf "Submitted $i of $shortName \n"
    waitBeforeNextTry $i
  fi
done
