#!/bin/bash
clear

# Addition-Trans-zh-master
cp -rf ../PATCH/duplicate/addition-trans-zh-x86 ./package/utils/addition-trans-zh

# Match Vermagic
latest_release="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | grep -Eo "22.03.+[0-9\.]" | head -n 1)"
wget https://downloads.openwrt.org/releases/${latest_release}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Crypto
echo '
CONFIG_CRYPTO_AES_NI_INTEL=y
' >> ./target/linux/x86/64/config-5.10

# Final Cleanup
chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
