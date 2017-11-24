#!/bin/bash

# set -e so that this script will exit if any of the commands fail
set -e

if [ -z "${CN1USER}" ] || [ -z "${CN1PASS}" ]; then
  if [ -n "${CN1_RUNTESTS_ANDROID_EMULATOR}" ] || [ -n "${CN1_RUNTESTS_IOS_SIMULATOR}" ]; then
    echo "Running tests on android or iOS requires the CN1USER and CN1PASS environment variables to be set to your Codename One username and password"
    echo "NOTE: Running tests on iOS and Android requires an enterprise account or higher, since they rely on automated build support"
    exit 1
  fi
fi


if [ "${CN1_PLATFORM}" == "android" ]; then
  echo "Installing Node 6"

  # Need to load NVM command first
  # https://github.com/BanzaiMan/travis_production_test/blob/9c02aef/.travis.yml
  # https://github.com/travis-ci/travis-ci/issues/5999#issuecomment-217201571
  source ~/.nvm/nvm.sh
  nvm install 6
  echo `which node`
  android list targets

  echo "Creating AVD..."
  if [ "${API}" -eq "15" ]; then
    echo no | android create avd --force -n test -t android-15 --abi google_apis/armeabi-v7a
  elif [ "${API}" -eq "16" ]; then
    echo no | android create avd --force -n test -t android-16 --abi armeabi-v7a
  elif [ "${API}" -eq "17" ]; then
    echo no | android create avd --force -n test -t android-17 --abi google_apis/armeabi-v7a
  elif [ "${API}" -eq "18" ]; then
    echo no | android create avd --force -n test -t android-18 --abi google_apis/armeabi-v7a
  elif [ "${API}" -eq "19" ]; then
    echo no | android create avd --force -n test -t android-19 --abi armeabi-v7a
  elif [ "${API}" -eq "21" ]; then
    echo no | android create avd --force -n test -t android-21 --abi armeabi-v7a
  elif [ "${API}" -eq "22" ]; then
    echo no | android create avd --force -n test -t android-22 --abi armeabi-v7a
  fi

  echo "Starting Android Emulator..."
  emulator -avd test -no-window &
  EMULATOR_PID=$!

  # Travis will hang after script completion if we don't kill
  # the emulator
  function stop_emulator() {
    kill $EMULATOR_PID
  }
  trap stop_emulator EXIT
fi
if [ "${CN1_PLATFORM}" == "ios" ]; then
  echo "Installing Ant..."
  # Install ANT and Maven.  They are missing from iOS machines
  curl -L http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.6-bin.tar.gz -o apache-ant-1.9.6-bin.tar.gz
  tar xfz apache-ant-1.9.6-bin.tar.gz --directory ../
  export PATH=`pwd`/../apache-ant-1.9.6/bin:$PATH

  echo "Installing Maven"
  curl -L https://archive.apache.org/dist/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz -o apache-maven-3.2.3-bin.tar.gz
  tar xvfz apache-maven-3.2.3-bin.tar.gz --directory ../
  export PATH=`pwd`/../apache-maven-3.2.3/bin:$PATH
fi

if [ "${CN1_PLATFORM}" == "android" ]; then
  echo "We are in android"
fi

# SET UP ENVIRONMENT
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT_DIR=`pwd`
if [ "${CN1_PLATFORM}" == "ios" ]; then
  # On OS X we need to set JAVA_HOME for maven to work properly
  export JAVA_HOME=$(/usr/libexec/java_home)
fi


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
echo "$CN1 install-jars"
$CN1 install-jars || true

echo "$CN1 install-tests"
$CN1 install-tests || true

# If CN1_SOURCES environment variable is set, then we download the CN1_SOURCES
# And build against those
if [[ -n ${CN1_SOURCES} ]]; then
  echo "Building against Codename One Sources from ${CN1_SOURCES}"
  curl -L ${CN1_SOURCES} -o  master.zip
  unzip master.zip -d ../
  rm master.zip
  mv ../CodenameOne-master ../cn1
  cd ../cn1
  ant all
  cp CodenameOne/dist/CodenameOne.jar $PROJECT_DIR/lib/CodenameOne.jar
  cp Ports/CLDC11/dist/CLDC11.jar $PROJECT_DIR/lib/CLDC11.jar
  cp Ports/JavaSE/dist/JavaSE.jar $PROJECT_DIR/JavaSE.jar
fi

# Build the project
cd $PROJECT_DIR
ant jar

# Run Tests Against JavaSE
if [[ -n ${CN1_RUNTESTS_JAVASE} ]]; then
  mkdir dist/testrunner
  cd dist/testrunner
  echo -e "<?xml version='1.0'?>\n<tests><test path='${PROJECT_DIR}'/></tests>" > tests.xml
  echo "tests.xml content:"
  cat tests.xml
  if [[ -n ${CN1_SOURCES} ]]; then
    $CN1 test -s -e -cn1Sources ${PROJECT_DIR}/../cn1 -skipCompileCn1Sources
  else
    $CN1 test -s -e
  fi
  cd ../..
fi

if [[ -n ${CN1_RUNTESTS_IOS_SIMULATOR} ]]; then
  echo "Running tests on IOS SIMULATOR"

  $CN1 install-appium-tests || true
  echo "Installing appium..."
  npm install appium
  ./node_modules/.bin/appium &
  APPIUM_PID=$!

  # Travis will hang after script completion if we don't kill appium
  function stop_appium() {
    kill $APPIUM_PID
  }
  trap stop_appium EXIT
  #ant -f appium.xml test-ios-appium-simulator -Dcn1.iphone.target=debug_iphone_steve -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS}
  ant -f appium.xml test-ios-appium-simulator -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS}
fi

if [[ -n ${CN1_RUNTESTS_ANDROID_EMULATOR} ]]; then
  echo "Running tests on Android Emulator"

  if [ ! -f "Keychain.ks" ]; then
    wget https://github.com/shannah/cn1-unit-tests/raw/master/Keychain.ks
  fi

  $CN1 install-appium-tests || true
  echo "Installing appium..."
  npm install appium
  ./node_modules/.bin/appium &
  APPIUM_PID=$!

  # Travis will hang after script completion if we don't kill appium
  function stop_appium() {
    kill $APPIUM_PID
  }
  trap stop_appium EXIT



  echo "Waiting for Emulator..."
  bash .travis/android-waiting-for-emulator.sh
  adb shell settings put global window_animation_scale 0 &
  adb shell settings put global transition_animation_scale 0 &
  adb shell settings put global animator_duration_scale 0 &

  echo "Sleeping for 30 seconds to give emulator a chance to settle in..."
  sleep 30

  echo "Unlocking emulator"
  adb shell input keyevent 82 &

  echo "Running tests with appium in the emulator "

  ant -f appium.xml test-android-appium-emulator \
    -Dcn1user=${CN1USER} \
    -Dcn1password=${CN1PASS} \
    -Dcodename1.android.keystore="Keychain.ks" \
    -Dcodename1.android.keystoreAlias="codenameone" \
    -Dcodename1.android.keystorePassword="password"
fi

if [[ -n $CN1_RUNTESTS_IOS_DEVICE ]]; then
  echo "Running Tests on iOS Device"

  $CN1 install-appium-tests || true

  echo "Installing appium..."
  npm install appium
  ./node_modules/.bin/appium &
  APPIUM_PID=$!

  # Travis will hang after script completion if we don't kill appium
  function stop_appium() {
    kill $APPIUM_PID
  }
  trap stop_appium EXIT

  ant -f appium.xml test-ios-appium-device -Dcn1user=${CN1USER} -Dcn1password=${CN1PASS}
fi
exit 0
