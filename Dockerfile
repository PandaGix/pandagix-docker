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

FROM pandagix/pandagix-docker:2020.0212.2pa AS build
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


# busybox-tar step moved to Layer 2.1, pay attention to WORKDIR
# Layer 2.1

WORKDIR "${ROOT_D}"

RUN /bin/busybox.static tar -cvf "${WORK_D}/${GUIXSD_IMG_NAME}" .

# Layer 3: Deploy Image
# --------------

FROM scratch

ARG ENTRY_D=/root

ENV USER="root"

# We need BusyBox in order to unpack the filesystem.
COPY --from=build "/bin/busybox.static" "/busybox"

# Deploy filesystem.
WORKDIR /
# NOT using ADD here, DO need busybox-tar
COPY --from=build "${WORK_D}/${GUIXSD_IMG_NAME}" "/root.tar"
RUN ["/busybox", "tar", "-xvf", "/root.tar"]
RUN ["/busybox", "rm", "-f", "/root.tar"]
RUN ["/busybox", "rm", "-f", "/busybox"]


# Final steps

WORKDIR "${ENTRY_D}"
ENTRYPOINT ["/init"]
