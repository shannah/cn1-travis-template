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
$CN1 install-tests || exit 1

# If CN1_SOURCES environment variable is set, then we download the CN1_SOURCES
# And build against those
if [[ -n ${CN1_SOURCES} ]]; then
  curl ${CN1_SOURCES} > master.zip
  unzip master.zip -d ../
  mv ../cn1-binaries-master ../cn1-binaries
  rm master.zip
  curl https://github.com/codenameone/codenameone-skins/archive/master.zip >master.zip
  unzip master.zip -d ../
  mv ../codenameone-skins-master ../codenameone-skins
  cd ../codenameone-skins
  ./build_skins.sh
  mv ../CodenameOne ../cn1
  cd ../cn1
  cd CodenameOne
  ant jar || exit 1
  cd ../CodenameOneDesigner
  mkdir dist
  mkdir dist/lib
  ant release || exit 1
  cp ../CodenameOne/dist/CodenameOne.jar $PROJECT_DIR/lib/CodenameOne.jar
  cp ../CodenameOne/Ports/CLDC11/dist/CLDC11.jar $PROJECT_DIR/lib/CLDC11.jar
  cp ../CodenameOne/Ports/JavaSE/dist/JavaSE.jar $PROJECT_DIR/JavaSE.jar
fi

# Build the project
cd $PROJECT_DIR
ant jar || exit 1

# Run Tests Against JavaSE
if [[ -n $CN1_RUNTESTS_JAVASE ]]; then
  ant compile-test
  java -cp dist/unitTests.jar:JavaSE.jar com.codename1.impl.javase.TestRunner
fi

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
 $SCRIPTPATH/build-osx.sh
else
    # Install some custom requirements on Linux
fi
