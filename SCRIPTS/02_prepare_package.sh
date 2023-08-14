#!/bin/bash
clear

## Prepare
# GCC CFlags
sed -i 's/Os/O2/g' include/target.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# Remove snapshot tags
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
# Victoria's secret
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/default NODEJS_ICU_SMALL/default NODEJS_ICU_NONE/g' feeds/packages/lang/node/Makefile

## Important Patches
# ARM64: Add CPU model name in proc cpuinfo
cp -rf ../immortalwrt/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patches for SSL
rm -rf ./package/libs/mbedtls
cp -rf ../immortalwrt/package/libs/mbedtls ./package/libs/mbedtls
# Fix fstools
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# Patch kernel to fix fullcone conflict
cp -rf ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
# Patch firewall to enable fullcone
rm -rf ./package/network/config/firewall4
cp -rf ../immortalwrt/package/network/config/firewall4 ./package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
rm -rf ./package/libs/libnftnl
cp -rf ../immortalwrt/package/libs/libnftnl ./package/libs/libnftnl
rm -rf ./package/network/utils/nftables
cp -rf ../immortalwrt/package/network/utils/nftables ./package/network/utils/nftables
# Patch LuCI to add fullcone button
patch -p1 <../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone modules
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
# Remove obsolete options
sed -i 's/syn_flood/synflood_protect/g' package/network/config/firewall/files/firewall.config

## Change x86 & rockchip target and u-boot
rm -rf ./target/linux/rockchip
cp -rf ../immortalwrt_23/target/linux/rockchip ./target/linux/rockchip
cp -rf ../PATCH/rockchip-5.15/* ./target/linux/rockchip/patches-5.15/
rm -rf ./package/boot/uboot-rockchip
cp -rf ../immortalwrt_23/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
rm -rf ./package/boot/arm-trusted-firmware-rockchip
cp -rf ../immortalwrt_23/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# Disable mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg

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
ln -sf ../../../feeds/packages/net/dae ./package/feeds/packages/dae
cp -rf ../immortalwrt_pkg/net/daed ./feeds/packages/net/daed
ln -sf ../../../feeds/packages/net/daed ./package/feeds/packages/daed
git clone -b master --depth 1 https://github.com/QiuSimons/luci-app-daed package/new/luci-app-daed
rm -rf ./feeds/packages/net/v2ray-geodata
cp -rf ../mosdns/v2ray-geodata ./package/new/v2ray-geodata
wget -qO - https://github.com/openwrt/openwrt/commit/47ea58b.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/ce3082d.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/hack-5.15/901-debloat_sock_diag.patch -O target/linux/generic/hack-5.15/901-debloat_sock_diag.patch
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e5679.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch -O target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch
pushd feeds/packages
patch -p1 <../../../PATCH/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ../PATCH/cgroupfs-mount/900-add-cgroupfs2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# Dae update
sed -i '/zip/d;/HASH/d;/RELEASE:=/d' feeds/packages/net/dae/Makefile
sed -i "/VERSION:/ s/$/-$(date +'%Y%m%d')/" feeds/packages/net/dae/Makefile
sed -i '10i\PKG_SOURCE_PROTO:=git' feeds/packages/net/dae/Makefile
sed -i '11i\PKG_SOURCE_URL:=https://github.com/daeuniverse/dae.git' feeds/packages/net/dae/Makefile
sed -i "12i\PKG_SOURCE_VERSION:=$(curl -s https://api.github.com/repos/daeuniverse/dae/commits | grep '"sha"' | head -1 | cut -d '"' -f 4)" feeds/packages/net/dae/Makefile
sed -i '13i\PKG_MIRROR_HASH:=skip' feeds/packages/net/dae/Makefile
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# NIC drivers update
git clone https://github.com/sbwml/package_kernel_r8125 package/new/r8125
cp -rf ../immortalwrt/package/kernel/r8152 ./package/new/r8152
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
