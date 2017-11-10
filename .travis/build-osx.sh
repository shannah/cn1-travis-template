#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
$SCRIPTPATH/build-common.sh
if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
 PROJECT_DIR=`pwd`
 if [[ -z ${CN1_SOURCES} ]]; then
   curl https://github.com/codenameone/cn1-binaries/archive/master.zip > master.zip
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
   ant jar
   cd ../CodenameOneDesigner
   mkdir dist
   mkdir dist/lib
   ant release
   cp ../CodenameOne/dist/CodenameOne.jar $PROJECT_DIR/lib/CodenameOne.jar
   cp ../CodenameOne/dist/CLDC11.jar $PROJECT_DIR/lib/CLDC11.jar
 fi

 cd "${PROJECT_DIR}"
 mkdir appium
 cd appium
 npm install appium
 cd ..
 ./appium/node_modules/.bin/appium &
 cd ..
 mkdir codenameone-cli
 cd codenameone-cli
 npm install codenameone-cli
 CN1=`pwd`/node_modules/.bin/cn1
 cd "${PROJECT_DIR}"
 $CN1 install-jars
 cp ../cn1/CodenameOne/dist/CodenameOne.jar lib/CodenameOne.jar
 cp ../cn1/CodenameOne/dist/CLDC11.jar lib/CLDC11.jar
 ant -f appium.xml test-ios-appium-simulator

else
    # Install some custom requirements on Linux
fi
