#!/bin/bash
# nt        = nucleotide
# -f e      = estimate base frequencies
# --ts/tv e = estimate transition/transversion ratio
# --pinv e  = estimate proportion of invariant sites
# --alpha e = estimate gamma distribution shape parameter
# --search BEST = best topology search result from among NNI and SPR
phyml --input $1 --datatype nt --sequential --model GTR -f e --ts/tv e --pinv e --alpha e --search BEST --quiet
