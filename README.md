
## Notice

This repository is based on [QiuSimons/YAOF](https://github.com/QiuSimons/YAOF).  

All source code in this repository uses [GNU GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.html).  
If this repository violates your legal rights, please contact me.  

This repository is for general informational purposes only. All content in the repository is provided in good faith. However, we make no representation or warranty of any kind, express or implied,
regarding the accuracy, adequacy, validity, reliability, availability, or completeness of the repository.  

---
### Key Infomations

Login IP：192.168.1.1 

Password：None

### Version Informations

OpenWrt official v22.03.3

---
### Feature

1.Based on official OpenWrt

2.Only contain the most basic software for the stability

3.Fullcone NAT supported ( `fullcone-nat` and `fullcone-nat6`, although I think nat6 is stupid )

4.Opkg vermagic matched with OpenWrt manifest ( You can install the software as if you have AppStore~ )

5.Port some old software for the LuCI JavaScript and fix the `luci-app-upnp` by [msylgj](https://github.com/msylgj)

6.Backport [MG-LRU](https://www.phoronix.com/news/MGLRU-Performance-OpenWRT) to OpenWrt k5.10

7.Add support for phone USB hotspot sharing, both for Android and iPhone

8.Disable IPv6 by default

  * If you do need IPv6

```
uci set dhcp.lan.ra='hybrid'
uci set dhcp.lan.ndp='hybrid'
uci set dhcp.lan.dhcpv6='hybrid'
uci set dhcp.lan.ra_management='1'
uci set dhcp.@dnsmasq[0].rebind_protection='0'
uci del dhcp.@dnsmasq[0].filteraaaa
uci commit dhcp
```

#### X86_64 Feature

1.Support more NICs by default: 
```
Intel: e1000, e1000e, ixgbe, igb, igc, i40e
Broadcom: tg3
Realtek: r8125, r8169
```

#### R2S Feature

1.Fix DDR4 333MHz problem

2.Modify DTSI to support overclocked unstable devices as much as possible

3.Remove frequencies below 800MHz (same voltage) for faster response

4.Support TF card with a minimum size of 512MB

![](/Screenshots/main.jpeg)

#### R4S Feature

1.Overclock to 2208MHz/1800MHz (big.LITTLE)

2.Remove thermal throttle limit (Default at 70°C)

3.Support TF card in 1.8V signalling, fix UHS card cannot boot in 3.3V mode

---
## Thanks to everyone in ImmortalWrt and OpenWrt

* Especially Thanks
  * [QiuSimons](https://github.com/QiuSimons)
  * [ImmortalWrt](https://github.com/immortalwrt)
  * [CN_SZTL](https://github.com/1715173329)
  * [quintus-lab](https://github.com/quintus-lab)
  * [AmadeusGhost](https://github.com/AmadeusGhost)
  * [RikudouPatrickstar](https://github.com/RikudouPatrickstar)
  * [KaneGreen](https://github.com/KaneGreen)
  * [msylgj](https://github.com/msylgj)
  * [coolsnowwolf](https://github.com/coolsnowwolf)
