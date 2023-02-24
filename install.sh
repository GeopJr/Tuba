#! /bin/sh

set -e
meson setup build --prefix=/usr
meson configure build -Ddevel=true
cd build
ninja
sudo ninja install
# gdb dev.geopjr.Tooth
dev.geopjr.Tooth
