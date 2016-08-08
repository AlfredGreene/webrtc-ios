#!/bin/bash

set -eu

BASE_DIR=$(cd $(dirname $0) && pwd)
WEBRTC_DIR=$BASE_DIR/webrtc
DEPOT_TOOLS_DIR=$BASE_DIR/depot_tools
GCLIENT_CONFIG=$WEBRTC_DIR/.gclient
WEBRTC_URL="https://chromium.googlesource.com/external/webrtc"
WEBRTC_BUILD_SCRIPT=$WEBRTC_DIR/src/webrtc/build/ios/build_ios_libs.sh
BUILD_DIR=$BASE_DIR/build
DIST_DIR=$BASE_DIR/dist
WEBRTC_FRAMEWORK_NAME=WebRTC
WEBRTC_FRAMEWORK=WebRTC.framework
CONFIG=./config.sh
IDENTITY=

mkdir -p $WEBRTC_DIR
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

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
  echo "    dist        build and archive all products"
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
  export PATH=$PATH:/$DEPOT_TOOLS_DIR
  export GYP_CROSSCOMPILE=1

  # replace code sign identity
  sed -i -e "s/\'CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\': \'[^\']*\',/\'CODE_SIGN_IDENTITY[sdk=iphoneos*]\': \'$IDENTITY\',/" "$WEBRTC_DIR/src/build/common.gypi"

  # ignore patches if already applied
  set +e
  patch -buN webrtc/src/webrtc/build/ios/build_ios_libs.sh < patch/build_ios_libs.sh.diff
  patch -buN webrtc/src/webrtc/system_wrappers/system_wrappers.gyp < patch/system_wrappers.gyp.diff
  patch -buN webrtc/src/webrtc/sdk/sdk.gyp < patch/sdk.gyp.diff
  set -e
}

function build {
  FLAVOR=$1
  FLAVOR_BUILD_DIR=$BUILD_DIR/$FLAVOR
  FLAVOR_DIST_DIR=$DIST_DIR/$FLAVOR

  setup

  echo "Build in $FLAVOR configuration..."
  mkdir -p $FLAVOR_DIST_DIR
  sh "$WEBRTC_BUILD_SCRIPT" -o "$FLAVOR_BUILD_DIR" -b framework -f "$FLAVOR"
  cp -r "$FLAVOR_BUILD_DIR/$WEBRTC_FRAMEWORK" "$FLAVOR_DIST_DIR"
}

function build_debug {
  build Debug
}

function build_release {
  build Release
  pushd $BUILD_DIR/Release > /dev/null
  zip -r "$WEBRTC_FRAMEWORK.zip" "$WEBRTC_FRAMEWORK" > /dev/null
  popd > /dev/null
  mkdir -p $DIST_DIR/Carthage
  cp "$BUILD_DIR/Release/$WEBRTC_FRAMEWORK.zip" $DIST_DIR/Carthage
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
  popd > /dev/null

elif [ $COMMAND = "debug" ]; then
  build_debug

elif [ $COMMAND = "release" ]; then
  build_release

elif [ $COMMAND = "dist" ]; then
  ARCHIVE_DIR=WebRTC-iOS

  build_debug
  build_release

  pushd $BUILD_DIR > /dev/null
  rm -rf $ARCHIVE_DIR
  mkdir -p $ARCHIVE_DIR
  mkdir $ARCHIVE_DIR/Debug
  mkdir $ARCHIVE_DIR/Release
  cp -r $DIST_DIR/Debug/$WEBRTC_FRAMEWORK $ARCHIVE_DIR/Debug
  cp -r $DIST_DIR/Release/$WEBRTC_FRAMEWORK $ARCHIVE_DIR/Release
  zip -r $ARCHIVE_DIR.zip $ARCHIVE_DIR > /dev/null
  rm -rf $DIST_DIR/$ARCHIVE_DIR $DIST_DIR/$ARCHIVE_DIR.zip
  mv $ARCHIVE_DIR $ARCHIVE_DIR.zip $DIST_DIR
  popd > /dev/null

else
  echo "Error: Unknown command '$COMMAND'. See '$0 -h' for help."
fi
