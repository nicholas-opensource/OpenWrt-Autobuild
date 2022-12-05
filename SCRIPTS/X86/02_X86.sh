#!/bin/bash
clear

# GCC CFlags for x86 and Kernel Settings
sed -i 's/O3 -Wl,--gc-sections/O2 -Wl,--gc-sections -mtune=goldmont-plus/g' include/target.mk
rm -rf ./package/kernel/linux/modules/video.mk
rm -rf ./target/linux/x86/64/config-5.10
wget -P package/kernel/linux/modules/ https://github.com/coolsnowwolf/lede/raw/master/package/kernel/linux/modules/video.mk
sed -i 's,CONFIG_DRM_I915_CAPTURE_ERROR ,CONFIG_DRM_I915_CAPTURE_ERROR=n ,g' package/kernel/linux/modules/video.mk
wget -P target/linux/x86/64/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/x86/64/config-5.10

# Addition-Trans-zh-master and fix APNS
cp -rf ../PATCH/duplicate/addition-trans-zh-x86 ./package/utils/addition-trans-zh
cp -rf ../PATCH/duplicate/files ./files

# Echo Model
echo '# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.
grep "Default string" /tmp/sysinfo/model >> /dev/null
if [ $? -ne 0 ];then
    echo should be fine
else
    echo "Compatible PC" > /tmp/sysinfo/model
fi
exit 0
'> ./package/base-files/files/etc/rc.local

# Match Vermagic
latest_release="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | grep -Eo "22.03.+[0-9\.]" | head -n 1)"
wget https://downloads.openwrt.org/releases/${latest_release}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Final Cleanup
chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
