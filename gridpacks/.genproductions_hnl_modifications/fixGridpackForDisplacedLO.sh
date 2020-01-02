#!/bin/bash

#
# Fix the gridpack to generate a displaced vertex for the heavy neutrino
#

home=$(pwd)
gridpack=$(basename $1)
mkdir -p temp_$gridpack
cp $1 temp_$gridpack/$gridpack
cd temp_$gridpack
tar -xaf $gridpack
cp $home/addDisplacedVertex.py .
if [[ $gridpack == *"Dirac"* ]]; then
  width=$(awk '/DECAY  9990012/{print $NF}' ./process/madevent/Cards/param_card.dat)   # LO
else
  width=$(awk '/DECAY  9900012/{print $NF}' ./process/madevent/Cards/param_card.dat)   # LO
fi
echo "Adapting gridpack $gridpack to add displaced vertex based on width $width"
sed -i "s/WIDTH/$width/g" addDisplacedVertex.py
sed -i 's#exit 0#./addDisplacedVertex.py cmsgrid_final.lhe\nexit 0#g' runcmsgrid.sh
tar cfJ $gridpack mgbasedir runcmsgrid.sh process gridpack_generation.log addDisplacedVertex.py
cd ..
mv temp_$gridpack/$gridpack $1
rm -r temp_$gridpack
