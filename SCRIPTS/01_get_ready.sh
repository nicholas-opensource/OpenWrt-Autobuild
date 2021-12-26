#!/bin/bash

# Clone source code
latest_release="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | grep -Eo "v21.02.+[0-9\.]" | head -n 1)"
#wget -qO openwrt_back.tar.gz https://github.com/openwrt/openwrt/archive/refs/tags/${latest_release}.tar.gz && mkdir openwrt_back && tar -zxvf openwrt_back.tar.gz -C openwrt_back --strip-components 1 && rm openwrt_back.tar.gz
git clone --single-branch -b ${latest_release} https://github.com/openwrt/openwrt openwrt_back
git clone --single-branch -b openwrt-21.02 https://github.com/openwrt/openwrt openwrt_new
rm -f ./openwrt_new/include/version.mk
rm -f ./openwrt_new/include/kernel-version.mk
rm -f ./openwrt_new/package/base-files/image-config.in
rm -rf ./openwrt_new/target/linux/*
cp -f ./openwrt_back/include/version.mk ./openwrt_new/include/version.mk
cp -f ./openwrt_back/include/kernel-version.mk ./openwrt_new/include/kernel-version.mk
cp -f ./openwrt_back/package/base-files/image-config.in ./openwrt_new/package/base-files/image-config.in
cp -rf ./openwrt_back/target/linux/* ./openwrt_new/target/linux/
mkdir openwrt
cp -rf ./openwrt_new/* ./openwrt/

exit 0
