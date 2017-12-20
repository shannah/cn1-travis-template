#!/bin/bash

# set -e so that this script will exit if any of the commands fail
set -e


export CN1_PLATFORM=ios
export CN1_RUNTESTS_IOS_SIMULATOR=1

command -v java >/dev/null 2>&1 || { echo >&2 "I require java but it's not installed.  Aborting."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }
command -v xcrun >/dev/null 2>&1 || { echo >&2 "I require xcrun but it's not installed.  You must install Xcode and its command line utilities. Aborting."; exit 1; }

if [ -z "${DEVICE}" ]; then
  echo "Please set the DEVICE environment variable to the iOS version you wish to test on.  E.g. DEVICE=9.3"
  exit 1
fi
bash .travis/build.sh
