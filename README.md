# ns8-netbootxyz

A [NethServer 8](https://github.com/NethServer/ns8-core) module that turns a node
into a PXE network boot server running [netboot.xyz](https://netboot.xyz).
Machines on your LAN boot into a menu with installers, live systems and tools for
dozens of operating systems (Debian, Ubuntu, Fedora, Rocky, Alma, Arch, Windows
PE, Clonezilla, GParted, memtest, ...). **Everything is loaded from the internet
on demand: there are no ISO files to download or upload.**

## How it works

1. A machine starts network boot (PXE). Your DHCP server gives it an IP address;
   the boot server address and boot file come either from **proxyDHCP** on this
   node or from **DHCP options 66/67** on your router.
2. The machine loads the netboot.xyz iPXE binary from this node over TFTP.
3. netboot.xyz shows its menu and pulls kernels, initrds and images from the
   distributions' official mirrors over HTTP(S).

## Architecture

Two rootless containers from the pinned `ghcr.io/netbootxyz/netbootxyz` image,
sharing the `netbootxyz-config` volume (boot files and menus):

| Container | Network | Ports | Purpose |
| --- | --- | --- | --- |
| `netbootxyz-tftp` | host | 69/udp, optionally 67/udp + 4011/udp | dnsmasq: TFTP and proxyDHCP |
| `netbootxyz` | private | 127.0.0.1:`WEB_PORT` → 8080 | netboot.xyz web app behind nginx basic auth, fronted by Traefik |

- TFTP and proxyDHCP need the host network: TFTP transfers use ephemeral ports
  and proxyDHCP must see LAN broadcasts. NethServer lowers
  `net.ipv4.ip_unprivileged_port_start` to 23, so the rootless container can bind
  these ports. The module opens them in the node firewall.
- The netboot.xyz web app has no authentication of its own. It is never
  published directly: nginx inside the container requires the login you set on
  the Settings page, Traefik adds TLS and an optional client IP allowlist.
- On first start the image downloads the boot files and menus of the latest
  netboot.xyz release (plus the signed Secure Boot binaries from the iPXE
  project) into the volume.

## Pointing clients at the boot server

### Option A: proxyDHCP (recommended)

Enable **Answer PXE clients directly (proxyDHCP)** on the Settings page. Leave
your router's DHCP server as it is, with options 66/67 empty. The router keeps
assigning addresses; this node only adds the boot information for machines that
network boot, choosing the right file per firmware (DHCP option 93):

| Client | Boot file |
| --- | --- |
| Legacy BIOS | `netboot.xyz.kpxe` |
| UEFI x86_64 | `netboot.xyz.efi` or, in Secure Boot mode, `secureboot-x86_64/shimx64.efi` |
| UEFI ARM64 | `netboot.xyz-arm64.efi` or `secureboot-arm64/shimaa64.efi` |

Clients that already run iPXE themselves (Proxmox and QEMU virtual machines,
many server network cards) get the boot file directly in the proxyDHCP offer:
iPXE ignores the broadcast reply of the PXE boot server exchange on port 4011,
so the menu path never completes for them.

Every machine in that network that tries PXE boot gets the netboot.xyz menu, so
do not run a second PXE server in the same network.

### Option B: DHCP options on the router

Keep proxyDHCP off and set on your DHCP server:

- **Option 66** (TFTP server name): the boot server address, e.g. `192.168.1.10`
- **Option 67** (boot file name): `netboot.xyz.efi` for UEFI machines, or
  `netboot.xyz.kpxe` for legacy BIOS machines

On a **DrayTek Vigor** router: *LAN » General Setup »* select the LAN, then
*DHCP Server Option*: add option 66 and option 67 as ASCII strings. Most
routers, including DrayTek, send one boot file to every client, so mixed BIOS
and UEFI networks work best with proxyDHCP.

## Settings

- **Boot server address**: the node address clients load the boot files from.
  Pick a static address: a DHCP lease can change on reboot and silently break
  network boot.
- **UEFI boot mode**: *Standard* serves the netboot.xyz iPXE binary (Secure Boot
  must be disabled on the clients). *Secure Boot compatible* serves the
  Microsoft-signed shim and the iPXE-signed binaries; its menus are loaded from
  `boot.netboot.xyz`. Some firmware requires allowing the "Microsoft 3rd party
  UEFI CA" for this.
- **Menu editor** (optional): host name, login and allowed client networks for
  the web app. Leave the host name empty if you do not need it.

## Where netboot.xyz loads its menus from

Once the netboot.xyz binary runs, it looks for local menus on the TFTP server
your **DHCP server** announced (`next-server`), not necessarily on this node:

- If your DHCP server announces no TFTP server (common on home routers),
  netboot.xyz loads its menus from `boot.netboot.xyz` over HTTPS.
- If it announces itself, netboot.xyz tries there first, runs into a few
  timeouts and then falls back to the internet. Press **`p`** at the
  "DHCP proxy detected" prompt to use this node instead.

Either way the operating system images come from the internet. The local menus
only matter if you customize them in the web app.

## Limitations

- **One instance per node**: TFTP (69/udp) and proxyDHCP bind fixed ports in the
  host network, so a second instance on the same node cannot start.
- The web app can mirror boot assets locally, but this module does not publish
  them over HTTP; boot images are always loaded from the internet. Clients need
  internet access.
- Secure Boot mode needs firmware that trusts the Microsoft 3rd party UEFI CA,
  and it always loads its menus from `boot.netboot.xyz`.
- IPv4 only.

## Install

```
add-module ghcr.io/tebbiworld/netbootxyz:latest 1
```

## Uninstall

```
remove-module --no-preserve netbootxyz1
```

## Credits

[netboot.xyz](https://github.com/netbootxyz/netboot.xyz) and its
[container image](https://github.com/netbootxyz/docker-netbootxyz) are
Apache-2.0 licensed. Secure Boot binaries come unmodified from the
[iPXE project](https://github.com/ipxe/ipxe/releases).
