# Layer 1: Build
# --------------

#FROM alpine:3.12.3 AS build
FROM pandagix/alpine-pandagix-docker:279889 AS build
# guix channel commit dffc918, used for ci.guix.gnu.org Build ID 279889, date 20200206
# nonguix channel commit 73b11e7, linux 5.10.14 and 5.4.96, date 20200208


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


# Alpine Package requirements
# ^^^^^^^^^^^^^^^^^^^^

#RUN apk add --no-cache ca-certificates openrc wget git
#already in pandagix/alpine-pandagix-docker:279889
RUN apk add --no-cache busybox-static jq tar


# Build GuixSD Docker Image
# ^^^^^^^^^^^^^^^^^^^^^^^^^

ENV USER="root"

#COPY scripts/channels.scm-279989 "${GUIX_CONFIG}/channels.scm"
COPY scripts/system.scm-with-nss "${WORK_D}/system.scm"

# since pandagix/alpine-pandagix-docker:279889 is used,
# guix pull is NOT needed, hash guix is needed.

RUN source "${GUIX_PROFILE}/etc/profile" \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    && hash guix \
    && "${GUIX_PROFILE}/bin/guix" --version \
    && "${GUIX_PROFILE}/bin/guix" describe \
    && "${GUIX_PROFILE}/bin/guix" gc \
    #&& "${GUIX_PROFILE}/bin/guix" pull \
    #&& "${GUIX_PROFILE}/bin/guix" package ${GUIX_OPTS} --upgrade \
    && cp -a "$(${GUIX_PROFILE}/bin/guix system docker-image ${GUIX_OPTS} ${WORK_D}/system.scm)" \
             "${WORK_D}/${GUIX_IMG_NAME}"


# Final steps

WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
