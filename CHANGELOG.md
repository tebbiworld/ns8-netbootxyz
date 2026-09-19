# Changelog

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Working restore.** New `restore-module` steps re-apply every setting on the restored instance (host name and route, web login, IP allow list, proxyDHCP, UEFI mode). Before, a restored instance came up unconfigured. The PXE server address is only taken over when the node owns it.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

Secrets: nothing to move. The web password has always been a SHA-512 crypt entry in `state/htpasswd` (0600), never part of the module environment.

### Platform integration

- **Clone and move.** New `clone-module` step (a link to the restore step): a cloned or moved instance gets its route and settings back instead of coming up unconfigured. The settings are read from the source instance, including those a new instance starts with a default for.
- `org.nethserver.max-per-node=1`: the module owns fixed ports on the node, a second instance on the same node is refused at install time instead of failing at start.
- `org.nethserver.volumes`: the bulk-data volume(s) `netbootxyz-config` can be placed on an additional disk when the module is installed.
- Release notes are linked from the software centre (`relnotes_url`).

## 1.0.1 — 2026-09-14

### Fixed

- `update-module` now restarts the service, so a new upstream image (automatic releases) or a changed unit takes effect right after the update instead of at the next reboot.

