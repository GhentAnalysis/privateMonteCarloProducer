#!/bin/bash

export X509_USER_PROXY=/user/$USER/x509up_u`id -u`

/group/userscripts/sl6 /user/bvermass/heavyNeutrino/Dileptonprompt/CMSSW_7_1_30/src/privateMonteCarloProducer/production/produceEvents_condor.sh $1 $2 $3 $4 $5 $6
