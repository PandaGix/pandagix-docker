# src/Dockerfile
# ==============
#
# Copying
# -------
#
# Copyright (c) 2020 x237net/guixsd authors.
#
# This file is part of the *x237net/guixsd* project.
#
# x237net/guixsd is a free software project. You can redistribute it and/or
# modify if under the terms of the MIT License.
#
# This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
# KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
#
# You should have received a copy of the MIT License along with
# x237net/guixsd. If not, see <http://opensource.org/licenses/MIT>.
#

# Layer 0: Welcome
# ----------------

FROM x237net/alpine-guix:latest AS welcome

RUN echo                                                                        \
    && echo "          ░░░                                     ░░░           "  \
    && echo "          ░░▒▒░░░░░░░░░               ░░░░░░░░░▒▒░░             "  \
    && echo "           ░░▒▒▒▒▒░░░░░░░           ░░░░░░░▒▒▒▒▒░               "  \
    && echo "               ░▒▒▒░░▒▒▒▒▒         ░░░░░░░▒▒░                   "  \
    && echo "                     ░▒▒▒▒░       ░░░░░░                        "  \
    && echo "                      ▒▒▒▒▒      ░░░░░░                         "  \
    && echo "                       ▒▒▒▒▒     ░░░░░                          "  \
    && echo "                       ░▒▒▒▒▒   ░░░░░                           "  \
    && echo "                        ▒▒▒▒▒   ░░░░░                           "  \
    && echo "                         ▒▒▒▒▒ ░░░░░                            "  \
    && echo "                         ░▒▒▒▒▒░░░░░                            "  \
    && echo "                          ▒▒▒▒▒▒░░░                             "  \
    && echo "                           ▒▒▒▒▒▒░                              "  \
    && echo "     _____ _   _ _    _    _____       _        ___________     "  \
    && echo "    / ____| \ | | |  | |  / ____|     (_)      / ____|  __ \    "  \
    && echo "   | |  __|  \| | |  | | | |  __ _   _ ___  __| (___ | |  | |   "  \
    && echo "   | | |_ | . ' | |  | | | | |_ | | | | \ \/ / \___ \| |  | |   "  \
    && echo "   | |__| | |\  | |__| | | |__| | |_| | |>  <  ____) | |__| |   "  \
    && echo "    \_____|_| \_|\____/   \_____|\__,_|_/_/\_\|_____/|_____/    "  \
    && echo


# Layer 1: Build
# --------------

FROM x237net/alpine-guix:latest AS build


ARG GUIX_PROFILE="/root/.config/guix/current"
ARG GUIX_BUILD_GRP="guixbuild"
ARG GUIX_OPTS="--verbosity=2 --fallback"
ARG GUIX_IMG_NAME="guix-docker-image.tar.gz"
ARG GUIXSD_IMG_NAME="guixsd-docker-image.tar"

ARG WORK_D=/tmp
ARG IMG_D="${WORK_D}/image"
ARG ROOT_D="${WORK_D}/root"


# Package requirements
# ^^^^^^^^^^^^^^^^^^^^

RUN apk add --no-cache busybox-static jq


# Build GuixSD Docker Image
# ^^^^^^^^^^^^^^^^^^^^^^^^^

ENV USER="root"


COPY system.scm "${WORK_D}/system.scm"
RUN source "${GUIX_PROFILE}/etc/profile"                                        \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    && "${GUIX_PROFILE}/bin/guix" pull ${GUIX_OPTS}                             \
    && "${GUIX_PROFILE}/bin/guix" package ${GUIX_OPTS} --upgrade                \
    && cp -a "$(${GUIX_PROFILE}/bin/guix system docker-image ${GUIX_OPTS} ${WORK_D}/system.scm)" \
             "${WORK_D}/${GUIX_IMG_NAME}"


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
    # Link binary folders to system's profile.
    && for _d in "bin" "sbin";                                                  \
       do                                                                       \
           rm -rf "${_d}"                                                       \
               && ln -s "/var/guix/profiles/system/profile/${_d}" "${_d}";      \
       done                                                                     \
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
    # Archive final root structure for next layer.
    && tar -cf "${WORK_D}/${GUIXSD_IMG_NAME}" .


# Layer 2: Image
# --------------

FROM scratch


ARG ENTRY_D=/root

ENV USER="root"


# We need BusyBox in order to unpack the filesystem.
COPY --from=build "/bin/busybox.static" "/busybox"

# Deploy filesystem.
WORKDIR /
COPY --from=build "${WORK_D}/${GUIXSD_IMG_NAME}" "/root.tar"
RUN ["/busybox", "tar", "-x", "-f", "/root.tar"]
RUN ["/busybox", "rm", "-f", "/root.tar"]
RUN ["/busybox", "rm", "-f", "/busybox"]


WORKDIR "${ENTRY_D}"
ENTRYPOINT "/init"
