# Layer 1: Build
# --------------

#FROM alpine:3.12.3 AS build
FROM pandagix/alpine-pandagix-docker:2021.0219 AS build


ARG GUIX_PROFILE="/root/.config/guix/current"
ARG GUIX_BUILD_GRP="guixbuild"
ARG GUIX_OPTS="--verbosity=2"
ARG GUIX_IMG_NAME="guix-docker-image.tar.gz"
ARG GUIXSD_IMG_NAME="guixsd-docker-image.tar"

ARG WORK_D="/tmp"
ARG IMG_D="${WORK_D}/image"
ARG ROOT_D="${WORK_D}/root"

#added as 3-phase arg
ARG PREFIX_D=/usr/local
ARG PROFILE_D=/etc/profile.d
ARG INIT_D=/etc/init.d
ARG ENTRY_D=/root

#added to resolve guix substitute problem on nss-certs 
ARG LC_ALL=en_US.utf8


# Alpine Package requirements
# ^^^^^^^^^^^^^^^^^^^^

#RUN apk add --no-cache ca-certificates openrc wget git
#already in pandagix/alpine-pandagix-docker:279889
RUN apk add --no-cache busybox-static jq tar


# Build GuixSD Docker Image
# ^^^^^^^^^^^^^^^^^^^^^^^^^

ENV USER="root"

COPY scripts/channels-a20210219.scm "${GUIX_CONFIG}/channels.scm"
COPY scripts/pandagixdocker-a20210219.scm "${WORK_D}/system.scm"

# since pandagix/alpine-pandagix-docker:2021.0219 is used,
# guix pull is NOT needed, hash guix is needed.

RUN source "${GUIX_PROFILE}/etc/profile" \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    && hash guix \
    && "${GUIX_PROFILE}/bin/guix" --version \
    && "${GUIX_PROFILE}/bin/guix" describe \
    && "${GUIX_PROFILE}/bin/guix" gc \
    #&& "${GUIX_PROFILE}/bin/guix" pull --allow-downgrades \
    && "${GUIX_PROFILE}/bin/guix" package ${GUIX_OPTS} --upgrade \
    && "${GUIX_PROFILE}/bin/guix" install --fallback glibc-utf8-locales \
    #&& "${GUIX_PROFILE}/bin/guix" install --fallback glibc-locales \
    && hash guix \
    && cp -a "$(${GUIX_PROFILE}/bin/guix system --fallback docker-image ${GUIX_OPTS} ${WORK_D}/system.scm)" \
             "${WORK_D}/${GUIX_IMG_NAME}"


# Final steps

WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
