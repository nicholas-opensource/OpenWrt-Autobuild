#!/bin/bash
clear

# Addition-Trans-zh-master
cp -rf ../PATCH/duplicate/addition-trans-zh-x86 ./package/lean/lean-translate

# Match Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p |sed 's/v//g' |sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Crypto
echo '
CONFIG_CRYPTO_AES_NI_INTEL=y
' >> ./target/linux/x86/64/config-5.4

# Final Cleanup
chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
