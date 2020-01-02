#!/bin/bash
gridpack=$(basename $1)
here=$(pwd)
mkdir -p /tmp/$USER/temp_$gridpack
cp $1 /tmp/$USER/temp_$gridpack/$gridpack
cd /tmp/$USER/temp_$gridpack
tar -xaf $gridpack
sed -i 's#ls -l#ls -l\nsed -i "s/LesHouchesEvent>/LesHouchesEvents>/g" cmsgrid_final.lhe#g' runcmsgrid.sh
tar cfJ $gridpack mgbasedir runcmsgrid.sh process gridpack_generation.log
mv /tmp/$USER/temp_$gridpack/$gridpack $here
rm -r /tmp/$USER/temp_$gridpack
