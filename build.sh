#!/bin/bash

set -eu

BASE_DIR=$(cd $(dirname $0) && pwd)
WEBRTC_DIR=$BASE_DIR/webrtc
DEPOT_TOOLS_DIR=$BASE_DIR/depot_tools
GCLIENT_CONFIG=$WEBRTC_DIR/.gclient
WEBRTC_URL="https://chromium.googlesource.com/external/webrtc"
CONFIG=./config.sh

mkdir -p $WEBRTC_DIR

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

if [ $COMMAND = "setup" ]; then
  if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    echo "Get depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  else
    echo "Update depot_tools..."
    git -C $DEPOT_TOOLS_DIR pull
  fi

elif [ $COMMAND = "fetch" ]; then
  cd $WEBRTC_DIR
  if [ ! -f "$GCLIENT_CONFIG" ]; then
    echo "Configure gclient..."
    gclient config --unmanaged "$WEBRTC_URL"
    echo "target_os = ['ios', 'mac']" >> .gclient
  fi
  echo "Checkout the code..."
  gclient sync -r "$WEBRTC_REVISION" --with_branch_heads

else
  echo "Unknown command '$COMMAND'. See '$0 -h' for help."
fi

echo "Done."
