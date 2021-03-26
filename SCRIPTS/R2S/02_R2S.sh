#!/bin/bash
clear

## Custom-made
# GCC CFlags for R2S
sed -i 's/Os/O3/g' include/target.mk
sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mabi=lp64,g' include/target.mk
# Mbedtls AES HW-Crypto
cp -f ../PATCH/new/package/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch ./package/libs/mbedtls/patches/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch
# DMC
patch -p1 < ../PATCH/new/dmc/0001-dmc-rk3328.patch
cp -f ../PATCH/new/dmc/803-PM-devfreq-rockchip-add-devfreq-driver-for-rk3328-dmc.patch ./target/linux/rockchip/patches-5.4/803-PM-devfreq-rockchip-add-devfreq-driver-for-rk3328-dmc.patch
cp -f ../PATCH/new/dmc/804-clk-rockchip-support-setting-ddr-clock-via-SIP-Version-2-.patch ./target/linux/rockchip/patches-5.4/804-clk-rockchip-support-setting-ddr-clock-via-SIP-Version-2-.patch
cp -f ../PATCH/new/dmc/805-PM-devfreq-rockchip-dfi-add-more-soc-support.patch ./target/linux/rockchip/patches-5.4/805-PM-devfreq-rockchip-dfi-add-more-soc-support.patch
cp -f ../PATCH/new/dmc/806-arm64-dts-rockchip-rk3328-add-dfi-node.patch ./target/linux/rockchip/patches-5.4/806-arm64-dts-rockchip-rk3328-add-dfi-node.patch
cp -f ../PATCH/new/dmc/807-arm64-dts-nanopi-r2s-add-rk3328-dmc-relate-node.patch ./target/linux/rockchip/patches-5.4/807-arm64-dts-nanopi-r2s-add-rk3328-dmc-relate-node.patch
# 3328 Add idle
cp -f ../PATCH/new/main/007-arm64-dts-rockchip-Add-RK3328-idle-state.patch ./target/linux/rockchip/patches-5.4/007-arm64-dts-rockchip-Add-RK3328-idle-state.patch
# Patch to adjust kernel dma coherent-pool size
cp -f ../PATCH/new/main/911-kernel-dma-adjust-default-coherent_pool-to-2MiB.patch ./target/linux/rockchip/patches-5.4/911-kernel-dma-adjust-default-coherent_pool-to-2MiB.patch
# Overclock or not
cp -f ../PATCH/new/overclock/999-rk3328-enable-1512mhz-and-minimum-at-816mhz.patch ./target/linux/rockchip/patches-5.4/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
#cp -f ../PATCH/new/overclock/999-rk3328-enable-1608mhz-and-minimum-at-816mhz.patch ./target/linux/rockchip/patches-5.4/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
# Patch i2c0
cp -f ../PATCH/new/main/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch
# Swap LAN & WAN
#patch -p1 < ../PATCH/new/custom/0003-target-rockchip-swap-nanopi-r2s-lan-wan-port.patch
# IRQ and disabed rk3328 ethernet tcp/udp offloading tx/rx
patch -p1 < ../PATCH/new/main/0002-IRQ-and-disable-eth0-tcp-udp-offloading-tx-rx.patch
# Update r8152 driver
#svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/r8152 package/new/r8152
#sed -i '/rtl8152/d' ./target/linux/rockchip/image/armv8.mk
# Addition-Trans-zh-master
cp -rf ../PATCH/duplicate/addition-trans-zh-r2s ./package/lean/lean-translate
# Add cputemp.sh
cp -rf ../PATCH/new/script/cputemp.sh ./package/base-files/files/bin/cputemp.sh

<<'COMMENT'
#Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p |sed 's/v//g' |sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/rockchip/armv8/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
COMMENT

# Vermagic 2102 SNAPSHOT ONLY
wget https://downloads.openwrt.org/releases/21.02-SNAPSHOT/targets/rockchip/armv8/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# Crypto and Devfreq
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_ARM_PSCI_CPUIDLE_DOMAIN=y
CONFIG_ARM_PSCI_FW=y
CONFIG_ARM_RK3328_DMC_DEVFREQ=y
# CONFIG_CPU_IDLE_GOV_LADDER is not set
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20_NEON=y
# CONFIG_CRYPTO_CRCT10DIF_ARM64_CE is not set
CONFIG_CRYPTO_GHASH_ARM64_CE=y
CONFIG_CRYPTO_NHPOLY1305_NEON=y
CONFIG_CRYPTO_POLY1305_NEON=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA3_ARM64=y
CONFIG_CRYPTO_SHA512_ARM64=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SM3_ARM64_CE=y
CONFIG_CRYPTO_SM4_ARM64_CE=y
# CONFIG_MMC_TIFM_SD is not set
# CONFIG_OCTEONTX2_AF is not set
# CONFIG_PCIE_AL is not set
' >> ./target/linux/rockchip/armv8/config-5.4

exit 0
