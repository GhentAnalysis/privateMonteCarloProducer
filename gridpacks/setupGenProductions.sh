# Setup script to check out genproduction repository

# We use the mg242 branch currently
# Newer branches might not work, also the mg242 might get broken depending on how the generator people mess with it
git clone git@github.com:cms-sw/genproductions.git genproductions -b mg242legacy

# Some improvements over the standard genproductions repository
cp .genproductions_hnl_modifications/makeHeavyNeutrinoCards.py genproductions/bin/MadGraph5_aMCatNLO/cards/production/2017/13TeV/exo_heavyNeutrino_LO/
cp .genproductions_hnl_modifications/addDisplacedVertex.py genproductions/bin/MadGraph5_aMCatNLO
cp .genproductions_hnl_modifications/fixGridpack.sh genproductions/bin/MadGraph5_aMCatNLO
cp .genproductions_hnl_modifications/fixGridpackForDisplacedLO.sh genproductions/bin/MadGraph5_aMCatNLO
