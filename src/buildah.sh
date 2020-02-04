#!/bin/sh
#
# src/buildah.sh
# ==============
#
# Copying
# -------
#
# Copyright (c) 2020 alpine-guix authors.
#
# This file is part of the *alpine-guix* project.
#
# alpine-guix is a free software project. You can redistribute it and/or
# modify if under the terms of the MIT License.
#
# This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
# KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
#
# You should have received a copy of the MIT License along with
# alpine-guix. If not, see <http://opensource.org/licenses/MIT>.
#

# Layer 0: Welcome
# ----------------

cat << "EOF"

          ░░░                                     ░░░
          ░░▒▒░░░░░░░░░               ░░░░░░░░░▒▒░░
           ░░▒▒▒▒▒░░░░░░░           ░░░░░░░▒▒▒▒▒░
               ░▒▒▒░░▒▒▒▒▒         ░░░░░░░▒▒░
                     ░▒▒▒▒░       ░░░░░░
                      ▒▒▒▒▒      ░░░░░░
                       ▒▒▒▒▒     ░░░░░
                       ░▒▒▒▒▒   ░░░░░
                        ▒▒▒▒▒   ░░░░░
                         ▒▒▒▒▒ ░░░░░
                         ░▒▒▒▒▒░░░░░
                          ▒▒▒▒▒▒░░░
                           ▒▒▒▒▒▒░
     _____ _   _ _    _    _____       _        ___________
    / ____| \ | | |  | |  / ____|     (_)      / ____|  __ \
   | |  __|  \| | |  | | | |  __ _   _ ___  __| (___ | |  | |
   | | |_ | . ' | |  | | | | |_ | | | | \ \/ / \___ \| |  | |
   | |__| | |\  | |__| | | |__| | |_| | |>  <  ____) | |__| |
    \_____|_| \_|\____/   \_____|\__,_|_/_/\_\|_____/|_____/

EOF


# Layer 1: Build
# --------------

build=$(buildah from x237net/alpine-guix)


GUIX_PROFILE="/root/.config/guix/current"
GUIX_BUILD_GRP="guixbuild"
GUIX_OPTS="--verbosity=2"
GUIX_IMG_NAME="guix-docker-image.tar.gz"
GUIXSD_IMG_NAME="guixsd-docker-image.tar"

WORK_D=/tmp
IMG_D="${WORK_D}/image"
ROOT_D="${WORK_D}/root"


# Try to run given command and exit on failure.
# We basically don't want to continue any further when a command fails.
try() { ${@} || exit ${?}; }


# Package requirements
# ^^^^^^^^^^^^^^^^^^^^

try buildah run "${build}" -- apk add --no-cache busybox-static jq


# Build GuixSD Docker Image
# ^^^^^^^^^^^^^^^^^^^^^^^^^

try buildah config --env USER="root" "${build}"

try buildah copy "${build}" ./system.scm "${WORK_D}/system.scm"
buildah run "${build}" -- sh -c "source '${GUIX_PROFILE}/etc/profile'
'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &
'${GUIX_PROFILE}/bin/guix' pull ${GUIX_OPTS}                                    \
    && '${GUIX_PROFILE}/bin/guix' package ${GUIX_OPTS} --upgrade                \
    && cp -a \"\$('${GUIX_PROFILE}/bin/guix' system docker-image ${GUIX_OPTS} '${WORK_D}/system.scm')\" \
             '${WORK_D}/${GUIX_IMG_NAME}'
" || exit ${?}


# Prepare final image
# ^^^^^^^^^^^^^^^^^^^

# Extract Docker image.
try buildah run "${build}" -- mkdir --parents "${IMG_D}"
try buildah run "${build}" -- tar -xzvf "${WORK_D}/${GUIX_IMG_NAME}" -C "${IMG_D}"

# Recreate root structure by extracting each layers.
try buildah run "${build}" -- mkdir --parents "${ROOT_D}"
buildah run "${build}" -- sh -c "
jq -r '.[0].Layers | .[]' '${IMG_D}/manifest.json' | while read _layer
do
    tar -xf \"${IMG_D}/\${_layer}\" --exclude 'dev/*' -C '${ROOT_D}'
done
" || exit ${?}

# Link special required binaries.
try buildah run "${build}" -- mkdir --parents "${ROOT_D}/usr/bin"
try buildah run "${build}" -- ln -s "/var/guix/profiles/system/profile/bin/sh"  \
                                    "${ROOT_D}/bin/sh"
try buildah run "${build}" -- ln -s "/var/guix/profiles/system/profile/bin/env" \
                                    "${ROOT_D}/usr/bin/env"

# Set up init script.
buildah run "${build}" -- sh -c "
echo '#!/bin/sh' > '${ROOT_D}/init'
jq -r '.config.env | .[]' '${IMG_D}/config.json' | while read _env
do
    echo \"export \${_env}\" >> '${ROOT_D}/init'
done
echo 'export GUIX_PROFILE=/var/guix/profiles/system/profile' >> '${ROOT_D}/init'
echo 'export PATH=\${GUIX_PROFILE}/bin\${PATH:+:}\${PATH}' >> '${ROOT_D}/init'
echo '. \${GUIX_PROFILE}/etc/profile' >> '${ROOT_D}/init'
echo \"exec \$(jq -r '.config.entrypoint | join(\" \")' '${IMG_D}/config.json')\" >> '${ROOT_D}/init'
" || exit ${?}

try buildah run "${build}" -- chmod 0500 "${ROOT_D}/init"

# Archive final root structure for next layer.
buildah run "${build}" -- sh -c "
cd '${ROOT_D}'
tar -cf '${WORK_D}/${GUIXSD_IMG_NAME}' .
" || exit ${?}


# Layer 2: Image
# --------------

image=$(buildah from scratch)


ENTRY_D=/root

try buildah config --env USER="root" "${image}"


build_mnt=$(buildah mount "${build}")

# We need BusyBox in order to unpack the filesystem.
try buildah copy "${image}" "${build_mnt}/bin/busybox.static" "/busybox"

# Deploy filesystem.
try buildah copy "${image}" "${build_mnt}${WORK_D}/${GUIXSD_IMG_NAME}" "/root.tar"
try buildah run "${image}" -- "/busybox" tar -xf "/root.tar" -C /
try buildah run "${image}" -- "/busybox" rm -f "/root.tar"
try buildah run "${image}" -- "/busybox" rm -f "/busybox"

buildah umount "${build}"

buildah config --workingdir "${ENTRY_D}" "${image}"
buildah config --entrypoint ["/init"]

buildah commit --squash "${image}" "x237net/guixsd"
