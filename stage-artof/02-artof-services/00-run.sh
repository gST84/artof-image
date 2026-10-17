#!/bin/bash -e
# Docker images (saved by build.sh) are loaded on the first boot
install -d "${ROOTFS_DIR}/opt/artof/images"
cp files/images/*.tar "${ROOTFS_DIR}/opt/artof/images/"

install -m 755 files/artof-firstboot.sh "${ROOTFS_DIR}/usr/local/sbin/artof-firstboot"
install -m 644 files/artof-firstboot.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/ilvo-robotics.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/ilvo.sh "${ROOTFS_DIR}/etc/profile.d/"

on_chroot << EOF2
usermod -aG docker "${FIRST_USER_NAME}"
EOF2
