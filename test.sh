#!/bin/sh

BASE=`rpmbuild --nobuild --eval '%{_topdir}' 2>/dev/null`

set -x
(cd test-data
 cp Getopt-Function-0.00*.tar.gz $BASE/SOURCES
)

#cp makerpm.pl $BASE/SOURCES
#cd $BASE

echo '********* VERSION INFO TESTS ************'

echo '*** should fail with bad version'
./makerpm.pl --specs --nochown --verbose --auto-desc --source=Getopt-Function-0.003.tar.gz

echo '*** should work correctly but warn about bad version'
./makerpm.pl --specs --nochown --verbose --auto-desc --source=Getopt-Function-0.0031.tar.gz

echo '*** should just work'
./makerpm.pl --specs --nochown --verbose --auto-desc --source=Getopt-Function-0.0032.tar.gz

echo '********* BUILD TESTS ************'

echo '*** should automatically derive description and build to end'
./makerpm.pl --specs --nochown --verbose --auto-desc --source=Getopt-Function-0.002.tar.gz
rpm -ba SPECS/Getopt-Function-0.002.spec

echo '*** should use package provided description and build to end'
./makerpm.pl --specs --nochown --verbose --auto-desc --source=Getopt-Function-0.004.tar.gz
rpm -ba SPECS/Getopt-Function-0.004.spec

echo '********* FILE DATA TESTS ************'

echo '*** should use data from package to make specfile'
echo '*** should use user supplied data to make specfile'
echo '*** should override package data with user supplied data and warn'
