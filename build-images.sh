#!/bin/bash

#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

images=()
repobase="${REPOBASE:-ghcr.io/tebbiworld}"
reponame="netbootxyz"

# Runtime image pinned by the module through the org.nethserver.images label so
# the node pre-pulls it and exposes its reference to the systemd units:
#   ghcr.io/netbootxyz/netbootxyz:... -> ${NETBOOTXYZ_IMAGE}
#
# Pinned to a fixed upstream release (not :latest) so every install runs the
# same TFTP server, web app and init logic. The netboot.xyz boot menus
# themselves are downloaded from the netboot.xyz GitHub releases at first start
# and can be upgraded from the web app.
netbootxyz_image="ghcr.io/netbootxyz/netbootxyz:0.7.6-nbxyz24"

runtime_images=(
    "${netbootxyz_image}"
)

container=$(buildah from scratch)

# Reuse an existing nodebuilder container to speed up UI rebuilds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-netbootxyz; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-netbootxyz -v "${PWD}:/usr/src:Z" docker.io/library/node:24.16.0-slim
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-netbootxyz \
    sh -c "yarn install && yarn build"

buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# One TCP port on the node loopback for the (password protected) netboot.xyz
# web app, fronted by Traefik. TFTP (69/udp) and the optional proxyDHCP service
# (67/udp, 4011/udp) run in the host network namespace and are opened in the
# node firewall by configure-module, hence node:fwadm.
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm node:fwadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${runtime_images[*]}" \
    "${container}"
buildah commit "${container}" "${repobase}/${reponame}"

images+=("${repobase}/${reponame}")

if [[ -n "${CI}" ]]; then
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
