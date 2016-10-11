#!/usr/bin/env bash

#
# This script will regenerate several projects that use zproject
# and then configure, build, install and run tests on them.
#
# Correctness is up to the user by inspection of messages emitted.
#
# In case of error, a log of last commands attempted can be found at files
# with extension .err in the build area (i.e. zproject/tmp).
#
# When it completes without errors, there will not be any *.err file
# left and the script exits with zero.
#
# Otherwise build area contains ${project}_${phase}.err files with error
# messages and script exits with non-zero value.
#
# Suggestion:
#   - Run the script prior to making changes to zproject and save output
#     to before.log:
#       opedroso@OPLIN:~/git/zproject$ ./tstbldgen.sh > ../before.log
#
#   - Make your changes to zproject
#
#   - Run the script and redirect to after.log:
#       opedroso@OPLIN:~/git/zproject$ ./tstbldgen.sh > ../after.log
#
#   - Compare before.log and after.log to check for any failures in
#     build, install, or test results:
#       opedroso@OPLIN:~/git/zproject$ meld ../before.log ../after.log
#
# Usage:
#   $ tstgenbld.sh [clean] [> results.log]
#
#     - if clean argument is present, the scrip will clean any git
#       repository clones and exit.
#     - Clean does not apply to zproject itself, only to other
#       repositories used in the process such as gsl, libsodium, libzmq,
#       czmq, malamute and zyre.
#
#     - Important to notice that if clean is used in command line, the
#       script will ask for confirmation that the ../gitprojects
#       directory is actually gone. I have had some problems when using
#       git clones that were on location shared by different OS machines
#       (Linux and Windows).
#

# set next line to "-o xtrace" if debugging
XTRACE="+o xtrace"
set ${XTRACE}

export STARTDATE=`date`

# directory where products will be installed
BUILD_PREFIX=${PWD}/tmp
echo Projects will be built to here "${BUILD_PREFIX}"
#read -p "Press ENTER to continue: "



# cleanup previous build, if any
test -d ${BUILD_PREFIX} && find ${BUILD_PREFIX} | xargs rm -rf
test -d ${BUILD_PREFIX} &&
            read -p "Error: Manually delete ${BUILD_PREFIX} then press ENTER: "
mkdir ${BUILD_PREFIX}

# define function used later in processing
function loglogs() {
    echo ..Logfiles after ${phase} phase
    ls ${BUILD_PREFIX}/*.err > /dev/null 2>&1 && ls ${BUILD_PREFIX}/*.err
#   ls ${BUILD_PREFIX}/*.ok  > /dev/null 2>&1 && ls ${BUILD_PREFIX}/*.ok
    #read -p "Press ENTER to continue: "
    return 0
}


# build zproject with any changes made to it
echo Building zproject
phase=building
(
    cd ../zproject &&
    ./autogen.sh &&
    ./configure &&
    make &&
    make install &&
    exit $?
) > ${BUILD_PREFIX}/zproject_${phase}.err 2>&1 && mv ${BUILD_PREFIX}/zproject_${phase}.err ${BUILD_PREFIX}/zproject_${phase}.ok
loglogs


# look for the word "FAIL" in .err files and report them
function logfailed() {
    echo Problems during $1:
    grep -iw -e fail $1 
    return 1
}

# inform user of final results
finalresult=0
for project in zproject ; do
  for phase in building autogen-config make make-install make-check; do
    test -f ${BUILD_PREFIX}/${project}_${phase}.err &&
            logfailed ${BUILD_PREFIX}/${project}_${phase}.err
  done
done
finalresult=$?

popd > /dev/null 2>&1

echo STOP__DATE: `date`
echo START_DATE: $STARTDATE

exit ${finalresult}
