#!/bin/bash
clear

## Prepare
# GCC CFLAGS
sed -i 's/Os/O2/g' include/target.mk
sed -i 's/O2/O2/g' ./rules.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# IRQ
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config

## Important Patches
# LuCI network
patch -p1 < ../PATCH/new/main/luci_network-add-packet-steering.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq
rm -rf ./package/network/services/dnsmasq
svn co https://github.com/openwrt/openwrt/trunk/package/network/services/dnsmasq package/network/services/dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget -P package/base-files/files/etc/init.d https://github.com/immortalwrt/immortalwrt/raw/openwrt-18.06-k5.4/package/base-files/files/etc/init.d/boot

# Patch kernel to fix fullcone conflict
wget -P target/linux/generic/hack-4.14/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-4.14/952-net-conntrack-events-support-multiple-registrant.patch
wget -P target/linux/generic/hack-4.14/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-4.14/202-reduce_module_size.patch
wget -P target/linux/x86/patches-4.14/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/x86/patches-4.14/900-x86-Enable-fast-strings-on-Intel-if-BIOS-hasn-t-already.patch
# Patch firewall to enable fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
# Patch LuCI to add fullcone button
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
#pushd feeds/luci
#wget -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
#popd
# FullCone modules
cp -rf ../PATCH/duplicate/fullconenat ./package/network/fullconenat

# SFE core patch
wget -P target/linux/generic/hack-4.14/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-4.14/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
# Patch firewall to enable SFE
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE modules
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d
# BBR Patch 2.0
wget -P target/linux/generic/pending-4.14/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-18.06/target/linux/generic/pending-4.14/607-tcp_bbr-adapt-cwnd-based-on-ack-aggregation-estimation.patch

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
#AutoCore
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
ln -sf ../../../feeds/packages/utils/coremark ./package/feeds/packages/coremark
sed -i 's,default n,default y,g' feeds/packages/utils/coremark/Makefile
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
cp -rf ../PATCH/duplicate/addition-trans-zh-x86 ./package/lean/lean-translate

## Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+.tar.gz" |sed -n '/19/p' |sed -n 1p |sed 's/v//g' |sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/x86/64/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/new/script/fuck package/base-files/files/usr/bin/fuck
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Change Startup
sed -i 's/default "5"/default "0"/g' config/Config-images.in
# Remove config
rm -rf .config

exit 0
