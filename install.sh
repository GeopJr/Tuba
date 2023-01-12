#! /bin/sh

set -e
meson setup build --prefix=/usr
meson configure build -Dprofile=development
cd build
ninja
sudo ninja install
# gdb dev.geopjr.tooth
dev.geopjr.tooth
