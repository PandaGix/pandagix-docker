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


# Layer 1: Build
# --------------

FROM pandagix/alpine-pandagix-docker:2021.0211.1 AS build


ARG GUIX_PROFILE="/root/.config/guix/current"
ARG GUIX_BUILD_GRP="guixbuild"
ARG GUIX_OPTS="--verbosity=2"
ARG GUIX_IMG_NAME="guix-docker-image.tar.gz"
ARG GUIXSD_IMG_NAME="guixsd-docker-image.tar"

ARG WORK_D="/tmp"
ARG IMG_D="${WORK_D}/image"
ARG ROOT_D="${WORK_D}/root"

#added as 2-phase arg
ARG PREFIX_D=/usr/local
ARG PROFILE_D=/etc/profile.d
ARG INIT_D=/etc/init.d
ARG ENTRY_D=/root


# Alpine Package requirements
# ^^^^^^^^^^^^^^^^^^^^

RUN apk add --no-cache busybox-static jq


# Build GuixSD Docker Image
# ^^^^^^^^^^^^^^^^^^^^^^^^^

ENV USER="root"

COPY scripts/channels.scm "${GUIX_CONFIG}/channels.scm"
COPY scripts/system.scm "${WORK_D}/system.scm"

# since pandagix/alpine-pandagix-docker:2021.0211.1 is used,
# guix pull is NOT needed, hash guix is needed.

RUN source "${GUIX_PROFILE}/etc/profile" \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    && hash guix \
    && "${GUIX_PROFILE}/bin/guix" --version \
    && "${GUIX_PROFILE}/bin/guix" describe \
    && "${GUIX_PROFILE}/bin/guix" gc \
    && "${GUIX_PROFILE}/bin/guix" pull \
    && "${GUIX_PROFILE}/bin/guix" package ${GUIX_OPTS} --upgrade \
    && cp -a "$(${GUIX_PROFILE}/bin/guix system docker-image ${GUIX_OPTS} ${WORK_D}/system.scm)" \
             "${WORK_D}/${GUIX_IMG_NAME}"


# Final steps

WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
