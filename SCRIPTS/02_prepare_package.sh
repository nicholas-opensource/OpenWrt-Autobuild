#!/bin/bash
clear

## Prepare
# GCC CFlags
sed -i 's/Os/O3 -Wl,--gc-sections/g' include/target.mk
wget -qO - https://github.com/openwrt/openwrt/commit/8249a8c.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/66fa343.patch | patch -p1
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r2s.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r4s.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg
# Victoria's Secret
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
wget -P scripts/ https://github.com/immortalwrt/immortalwrt/raw/master/scripts/download.pl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/download.mk
sed -i '/unshift/d' scripts/download.pl
sed -i '/mirror02/d' scripts/download.pl
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/default NODEJS_ICU_SMALL/default NODEJS_ICU_NONE/g' feeds/packages/lang/node/Makefile

## Important Patches
# OpenSSL
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/11895.patch
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/14578.patch
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/16575.patch
# Remove Kconfig I8K
cp -f ../PATCH/backport/290-remove-kconfig-CONFIG_I8K.patch ./target/linux/generic/hack-5.10/290-remove-kconfig-CONFIG_I8K.patch
# Backport MG-LRU to linux kernel 5.10
cp -rf ../PATCH/backport/MG-LRU/* ./target/linux/generic/pending-5.10/
echo '
CONFIG_LRU_GEN=y
CONFIG_LRU_GEN_ENABLED=y
# CONFIG_LRU_GEN_STATS is not set
' >>./target/linux/generic/config-5.10
# ARM64: Add CPU model name in proc cpuinfo
wget -P target/linux/generic/hack-5.10/ https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.10/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patches for SSL
rm -rf ./package/libs/mbedtls
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/libs/mbedtls package/libs/mbedtls
rm -rf ./package/libs/openssl
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/libs/openssl package/libs/openssl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/openssl-engine.mk
# Fix fstools
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# Patch kernel to fix fullcone conflict
pushd target/linux/generic/hack-5.10
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.10/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch firewall to enable fullcone
rm -rf ./package/network/config/firewall4
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/network/config/firewall4 package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
rm -rf ./package/libs/libnftnl
svn export https://github.com/wongsyrone/lede-1/trunk/package/libs/libnftnl package/libs/libnftnl
rm -rf ./package/network/utils/nftables
svn export https://github.com/wongsyrone/lede-1/trunk/package/network/utils/nftables package/network/utils/nftables
mkdir -p package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/package/network/config/firewall/patches/100-fullconenat.patch
wget -qO- https://github.com/msylgj/R2S-R4S-OpenWrt/raw/master/PATCHES/001-fix-firewall3-flock.patch | patch -p1
# Patch LuCI to add fullcone button
patch -p1 <../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone modules
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
cp -rf ../PATCH/duplicate/fullconenat ./package/network/fullconenat

## Change Rockchip target and Uboot
rm -rf ./target/linux/rockchip
svn export https://github.com/coolsnowwolf/lede/trunk/target/linux/rockchip target/linux/rockchip
rm -rf ./target/linux/rockchip/Makefile
wget -P target/linux/rockchip/ https://github.com/openwrt/openwrt/raw/openwrt-22.03/target/linux/rockchip/Makefile
rm -rf ./target/linux/rockchip/patches-5.10/002-net-usb-r8152-add-LED-configuration-from-OF.patch
rm -rf ./target/linux/rockchip/patches-5.10/003-dt-bindings-net-add-RTL8152-binding-documentation.patch
mkdir -p target/linux/rockchip/files-5.10/arch/arm64/boot/dts/rockchip
cp -rf ../PATCH/dts/* ./target/linux/rockchip/files-5.10/arch/arm64/boot/dts/rockchip/
rm -rf ./package/boot/uboot-rockchip
svn export https://github.com/coolsnowwolf/lede/trunk/package/boot/uboot-rockchip package/boot/uboot-rockchip
sed -i '/r2c-rk3328:arm-trusted/d' package/boot/uboot-rockchip/Makefile
svn export https://github.com/coolsnowwolf/lede/trunk/package/boot/arm-trusted-firmware-rockchip-vendor package/boot/arm-trusted-firmware-rockchip-vendor
rm -rf ./package/kernel/linux/modules/video.mk
wget -P package/kernel/linux/modules/ https://github.com/immortalwrt/immortalwrt/raw/master/package/kernel/linux/modules/video.mk
echo '
# CONFIG_SHORTCUT_FE is not set
# CONFIG_PHY_ROCKCHIP_NANENG_COMBO_PHY is not set
# CONFIG_PHY_ROCKCHIP_SNPS_PCIE3 is not set
' >>./target/linux/rockchip/armv8/config-5.10

## Extra Packages
# AutoCore
svn export -r 219750 https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/lean/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/lean/autocore/files/generic/luci-mod-status-autocore.json
sed -i '/"$threads"/d' package/lean/autocore/files/x86/autocore
rm -rf ./feeds/packages/utils/coremark
svn export https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
# Autoreboot
svn export https://github.com/immortalwrt/luci/trunk/applications/luci-app-autoreboot feeds/luci/applications/luci-app-autoreboot
ln -sf ../../../feeds/luci/applications/luci-app-autoreboot ./package/feeds/luci/luci-app-autoreboot
# Dnsmasq
git clone -b mine --depth 1 https://git.openwrt.org/openwrt/staging/ldir.git
rm -rf ./package/network/services/dnsmasq
cp -rf ./ldir/package/network/services/dnsmasq ./package/network/services/
# MiniUPNP
rm -rf ./feeds/packages/net/miniupnpd
svn export https://github.com/openwrt/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/785bbcb.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/d811cb4.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/9a2da85.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/71dc090.patch | patch -p1
popd
sed -i '/firewall4.include/d' feeds/packages/net/miniupnpd/Makefile
rm -rf ./feeds/luci/applications/luci-app-upnp
svn export https://github.com/openwrt/luci/trunk/applications/luci-app-upnp feeds/luci/applications/luci-app-upnp
pushd feeds/luci
wget -qO- https://github.com/openwrt/luci/commit/0b5fb915.patch | patch -p1
popd
# NIC drivers update
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/kernel/r8152 package/new/r8152
svn export https://github.com/coolsnowwolf/lede/trunk/package/lean/r8125 package/new/r8125
svn export https://github.com/coolsnowwolf/lede/trunk/package/lean/igb-intel package/new/igb-intel
# Ram-free
svn export https://github.com/immortalwrt/luci/trunk/applications/luci-app-ramfree feeds/luci/applications/luci-app-ramfree
ln -sf ../../../feeds/luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/script/fuck package/base-files/files/usr/bin/fuck
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Remove config
rm -rf .config
