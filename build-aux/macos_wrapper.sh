#!/bin/sh

bundle_contents="$( cd "$( dirname "$0" )/../.." >/dev/null 2>&1 && pwd )"/Contents
bundle_res="$bundle_contents"/Resources

export DYLD_LIBRARY_PATH="$bundle_res"/lib
export XDG_CONFIG_DIRS="$bundle_res"/etc/xdg
export XDG_DATA_DIRS="$bundle_res"/share
export GTK_DATA_PREFIX="$bundle_res"
export GTK_EXE_PREFIX="$bundle_res"
export GTK_PATH="$bundle_res"

exec "$bundle_contents/MacOS/dev.geopjr.Tuba" "$@"
