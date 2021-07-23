#! /bin/sh

set -e
meson build --prefix=/usr
cd build
ninja
sudo ninja install
com.github.bleakgrey.tootle
