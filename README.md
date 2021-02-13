
## Notice

This repository is based on [QiuSimons/R2S-R4S-X86-OpenWrt](https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt).  
All source code in this repository uses [GNU GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.html).  
If your rights are violated by this repository, please contact me.  
This repository is for general informational purposes only. All content in the repository is provided in good faith. However, we make no representation or warranty of any kind, express or implied,
regarding the accuracy, adequacy, validity, reliability, availability, or completeness of the repository.  

### Key Infomations

Login IP：192.168.1.1 

Password：None

### Version Informations

The Latest Edition of Snapshot OpenWrt or OpenWrt v19.07

LuCI version：LuCI master or LuCI 19.07

Doge contains JD-DailyBonus

[BingBing](https://weibo.com/u/6512991534) contains nothing

Null means "No Services"

### Feature

1.Stability first

2.Only the most basic softwares

3.SFE supported

4.Fullcone NAT supported

5.Port some old softwares for the LuCI master by [msylgj](https://github.com/msylgj)

6.Remove IPv6 by default

  * If you do need IPv6

```
uci set dhcp.lan.ra='hybrid'
uci set dhcp.lan.ndp='hybrid'
uci set dhcp.lan.dhcpv6='hybrid'
uci set dhcp.lan.ra_management='1'
uci del dhcp.@dnsmasq[0].rebind_protection='1'
uci commit dhcp
```

![](/Screenshots/main.jpeg)

## Thanks to all friends in NanoPi R2S Club

* Especially Thanks
  * [QiuSimons](https://github.com/QiuSimons)
  * [ImmortalWrt](https://github.com/immortalwrt)
  * [CN_SZTL](https://github.com/1715173329)
  * [quintus-lab](https://github.com/quintus-lab)
  * [RikudouPatrickstar](https://github.com/RikudouPatrickstar)
  * [KaneGreen](https://github.com/KaneGreen)
  * [msylgj](https://github.com/msylgj)
