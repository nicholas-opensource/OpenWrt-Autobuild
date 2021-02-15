#!/bin/bash
clear

notExce(){ 
# Blocktrron.git 
patch -p1 < ../PATCH/new/main/exp/uboot-rockchip-update-to-v2020.10.patch
patch -p1 < ../PATCH/new/main/exp/rockchip-fix-NanoPi-R2S-GMAC-clock-name.patch
# Kernel
cp -f ../PATCH/new/main/xanmod_5.4.patch ./target/linux/generic/hack-5.4/000-xanmod_5.4.patch
wget -q https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/3580.patch
patch -p1 < ./3580.patch
# RT Kernel
cp -f ../PATCH/new/main/999-patch-5.4.61-rt37.patch ./target/linux/generic/hack-5.4/999-patch-5.4.61-rt37.patch
sed -i '/PREEMPT/d' ./target/linux/rockchip/armv8/config-5.4
echo '
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPTION=y
' >> ./target/linux/rockchip/armv8/config-5.4
sed -i '/PREEMPT/d' ./target/linux/rockchip/config-default
echo '
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPTION=y
' >> ./target/linux/rockchip/config-default
# HW-RNG
patch -p1 < ../PATCH/new/main/Support-hardware-random-number-generator-for-RK3328.patch
sed -i 's/-f/-f -i/g' feeds/packages/utils/rng-tools/files/rngd.init
echo '
CONFIG_CRYPTO_DRBG=y
CONFIG_CRYPTO_DRBG_HMAC=y
CONFIG_CRYPTO_DRBG_MENU=y
CONFIG_CRYPTO_JITTERENTROPY=y
CONFIG_CRYPTO_RNG=y
CONFIG_CRYPTO_RNG2=y
CONFIG_CRYPTO_RNG_DEFAULT=y
' >> ./target/linux/rockchip/armv8/config-5.4
}

## Prepare
# Use feed sources of Branch 19.07
rm -f ./feeds.conf.default
wget https://github.com/nicholas-opensource/openwrt/raw/openwrt-19.07/feeds.conf.default
wget -P include/ https://github.com/openwrt/openwrt/raw/openwrt-19.07/include/scons.mk
patch -p1 < ../PATCH/new/main/0001-tools-add-upx-ucl-support.patch
# Remove annoying snapshot tag
sed -i 's,SNAPSHOT,,g' include/version.mk
sed -i 's,snapshots,,g' package/base-files/image-config.in
# GCC CFLAGS
sed -i 's/Os/O2/g' include/target.mk
sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53,g' include/target.mk
#sed -i 's/O2/O2/g' ./rules.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a

## Custom-made
# 3328 Add idle
wget -P target/linux/rockchip/patches-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/rockchip/patches-5.4/007-arm64-dts-rockchip-Add-RK3328-idle-state.patch
wget -P target/linux/generic/pending-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/pending-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# IRQ
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 8 "ff160000" "ff160000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 1 "ff150000" "ff150000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# Disabed rk3328 ethernet tcp/udp offloading tx/rx
sed -i '/;;/i\ethtool -K eth0 rx off tx off && logger -t disable-offloading "disabed rk3328 ethernet tcp/udp offloading tx/rx"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# Update r8152 driver
#wget -O- https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/3178.patch | patch -p1
#wget -O- https://github.com/immortalwrt/immortalwrt/commit/d8df86130d172b3ce262d2744e2ddd2a6eed5f50.patch | patch -p1
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/r8152 package/new/r8152
sed -i '/rtl8152/d' ./target/linux/rockchip/image/armv8.mk
# Overclock or not
cp -f ../PATCH/new/main/999-RK3328-enable-1512mhz-opp.patch ./target/linux/rockchip/patches-5.4/999-RK3328-enable-1512mhz-opp.patch
#cp -f ../PATCH/new/main/999-unlock-1608mhz-rk3328.patch ./target/linux/rockchip/patches-5.4/999-unlock-1608mhz-rk3328.patch
# Swap LAN & WAN
#patch -p1 < ../PATCH/new/main/0001-target-rockchip-swap-nanopi-r2s-lan-wan-port.patch

## Important Patches
# Minor Changes
sed -i '/CONFIG_SLUB/d' ./target/linux/rockchip/armv8/config-5.4
sed -i '/CONFIG_PROC_[^V].*/d' ./target/linux/rockchip/armv8/config-5.4
# Patch i2c0
#cp -f ../PATCH/new/main/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch
# LuCI network
#patch -p1 < ../PATCH/new/main/luci_network-add-packet-steering.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget -P package/base-files/files/etc/init.d https://github.com/immortalwrt/immortalwrt/raw/openwrt-18.06-k5.4/package/base-files/files/etc/init.d/boot

# Revert to FW3
#rm -rf ./package/network/config/firewall
#svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/config/firewall package/network/config/firewall
# Patch kernel to fix fullcone conflict
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch firewall to enable fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
#wget -P package/network/config/firewall/patches/ https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/fullconenat.patch
# Patch LuCI to add fullcone button
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
#pushd feeds/luci
#wget -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
#popd
# FullCone modules
cp -rf ../PATCH/duplicate/fullconenat ./package/network/fullconenat

# SFE core patch
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
# Patch firewall to enable SFE
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE modules
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d

## Change Packages
# Change Cryptodev-linux
rm -rf ./package/kernel/cryptodev-linux
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/kernel/cryptodev-linux package/kernel/cryptodev-linux
# Change Htop
rm -rf ./feeds/packages/admin/htop
svn co https://github.com/openwrt/packages/trunk/admin/htop feeds/packages/admin/htop
# Change Lzo
svn co https://github.com/openwrt/packages/trunk/libs/lzo feeds/packages/libs/lzo
ln -sf ../../../feeds/packages/libs/lzo ./package/feeds/packages/lzo
# Change Curl
rm -rf ./package/network/utils/curl
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/utils/curl package/network/utils/curl
# Change Node
rm -rf ./feeds/packages/lang/node
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
rm -rf ./feeds/packages/lang/node-arduino-firmata
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
rm -rf ./feeds/packages/lang/node-cylon
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
rm -rf ./feeds/packages/lang/node-hid
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
rm -rf ./feeds/packages/lang/node-homebridge
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
rm -rf ./feeds/packages/lang/node-serialport
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
rm -rf ./feeds/packages/lang/node-serialport-bindings
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
# Change libcap
rm -rf ./feeds/packages/libs/libcap/
svn co https://github.com/openwrt/packages/trunk/libs/libcap feeds/packages/libs/libcap
# Change GCC
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc feeds/packages/devel/gcc
# Change Golang
rm -rf ./feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang
# Change Ruby
rm -rf ./feeds/packages/lang/ruby
svn co https://github.com/openwrt/packages/trunk/lang/ruby feeds/packages/lang/ruby

## Extra Packages
# Python
svn co https://github.com/openwrt/packages/trunk/lang/python/python-cached-property feeds/packages/lang/python/python-cached-property
ln -sf ../../../feeds/packages/lang/python/python-cached-property ./package/feeds/packages/python-cached-property
svn co https://github.com/openwrt/packages/trunk/lang/python/python-distro feeds/packages/lang/python/python-distro
ln -sf ../../../feeds/packages/lang/python/python-distro ./package/feeds/packages/python-distro
svn co https://github.com/openwrt/packages/trunk/lang/python/python-docopt feeds/packages/lang/python/python-docopt
ln -sf ../../../feeds/packages/lang/python/python-docopt ./package/feeds/packages/python-docopt
svn co https://github.com/openwrt/packages/trunk/lang/python/python-docker feeds/packages/lang/python/python-docker
ln -sf ../../../feeds/packages/lang/python/python-docker ./package/feeds/packages/python-docker
svn co https://github.com/openwrt/packages/trunk/lang/python/python-dockerpty feeds/packages/lang/python/python-dockerpty
ln -sf ../../../feeds/packages/lang/python/python-dockerpty ./package/feeds/packages/python-dockerpty
svn co https://github.com/openwrt/packages/trunk/lang/python/python-dotenv feeds/packages/lang/python/python-dotenv
ln -sf ../../../feeds/packages/lang/python/python-dotenv ./package/feeds/packages/python-dotenv
svn co https://github.com/openwrt/packages/trunk/lang/python/python-jsonschema feeds/packages/lang/python/python-jsonschema
ln -sf ../../../feeds/packages/lang/python/python-jsonschema ./package/feeds/packages/python-jsonschema
svn co https://github.com/openwrt/packages/trunk/lang/python/python-texttable feeds/packages/lang/python/python-texttable
ln -sf ../../../feeds/packages/lang/python/python-texttable ./package/feeds/packages/python-texttable
svn co https://github.com/openwrt/packages/trunk/lang/python/python-websocket-client feeds/packages/lang/python/python-websocket-client
ln -sf ../../../feeds/packages/lang/python/python-websocket-client ./package/feeds/packages/python-websocket-client
svn co https://github.com/openwrt/packages/trunk/lang/python/python-paramiko feeds/packages/lang/python/python-paramiko
ln -sf ../../../feeds/packages/lang/python/python-paramiko ./package/feeds/packages/python-paramiko
svn co https://github.com/openwrt/packages/trunk/lang/python/python-pynacl feeds/packages/lang/python/python-pynacl
ln -sf ../../../feeds/packages/lang/python/python-pynacl ./package/feeds/packages/python-pynacl
# JD-DailyBonus
git clone --depth 1 https://github.com/jerrykuku/node-request.git package/new/node-request
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus
#git clone -b develop --depth 1 https://github.com/Promix953/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus
# Arpbind
svn co https://github.com/nicholas-opensource/OpenWrt_luci-app/trunk/lean/luci-app-arpbind package/lean/luci-app-arpbind
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind package/lean/luci-app-arpbind
# AutoCore
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
ln -sf ../../../feeds/packages/utils/coremark ./package/feeds/packages/coremark
sed -i 's,default n,default y,g' feeds/packages/utils/coremark/Makefile
# Add iftop
rm -rf ./package/network/utils/iftop ./feeds/packages/net/iftop
svn co https://github.com/openwrt/packages/trunk/net/iftop feeds/packages/net/iftop
ln -sdf ../../../feeds/packages/net/iftop ./package/feeds/packages/iftop
# Add iperf3
rm -rf ./package/network/utils/iperf3 ./feeds/packages/net/iperf3
svn co https://github.com/openwrt/packages/trunk/net/iperf3 feeds/packages/net/iperf3
ln -sdf ../../../feeds/packages/net/iperf3 ./package/feeds/packages/iperf3
# Stress-ng
svn co https://github.com/openwrt/packages/trunk/utils/stress-ng feeds/packages/utils/stress-ng
ln -sf ../../../feeds/packages/utils/stress-ng ./package/feeds/packages/stress-ng
# Autoreboot
svn co https://github.com/nicholas-opensource/OpenWrt_luci-app/trunk/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
#svn co https://github.com/Mattraks/helloworld/branches/Preview/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/po/zh_Hans
#svn co https://github.com/nicholas-opensource/Others/trunk/luci-app-ssr-plus-181 package/lean/luci-app-ssr-plus
#sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
#sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
# Add Extra Proxy Ports and Change Lists
pushd package/lean/luci-app-ssr-plus/root/etc/init.d
sed -i 's/143/143,25,5222/' shadowsocksr
sed -i 's,ispip.clang.cn/all_cn,cdn.jsdelivr.net/gh/QiuSimons/Chnroute/dist/chnroute/chnroute,' shadowsocksr
sed -i 's,YW5vbnltb3Vz/domain-list-community@release/gfwlist,Loyalsoldier/v2ray-rules-dat@release/gfw,' shadowsocksr
popd
#rm -rf ./package/lean/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
#wget -P package/lean/luci-app-ssr-plus/root/etc/init.d https://raw.githubusercontent.com/nicholas-opensource/Others/master/luci-app-ssr-plus-177-1/root/etc/init.d/shadowsocksr
# SSRP Dependies
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray package/lean/v2ray
svn co https://github.com/fw876/helloworld/trunk/xray-core package/lean/xray-core
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
#svn co https://github.com/fw876/helloworld/trunk/trojan-go package/lean/trojan-go
#svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/tcpping package/lean/tcpping
svn co https://github.com/fw876/helloworld/trunk/tcping package/lean/tcping
svn co https://github.com/fw876/helloworld/trunk/naiveproxy package/lean/naiveproxy
#svn co https://github.com/fw876/helloworld/trunk/ipt2socks-alt package/lean/ipt2socks-alt
# Merge Pull Requests from Mattraks
#pushd package/lean
#wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/271.patch | patch -p1
#popd
# Ram-free
svn co https://github.com/nicholas-opensource/OpenWrt_luci-app/trunk/lean/luci-app-ramfree package/lean/luci-app-ramfree
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
# Extra Dependies (May not be used)
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-log package/libs/libnetfilter-log
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-queue package/libs/libnetfilter-queue
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cttimeout package/libs/libnetfilter-cttimeout
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cthelper package/libs/libnetfilter-cthelper
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/services/samba36 package/network/services/samba36
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libusb-compat package/libs/libusb-compat
svn co https://github.com/openwrt/packages/trunk/libs/nghttp2 feeds/packages/libs/nghttp2
ln -sf ../../../feeds/packages/libs/nghttp2 ./package/feeds/packages/nghttp2
svn co https://github.com/openwrt/packages/trunk/libs/libcap-ng feeds/packages/libs/libcap-ng
ln -sf ../../../feeds/packages/libs/libcap-ng ./package/feeds/packages/libcap-ng
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/usbutils feeds/packages/utils/usbutils
ln -sf ../../../feeds/packages/utils/usbutils ./package/feeds/packages/usbutils
svn co https://github.com/openwrt/packages/trunk/utils/hwdata feeds/packages/utils/hwdata
ln -sf ../../../feeds/packages/utils/hwdata ./package/feeds/packages/hwdata
rm -rf ./feeds/packages/net/dnsdist
svn co https://github.com/openwrt/packages/trunk/net/dnsdist feeds/packages/net/dnsdist
svn co https://github.com/openwrt/packages/trunk/libs/h2o feeds/packages/libs/h2o
ln -sf ../../../feeds/packages/libs/h2o ./package/feeds/packages/h2o
svn co https://github.com/openwrt/packages/trunk/libs/libwslay feeds/packages/libs/libwslay
ln -sf ../../../feeds/packages/libs/libwslay ./package/feeds/packages/libwslay
# Addition-Trans-zh-master
cp -rf ../PATCH/duplicate/addition-trans-zh-r2s ./package/lean/lean-translate
# Addition-Trans-zh-master from QiuSimons with individuation changes
notExce(){
MY_Var=package/lean/lean-translate
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh ${MY_Var}
sed -i '/uci .* dhcp/d' ${MY_Var}/files/zzz-default-settings
sed -i '/chinadnslist\|ddns\|upnp\|netease\|argon\|openwrt_luci\|rng\|openclash\|dockerman/d' ${MY_Var}/files/zzz-default-settings
sed -i "4a uci set luci.main.lang='en'" ${MY_Var}/files/zzz-default-settings
sed -i '5a uci commit luci' ${MY_Var}/files/zzz-default-settings
sed -i '/^[[:space:]]*$/d' ${MY_Var}/files/zzz-default-settings
unset MY_Var
}

# Crypto
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20=y
CONFIG_CRYPTO_CHACHA20_NEON=y
CONFIG_CRYPTO_CRYPTD=y
CONFIG_CRYPTO_GF128MUL=y
CONFIG_CRYPTO_GHASH_ARM64_CE=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
# CONFIG_CRYPTO_SHA3_ARM64 is not set
CONFIG_CRYPTO_SHA512_ARM64=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SIMD=y
# CONFIG_CRYPTO_SM3_ARM64_CE is not set
# CONFIG_CRYPTO_SM4_ARM64_CE is not set
' >> ./target/linux/rockchip/armv8/config-5.4

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/new/script/fuck package/base-files/files/usr/bin/fuck
# Add cputemp.sh
wget https://raw.githubusercontent.com/nicholas-opensource/Others/master/cputemp.sh -O package/base-files/files/bin/cputemp.sh
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Remove config
rm -rf .config

exit 0
