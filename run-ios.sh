#!/bin/bash

set -e
BASE=`pwd`
SANDBOX=/tmp/sandbox
rm -rf "$SANDBOX"
mkdir "$SANDBOX"
cd "$SANDBOX"
regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
if [[ $1 =~ $regex ]]; then
  cd "$SANDBOX"
  git clone $1 project
else
  cd "$BASE"
  cp -r "$1" "$SANDBOX"/project
  cd "$SANDBOX"
fi
rm -rf project/.travis || true
cp -r "${BASE}"/.travis "${SANDBOX}/project/.travis"
cd project
bash ./.travis/build-ios.sh
