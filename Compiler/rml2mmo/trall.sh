#!/bin/sh
RESULT=`./translate-if-needed.sh`
if [ "${RESULT}" == "GOOD" ]
then 
    exit 0
else
cd ..
RMLFILES=`ls *.rml`
echo Calling the translator with flags: $@ -napAll
echo This can really take a while!!!
echo On my computer it takes:
echo [BENCH:	116.00 seconds, 497 minor collections, 20 major collections]
${OMDEV}/tools/rml/bin/rml2mod -bench -young-size=1024000 $RMLFILES $@ -napAll
echo Deleting inetrmediate files "*.rmod *.rsig *.rdb"
rm -f *.rmod *.rsig *.rdb
fi

