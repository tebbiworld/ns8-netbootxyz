<!--
First community post for the NS8 netboot.xyz module, written in the style
of https://community.nethserver.org/t/ns8-forgejo-testing/28554 (first post).
Paste into a new topic on community.nethserver.org, category "App", tag "ns8".
Fill in the wiki link once the page is published.
-->

# NS8 netboot.xyz (testing)

Hi all,

I've built an NS8 module for [netboot.xyz](https://netboot.xyz) — it turns a node into a PXE network-boot server, so machines on your LAN boot into a menu of installers, live systems and tools for dozens of operating systems.

It's in my community repository. To try it, add the repo once:

```
api-cli run add-repository --data '{"name":"tebbiworld","url":"https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/","status":true,"testing":false}'
```

then install **netboot.xyz** from the Software Center. (Or straight from the image: `add-module ghcr.io/tebbiworld/netbootxyz:latest 1`.)

What it does:

* Boots LAN machines into the netboot.xyz menu — Debian, Ubuntu, Fedora, Rocky, Alma, Arch, Clonezilla, GParted, memtest and more. Kernels, initrds and images are fetched from the internet on demand, so there are no ISO files to download or upload.
* Points clients at the boot server either with **proxyDHCP** (leave your router's DHCP alone; the node just adds the boot info and picks the right file per firmware) or with classic DHCP options 66/67.
* Runs the pinned `ghcr.io/netbootxyz/netbootxyz` image as two rootless containers, so the menu web app does not sit in the host network.
* Puts an nginx basic-auth login in front of the menu web app (which has none of its own) and publishes it through Traefik with TLS and an optional client-network allowlist.
* Offers a Secure Boot compatible mode that serves the Microsoft-signed shim and the iPXE-signed binaries, plus firewall openings and backup of the config volume.

A few things to know:

* TFTP and proxyDHCP need the host network, and dnsmasq needs `NET_ADMIN` + `NET_RAW` (rootless, these apply only inside the module's namespace). One instance per node, and only one PXE server may answer in a given network.
* Clients need internet access — the operating-system images always come from the internet. IPv4 only.
* With DHCP options 66/67, most routers send the *same* boot file to every client, so a BIOS machine handed `netboot.xyz.efi` aborts with "exec format error" — for mixed BIOS/UEFI networks, prefer proxyDHCP. On a DrayTek Vigor the options go under *LAN » General Setup » DHCP Server Option* as ASCII strings.
* Secure Boot mode needs firmware that trusts the "Microsoft 3rd party UEFI CA" and always loads its menus from `boot.netboot.xyz`.

If you give it a spin, I'd love to hear how it behaves with your router and firmware — especially any proxyDHCP or Secure Boot quirks I should document.

Docs: NethServer wiki (tebbiworld repository) · Source: [github.com/tebbiworld/ns8-netbootxyz](https://github.com/tebbiworld/ns8-netbootxyz)

Thanks!

*Category: App · Tags: ns8*
