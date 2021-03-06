# Workflow for obtaining a parallel set of MWEs from a parallel corpus
# Required to set paths to the tools
# LV Tagger only required for Latvian

MOSES_SCRIPTS=
TREE_TAGGER=
LV_TAGGER=
MWE_TOOLKIT=
MONO=
MP_ALIGNER=
MWE_TOOLS=

# This is an example for English and Czech

# Tokenize data
$MOSES_SCRIPTS/tokenizer/tokenizer.perl -l en < train.en > train.tok.en
$MOSES_SCRIPTS/tokenizer/tokenizer.perl -l cs < train.cs > train.tok.cs

# Add <sentence> tags after each new line
sed 's/$/\n<sentence>/' train.tok.en > train.br.en
sed 's/$/\n<sentence>/' train.tok.cs > train.br.cs

# Tag data 
$TREE_TAGGER/cmd/tree-tagger-english < train.br.en > train.en.tt
$TREE_TAGGER/cmd/tree-tagger-czech < train.br.cs > train.cs.tt

# Replace <sentence> tags with .	SENTENCE	. 
sed 's/<sentence>/.\tSENTENCE\t./g' train.en.tt > train.en.tt2
sed 's/<sentence>/.\tSENTENCE\t./g' train.cs.tt > train.cs.tt2

# Tagger to XML 
python2 $MWE_TOOLKIT/bin/from_treetagger.py -s SENTENCE train.en.tt2 > train.en.tagged.xml
python2 $MWE_TOOLKIT/bin/from_treetagger.py -s SENTENCE train.cs.tt2 > train.cs.tagged.xml

# Get patterns... somehow?!
# /patterns folder contains
# 	patterns_cs.xml
# 	patterns_en.xml
# 	patterns_lv.xml

# Extract MWE candidates 
python2 $MWE_TOOLKIT/bin/candidates.py -p index/patterns_en.xml train.en.tagged.xml > candidates.en.xml
python2 $MWE_TOOLKIT/bin/candidates.py -p index/patterns_cs.xml train.cs.tagged.xml > candidates.cs.xml

# Clean the candidates
grep -v "<unknown>" candidates.cs.xml > candidates.cs.clean.xml
grep -v '<!-- #  # -->' candidates.en.xml > candidates.en.clean.xml

# Annotate data 
python2 $MWE_TOOLKIT/bin/annotate_mwe.py -c candidates.en.xml train.en.tagged.xml > train.en.annotated.xml
python2 $MWE_TOOLKIT/bin/annotate_mwe.py -c candidates.cs.xml train.cs.tagged.xml > train.cs.annotated.xml

# Use my tool to convert for MPFormat 
$MWE_TOOLS/XMLConverter/converter train.en.annotated.xml
$MWE_TOOLS/XMLConverter/converter train.cs.annotated.xml

# Run MPAligner to try to align the MWEs 
$MONO/mono --runtime=v4.0 $MP_ALIGNER/ParallelCorpusMPAligner.exe \
-c $MP_ALIGNER/LinuxMPAlignerConfig.xml \
-si train.en.annotated.xml.taas.tagged \
-ti train.cs.annotated.xml.taas.tagged \
-sl en \
-tl cs \
-o train.MPOutput

# Convert MPOutput to normal phrase pairs with my tool 
$MWE_TOOLS/MPoutput_to_training_data.sh train.MPOutput train.en.out train.cs.out


# The final outputs should be an aligned set of parallel multiword expressions in files:
# "train.en.out" and "train.cs.out"