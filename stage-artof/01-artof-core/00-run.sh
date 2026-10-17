#!/bin/bash -e
# Copy the artof-core source (put in files/artof-core by build.sh) into the image.
# Not in /tmp: on_chroot mounts a tmpfs there.
rm -rf "${ROOTFS_DIR}/opt/artof-core-src"
cp -a files/artof-core "${ROOTFS_DIR}/opt/artof-core-src"
