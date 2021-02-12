# src/Dockerfile
# ==============
# Copying
# -------
# Copyright (c) 2020 x237net/guixsd authors.
# Copyright (c) 2021 BambooGeek@PandaGix
#
# You can redistribute it and/or
# modify if under the terms of the MIT License.
# This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
# KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
# You should have received a copy of the MIT License.
# If not, see <http://opensource.org/licenses/MIT>.


# Layer 1.1: Post Build reuse ARGs
# --------------

FROM pandagix/pandagix-docker:2020.0212.1pa AS build
# AS build should be keeped for Layer 3 to copy busybox.static

ARG GUIX_PROFILE="/root/.config/guix/current"
ARG GUIX_BUILD_GRP="guixbuild"
ARG GUIX_OPTS="--verbosity=2"
ARG GUIX_IMG_NAME="guix-docker-image.tar.gz"
ARG GUIXSD_IMG_NAME="guixsd-docker-image.tar"

ARG WORK_D="/tmp"
ARG IMG_D="${WORK_D}/image"
ARG ROOT_D="${WORK_D}/root"
ARG ENTRY_D=/root
#added as 2-phase arg
ARG PREFIX_D=/usr/local
ARG PROFILE_D=/etc/profile.d
ARG INIT_D=/etc/init.d


# Layer 2: Prepare Image
# --------------
# Prepare final image
# ^^^^^^^^^^^^^^^^^^^

# Extract Docker image.
WORKDIR "${IMG_D}"
RUN tar -xzvf "${WORK_D}/${GUIX_IMG_NAME}"

# Recreate root structure by extracting each layers.
WORKDIR "${ROOT_D}"
RUN jq -r ".[0].Layers | .[]" "${IMG_D}/manifest.json" | while read _layer;     \
    do                                                                          \
        tar -xf "${IMG_D}/${_layer}" --exclude "dev/*";                         \
    done                                                                        \
    # Link special required binaries.
    && mkdir --parents usr/bin                                                  \
    && ln -s /var/guix/profiles/system/profile/bin/sh bin/sh                    \
    && ln -s /var/guix/profiles/system/profile/bin/env usr/bin/env              \
    # Set up init script.
    && echo "#!/bin/sh" > "init"                                                \
    && jq -r ".config.env | .[]" "${IMG_D}/config.json" | while read _env;      \
       do                                                                       \
           echo "export ${_env}" >> "init";                                     \
       done                                                                     \
    && echo "export GUIX_PROFILE=/var/guix/profiles/system/profile" >> "init"   \
    && echo "export PATH=\${GUIX_PROFILE}/bin:\${PATH:+:}\${PATH}" >> "init"    \
    && echo ". \${GUIX_PROFILE}/etc/profile" >> "init"                          \
    && echo "exec $(jq -r '.config.entrypoint | join(" ")' ${IMG_D}/config.json)" >> "init" \
    && chmod 0500 "init"                                                        \
    # busybox-tar step moved to Layer 3, pay attention to WORKDIR

# Final steps

WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
