#!/bin/bash

# set -e so that this script will exit if any of the commands fail
set -e
DEVICE=9.3
./travis/build-ios.sh
