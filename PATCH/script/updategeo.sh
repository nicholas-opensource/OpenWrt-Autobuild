#!/bin/sh

geoip_url="https://mirror.ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
geoip_path="/tmp/geoip.dat"
geosite_url="https://mirror.ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
geosite_path="/tmp/geosite.dat"
geoip_hash_url="https://mirror.ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat.sha256sum"
geoip_hash_path="/tmp/geoip.dat.sha256sum"
geosite_hash_url="https://mirror.ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat.sha256sum"
geosite_hash_path="/tmp/geosite.dat.sha256sum"

echo -e "\033[33mStart Downloading...... It won't take long\033[0m"
wget -qO $geoip_path $geoip_url
wget -qO $geosite_path $geosite_url
wget -qO $geoip_hash_path $geoip_hash_url
wget -qO $geosite_hash_path $geosite_hash_url

local_geoip_hash=$(sha256sum $geoip_path | awk '{print $1}')
local_geosite_hash=$(sha256sum $geosite_path | awk '{print $1}')
github_geoip_hash=$(cat $geoip_hash_path | awk '{print $1}')
github_geosite_hash=$(cat $geosite_hash_path | awk '{print $1}')

mkdir -p /etc/dae

if [ -f $geoip_path ] && [ $local_geoip_hash = $github_geoip_hash ]; then
    echo -e "\033[32mGeoIP sha256 check passed! Hash is $local_geoip_hash \033[0m"
    mv $geoip_path /etc/dae/geoip.dat
    rm $geoip_hash_path
else
    echo -e "\033[31mGeoIP download failed or sha256 mismatch, use original file\033[0m"
    echo -e "The downloaded GeoIP hash is $local_geoip_hash , should be $github_geoip_hash"
    rm $geoip_hash_path
    rm $geoip_path
fi

if [ -f $geosite_path ] && [ $local_geosite_hash = $github_geosite_hash ]; then
    echo -e "\033[32mGeoSite sha256 check passed! Hash is $local_geosite_hash \033[0m"
    mv $geosite_path /etc/dae/geosite.dat
    rm $geosite_hash_path
else
    echo -e "\033[31mGeoSite download failed or sha256 mismatch, use original file\033[0m"
    echo -e "The downloaded GeoSite hash is $local_geosite_hash , should be $github_geosite_hash"
    rm $geosite_hash_path
    rm $geosite_path
fi

chmod 640 /etc/dae/geoip.dat
chmod 640 /etc/dae/geosite.dat

exit 0
