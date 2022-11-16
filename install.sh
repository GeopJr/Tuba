#! /bin/sh

set -e
meson build --prefix=/usr
cd build
ninja
sudo ninja install
# gdb dev.geopjr.tooth
dev.geopjr.tooth
