#!/bin/bash
clear

## Prepare
# GCC CFlags
sed -i 's/Os/O2/g' include/target.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# Remove snapshot tags
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
# Victoria's secret
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/default NODEJS_ICU_SMALL/default NODEJS_ICU_NONE/g' feeds/packages/lang/node/Makefile
# Bump firewall4 to the master branch
rm -rf ./package/network/config/firewall4
cp -rf ../openwrt_ma/package/network/config/firewall4 ./package/network/config/firewall4

## Important Patches
# ARM64: Add CPU model name in proc cpuinfo
cp -rf ../immortalwrt_23/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patches for SSL
#rm -rf ./package/libs/mbedtls
#cp -rf ../immortalwrt/package/libs/mbedtls ./package/libs/mbedtls
# Fix fstools
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# Patch kernel to fix fullcone conflict
cp -rf ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
# Patch firewall to enable fullcone
mkdir -p package/network/config/firewall4/patches
cp -f ../PATCH/firewall/001-fix-fw4-flow-offload.patch ./package/network/config/firewall4/patches/001-fix-fw4-flow-offload.patch
cp -f ../PATCH/firewall/002-fw4-apns.patch ./package/network/config/firewall4/patches/002-fw4-apns.patch
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
cp -f ../PATCH/firewall/999-01-firewall4-add-fullcone-support.patch ./package/network/config/firewall4/patches/999-01-firewall4-add-fullcone-support.patch
mkdir -p package/libs/libnftnl/patches
cp -f ../PATCH/firewall/libnftnl/001-libnftnl-add-fullcone-expression-support.patch ./package/libs/libnftnl/patches/001-libnftnl-add-fullcone-expression-support.patch
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ../PATCH/firewall/nftables/002-nftables-add-fullcone-expression-support.patch ./package/network/utils/nftables/patches/002-nftables-add-fullcone-expression-support.patch
# Patch LuCI to add fullcone button
pushd feeds/luci
patch -p1 <../../../PATCH/firewall/luci-app-firewall_add_fullcone_fw4.patch
popd
# FullCone modules
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
# Odhcp
patch -p1 <../PATCH/odhcp6c/1002-odhcp6c-support-dhcpv6-hotplug.patch
mkdir -p package/network/services/odhcpd/patches
cp -f ../PATCH/odhcpd/0001-odhcpd-improve-RFC-9096-compliance.patch ./package/network/services/odhcpd/patches/0001-odhcpd-improve-RFC-9096-compliance.patch
pushd feeds/luci
wget -qO - https://github.com/openwrt/luci/commit/39e6514cee3ba60b0876ca00197d53a65ddc809a.patch | patch -p1
popd
# Remove obsolete options
sed -i 's/syn_flood/synflood_protect/g' package/network/config/firewall/files/firewall.config
# BBRv3
cp -rf ../PATCH/BBRv3/kernel/* ./target/linux/generic/backport-5.15/
# LRNG
cp -rf ../PATCH/LRNG/* ./target/linux/generic/hack-5.15/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
' >>./target/linux/generic/config-5.15

## Change x86 & rockchip target and u-boot
rm -rf ./target/linux/rockchip
cp -rf ../immortalwrt_23/target/linux/rockchip ./target/linux/rockchip
cp -rf ../PATCH/rockchip-5.15/* ./target/linux/rockchip/patches-5.15/
rm -rf ./package/boot/uboot-rockchip
cp -rf ../immortalwrt_23/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
rm -rf ./package/boot/arm-trusted-firmware-rockchip
cp -rf ../immortalwrt_23/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip
sed -i '/REQUIRE_IMAGE_METADATA/d' target/linux/rockchip/armv8/base-files/lib/upgrade/platform.sh
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# Disable mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg

## Extra Packages
# AutoCore
cp -rf ../immortalwrt_23/package/emortal/autocore ./package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/luci-mod-status-autocore.json
rm -rf ./package/new/autocore/files/autocore
wget https://raw.githubusercontent.com/QiuSimons/OpenWrt-Add/master/autocore/files/x86/autocore -O package/new/autocore/files/autocore
sed -i '/i386 i686 x86_64/{n;n;n;d;}' package/new/autocore/Makefile
sed -i '/i386 i686 x86_64/d' package/new/autocore/Makefile
rm -rf ./feeds/luci/modules/luci-base
cp -rf ../immortalwrt_luci_23/modules/luci-base ./feeds/luci/modules/luci-base
sed -i "s,(br-lan),,g" feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci
rm -rf ./feeds/luci/modules/luci-mod-status
cp -rf ../immortalwrt_luci_23/modules/luci-mod-status ./feeds/luci/modules/luci-mod-status
rm -rf ./feeds/packages/utils/coremark
cp -rf ../immortalwrt_pkg/utils/coremark ./feeds/packages/utils/coremark
sed -i "s,-O3,-Ofast -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las,g" feeds/packages/utils/coremark/Makefile
cp -rf ../immortalwrt_23/package/utils/mhz ./package/utils/mhz
# AutoReboot
cp -rf ../immortalwrt_luci/applications/luci-app-autoreboot ./feeds/luci/applications/luci-app-autoreboot
ln -sf ../../../feeds/luci/applications/luci-app-autoreboot ./package/feeds/luci/luci-app-autoreboot
# Dae ready
cp -rf ../immortalwrt_pkg/net/dae ./feeds/packages/net/dae
mkdir -p feeds/packages/net/dae/patches
cp -rf ../PATCH/duplicate/dae/* ./feeds/packages/net/dae/patches/
ln -sf ../../../feeds/packages/net/dae ./package/feeds/packages/dae
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e5679.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch -O target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch
pushd feeds/packages
patch -p1 <../../../PATCH/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ../PATCH/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/script/updategeo.sh ./package/base-files/files/bin/updategeo
cp -f ../PATCH/bpf_loop/*.patch ./target/linux/generic/backport-5.15/
# Dae update
sed -i 's/0.7.4/0.8.0rc2/g' feeds/packages/net/dae/Makefile
sed -i "s/a6d04ceb698e1e6595e14ac51ac56503abd9d7d91790850937dcd1d470364b88/007e712bb1c21199dc748e052e0e175a4a16a576e7327d18c7a4d79c2e32722f/g" feeds/packages/net/dae/Makefile
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# NIC drivers update
cp -rf ../immortalwrt/package/kernel/r8152 ./package/new/r8152
git clone https://github.com/sbwml/package_kernel_r8152 package/new/r8152
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
cp -rf ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch
# Ram-free
cp -rf ../immortalwrt_luci/applications/luci-app-ramfree ./feeds/luci/applications/luci-app-ramfree
ln -sf ../../../feeds/luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/script/fuck package/base-files/files/usr/bin/fuck
# Conntrack_Max
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
# Remove config
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-5.15
