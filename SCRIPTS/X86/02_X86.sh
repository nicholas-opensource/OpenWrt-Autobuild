#!/bin/bash
clear

# GCC CFlags for x86 and Kernel Settings
sed -i 's/O2/O2 -mtune=goldmont-plus/g' include/target.mk

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

# Enable SMP
echo '
CONFIG_X86_INTEL_PSTATE=y
CONFIG_SMP=y
' >>./target/linux/x86/config-5.15

# Match Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][0-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Final Cleanup
chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
