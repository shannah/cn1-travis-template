#!/bin/bash

# SET UP ENVIRONMENT
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT_DIR=`pwd`

# Install Codename One CLI tools
cd ..
mkdir codenameone-cli
cd codenameone-cli
npm install codenameone-cli
CN1=`pwd`/node_modules/.bin/cn1

cd $PROJECT_DIR

# Install missing jar files into project
$CN1 install-jars || exit 1
$CN1 install-tests

# If CN1_SOURCES environment variable is set, then we download the CN1_SOURCES
# And build against those
if [[ -n ${CN1_SOURCES} ]]; then
  curl -L ${CN1_SOURCES} > master.zip || exit 1
  unzip master.zip -d ../ || exit 1
  rm master.zip || exit 1
  curl -L https://github.com/codenameone/cn1-binares/archive/master.zip >master.zip || exit 1
  mv ../cn1-binaries-master ../cn1-binaries || exit 1
  rm master.zip || exit 1
  curl -L https://github.com/codenameone/codenameone-skins/archive/master.zip >master.zip || exit 1
  unzip master.zip -d ../ || exit 1
  mv ../codenameone-skins-master ../codenameone-skins || exit 1
  cd ../codenameone-skins || exit 1
  ./build_skins.sh || exit 1
  mv ../CodenameOne ../cn1 || exit 1
  cd ../cn1 || exit 1
  cd CodenameOne || exit 1
  ant jar || exit 1
  cd ../CodenameOneDesigner || exit 1
  mkdir dist
  mkdir dist/lib
  ant release || exit 1
  cp ../CodenameOne/dist/CodenameOne.jar $PROJECT_DIR/lib/CodenameOne.jar || exit 1
  cp ../CodenameOne/Ports/CLDC11/dist/CLDC11.jar $PROJECT_DIR/lib/CLDC11.jar || exit 1
  cp ../CodenameOne/Ports/JavaSE/dist/JavaSE.jar $PROJECT_DIR/JavaSE.jar || exit 1
fi

# Build the project
cd $PROJECT_DIR
ant jar || exit 1

# Run Tests Against JavaSE
if [[ -n ${CN1_RUNTESTS_JAVASE} ]]; then
  $CN1 install-tests
  ant -f tests.xml test-javase || exit 1
fi

if [[ -n ${CN1_RUNTESTS_IOS_SIMULATOR} && -n ${CN1PASS} && -n ${CN1USER} ]]; then
  $CN1 install-appium-tests
  ant -f appium.xml test-ios-appium-simulator -Dcn1.iphone.target=debug_iphone_steve -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS} || exit 1
fi

if [[ -n $CN1_RUNTESTS_IOS_DEVICE && -n ${CN1PASS} && -n ${CN1USER} ]]; then
  $CN1 install-appium-tests
  ant -f appium.xml test-ios-appium-device -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS} || exit 1
fi
