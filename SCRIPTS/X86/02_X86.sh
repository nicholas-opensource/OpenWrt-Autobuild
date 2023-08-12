#!/bin/bash
clear

# GCC CFlags for x86 and Kernel Settings
sed -i 's/O2/O2 -march=x86-64-v2/g' include/target.mk

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
    echo "Generic PC" > /tmp/sysinfo/model
fi
exit 0
'> ./package/base-files/files/etc/rc.local

# Enable SMP
echo '
CONFIG_X86_INTEL_PSTATE=y
CONFIG_SMP=y
' >>./target/linux/x86/config-5.15

# Match Vermagic
latest_release="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | grep -Eo "v23.05.+[0-9\.]" | head -n 1)"
wget https://downloads.openwrt.org/releases/${latest_release}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Final Cleanup
chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
