#!/bin/bash
clear

## Prepare
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# Victoria's Secret
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
wget -P scripts/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/scripts/download.pl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/include/download.mk
sed -i '/mirror02/d' scripts/download.pl
#echo "net.netfilter.nf_conntrack_helper=1" >> ./package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/default NODEJS_ICU_SMALL/default NODEJS_ICU_NONE/g' feeds/packages/lang/node/Makefile

## Important Patches
# ARM64: Add CPU model name in proc cpuinfo
wget -P target/linux/generic/pending-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
# Patch kernel to fix fullcone conflict
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
# Patch firewall to enable fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
# Patch LuCI to add fullcone button
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
# FullCone modules
cp -rf ../PATCH/duplicate/fullconenat ./package/network/fullconenat
# SFE core patch
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
# Patch firewall to enable SFE
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE modules
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/kernel/shortcut-fe package/kernel/shortcut-fe
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/kernel/fast-classifier package/kernel/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d

## Extra Packages
# AutoCore
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/emortal/autocore
curl -fsSL https://raw.githubusercontent.com/nicholas-opensource/Others/master/add-openwrt.patch | patch -p1
rm -rf ./feeds/packages/utils/coremark
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
# Autoreboot
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-autoreboot feeds/luci/applications/luci-app-autoreboot
ln -sf ../../../feeds/luci/applications/luci-app-autoreboot ./package/feeds/luci/luci-app-autoreboot
# Ram-free
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-ramfree feeds/luci/applications/luci-app-ramfree
ln -sf ../../../feeds/luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/po/zh_Hans
# SSRP Dependies
rm -rf ./feeds/packages/net/shadowsocks-libev
rm -rf ./feeds/packages/net/xray-core
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd-alt
svn co https://github.com/fw876/helloworld/trunk/tcping package/lean/tcping
svn co https://github.com/fw876/helloworld/trunk/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/fw876/helloworld/trunk/naiveproxy package/lean/naiveproxy
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/fw876/helloworld/trunk/shadowsocks-rust package/lean/shadowsocks-rust
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
svn co https://github.com/fw876/helloworld/trunk/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/fw876/helloworld/trunk/xray-plugin package/lean/xray-plugin
svn co https://github.com/fw876/helloworld/trunk/xray-core package/lean/xray-core
#svn co https://github.com/fw876/helloworld/trunk/ipt2socks-alt package/lean/ipt2socks-alt
#svn co https://github.com/immortalwrt/packages/trunk/package/net/tcpping feeds/packages/net/tcpping
#svn co https://github.com/fw876/helloworld/trunk/trojan-go package/lean/trojan-go
#svn co https://github.com/fw876/helloworld/trunk/v2ray-core package/lean/v2ray-core
# Merge Pull Requests from developers
pushd package/lean
#wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/559.patch | patch -p1
wget -qO - https://github.com/QiuSimons/helloworld-fw876/commit/c1674ad.patch | patch -p1
popd
# Add Extra Proxy Ports and Change Lists
pushd package/lean/luci-app-ssr-plus
sed -i 's/143/143,25,5222/' root/etc/init.d/shadowsocksr
sed -i 's,ispip.clang.cn/all_cn,cdn.jsdelivr.net/gh/QiuSimons/Chnroute@master/dist/chnroute/chnroute,' root/etc/init.d/shadowsocksr
sed -i 's,ghproxy.com/https://raw.githubusercontent.com/YW5vbnltb3Vz/domain-list-community/release/gfwlist,cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw,' root/etc/init.d/shadowsocksr luasrc/model/cbi/shadowsocksr/advanced.lua
sed -i '/Clang.CN.CIDR/a\o:value("https://cdn.jsdelivr.net/gh/QiuSimons/Chnroute@master/dist/chnroute/chnroute.txt", translate("QiuSimons/Chnroute"))' luasrc/model/cbi/shadowsocksr/advanced.lua
popd

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/new/script/fuck package/base-files/files/usr/bin/fuck
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Remove config
rm -rf .config
