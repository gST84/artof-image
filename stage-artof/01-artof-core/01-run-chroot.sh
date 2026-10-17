#!/bin/bash -e
# Build artof-core natively for ARM64 (snap7 and shapelib are built from source)
# and install the binaries in /usr/bin, libsnap7.so in /usr/lib/ilvo
mkdir -p /opt/artof-core-src/build
cd /opt/artof-core-src/build
NO_ASAN=1 cmake -DCMAKE_BUILD_TYPE=Release -DINSTALL_FOLDER="/usr/bin" ..
make -j"$(nproc)" install
ldconfig

# Default ARTOF data (settings, config, types, fields, implements)
mkdir -p /var/lib/ilvo
cp -a /opt/artof-core-src/artof-core/var/lib/ilvo/. /var/lib/ilvo/

rm -rf /opt/artof-core-src
