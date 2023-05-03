#!/bin/sh

geoip_url="https://ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
geoip_path="/tmp/geoip.dat"
geosite_url="https://ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
geosite_path="/tmp/geosite.dat"

wget -O $geoip_path $geoip_url
wget -O $geosite_path $geosite_url

mkdir -p /usr/share/dae

if [ -f $geoip_path ]; then
    mv $geoip_path /usr/share/dae/geoip.dat
else
    echo "GeoIP download failed, use original file"
fi

if [ -f $geosite_path ]; then
    mv $geosite_path /usr/share/dae/geosite.dat
else
    echo "GeoSite download failed, use original file"
fi

chmod 755 /usr/share/dae/geoip.dat
chmod 755 /usr/share/dae/geosite.dat

exit 0
