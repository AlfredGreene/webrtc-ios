#!/bin/bash

set -eu

BASE_DIR=$(cd $(dirname $0) && pwd)
WEBRTC_DIR=$BASE_DIR/webrtc
DEPOT_TOOLS_DIR=$BASE_DIR/depot_tools
GCLIENT_CONFIG=$WEBRTC_DIR/.gclient
WEBRTC_URL="https://chromium.googlesource.com/external/webrtc"
WEBRTC_BUILD_SCRIPT=$WEBRTC_DIR/src/webrtc/build/ios/build_ios_libs.sh
BUILD_DIR=$BASE_DIR/build
OUT_DIR=$BASE_DIR
WEBRTC_FRAMEWORK_NAME=WebRTC
WEBRTC_FRAMEWORK=WebRTC.framework
CONFIG=./config.sh
CARTHAGE=carthage

mkdir -p $WEBRTC_DIR
mkdir -p $BUILD_DIR

function usage {
  echo "WebRTC framework build script."
  echo ""
  echo "Usage: $0 [-h] <command>"
  echo "    -h          print this message"
  echo ""
  echo "Commands:"
  echo "    setup       install depot_tools into a local directory"
  echo "    fetch       get WebRTC source code"
  echo "    debug       build in debug configuration"
  echo "    release     build in release configuration"
  echo "    all         build in debug and release configurations"
  exit 0
}

while getopts "h" OPT; do
  case "$OPT" in
    h) usage;;
    *)
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))
if [ $# -eq 0 ]; then
  usage
fi

source $CONFIG

COMMAND=$1

function setup {
  export PATH=$PATH:/$DEPOT_TOOLS
}

function build {
  FLAVOR=$1
  FLAVOR_BUILD_DIR=$BUILD_DIR/$FLAVOR
  FLAVOR_OUT_DIR=$OUT_DIR/$FLAVOR

  echo "Build in $FLAVOR configuration..."
  mkdir -p $FLAVOR_OUT_DIR
  sh "$WEBRTC_BUILD_SCRIPT" -o "$FLAVOR_BUILD_DIR" -b framework
  cp -r "$FLAVOR_BUILD_DIR/$WEBRTC_FRAMEWORK" "$FLAVOR_OUT_DIR"

  # archive with Carthage
  echo "Archive the built framework with Carthage..."
  if [ -f "$CARTHAGE"]; then
    pushd $FLAVOR_BUILD_DIR
    $CARTHAGE archive $WEBRTC_FRAMEWORK_NAME
    popd
  else
    echo "Warning: Cathage is not found."
  fi
}

if [ $COMMAND = "setup" ]; then
  if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    echo "Get depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  else
    echo "Update depot_tools..."
    git -C $DEPOT_TOOLS_DIR pull
  fi

elif [ $COMMAND = "fetch" ]; then
  pushd $WEBRTC_DIR > /dev/null
  if [ ! -f "$GCLIENT_CONFIG" ]; then
    echo "Configure gclient..."
    gclient config --unmanaged  --name=src "$WEBRTC_URL"
    echo "target_os = ['ios', 'mac']" >> .gclient
  fi
  echo "Checkout the code..."
  gclient sync -r "$WEBRTC_REVISION" --with_branch_heads
  popd

elif [ $COMMAND = "debug" ]; then
  build Debug
else
  echo "Error: Unknown command '$COMMAND'. See '$0 -h' for help."
fi

echo "Done."
