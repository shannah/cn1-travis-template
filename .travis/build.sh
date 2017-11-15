#!/bin/bash
set -e
# SET UP ENVIRONMENT
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT_DIR=`pwd`
export JAVA_HOME=$(/usr/libexec/java_home)
# Install Codename One CLI tools
echo "Current directory: "
echo `pwd`
cd ..
mkdir codenameone-cli
cd codenameone-cli
npm install codenameone-cli
CN1=`pwd`/node_modules/.bin/cn1

cd $PROJECT_DIR

# Install missing jar files into project
$CN1 install-jars
$CN1 install-tests

# If CN1_SOURCES environment variable is set, then we download the CN1_SOURCES
# And build against those
if [[ -n ${CN1_SOURCES} ]]; then
  curl -L ${CN1_SOURCES} -o  master.zip
  unzip master.zip -d ../
  rm master.zip
  mv ../CodenameOne-master ../CodenameOne
  curl -L https://github.com/codenameone/cn1-binaries/archive/master.zip -o master.zip
  unzip master.zip -d ../
  mv ../cn1-binaries-master ../cn1-binaries
  rm master.zip
  curl -L https://github.com/codenameone/codenameone-skins/archive/master.zip -o master.zip
  unzip master.zip -d ../
  mv ../codenameone-skins-master ../codenameone-skins
  cd ../codenameone-skins
  ./build_skins.sh
  mv ../CodenameOne ../cn1
  cd ../cn1
  cd CodenameOne
  ant jar
  cd ../CodenameOneDesigner
  mkdir dist
  mkdir dist/lib
  ant release
  cd ../Ports/CLDC11
  ant jar
  cd ../JavaSE
  ant jar
  cd ../..
  cp CodenameOne/dist/CodenameOne.jar $PROJECT_DIR/lib/CodenameOne.jar
  cp Ports/CLDC11/dist/CLDC11.jar $PROJECT_DIR/lib/CLDC11.jar
  cp Ports/JavaSE/dist/JavaSE.jar $PROJECT_DIR/JavaSE.jar
fi

# Build the project
cd $PROJECT_DIR
ant jar

# Run Tests Against JavaSE
if [[ -n ${CN1_RUNTESTS_JAVASE} ]]; then
  $CN1 install-tests
  ant -f tests.xml test-javase
fi

if [[ -n ${CN1_RUNTESTS_IOS_SIMULATOR} ]]; then
  $CN1 install-appium-tests
  echo "Installing appium..."
  npm install appium
  ./node_modules/.bin/appium &
  APPIUM_PID=$!
  ant -f appium.xml test-ios-appium-simulator -Dcn1.iphone.target=debug_iphone_steve -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS}
  kill $APPIUM_PID
fi

if [[ -n $CN1_RUNTESTS_IOS_DEVICE && -n ${CN1PASS} && -n ${CN1USER} ]]; then
  $CN1 install-appium-tests
  echo "Installing appium..."
  npm install appium
  ./node_modules/.bin/appium &
  APPIUM_PID=$!
  ant -f appium.xml test-ios-appium-device -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS}
  kill $APPIUM_PID
fi
