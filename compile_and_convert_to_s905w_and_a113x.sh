#/bin/bash -x
#
# -x        Print commands and their arguments as they are executed.

set -e # Exit immediately if a command exits with a non-zero status
set -u # Treat unset variables and parameters as an error

SRC="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

JETHOME=$SRC/jethome
USERPATCHES=$SRC/userpatches
USERPATCHES_KERNEL_ARM_64=$USERPATCHES/kernel/arm-64-current
USERPATCHES_SOURCES_FAMILIES=$USERPATCHES/sources/families

mkdir -pv $USERPATCHES_KERNEL_ARM_64
mkdir -pv $USERPATCHES_SOURCES_FAMILIES

rm -fv $USERPATCHES_KERNEL_ARM_64/*

cp -fv $JETHOME/patch/kernel/arm-64-current/* $USERPATCHES_KERNEL_ARM_64/
cp -fv $JETHOME/patch/sources/families/arm-64.conf $USERPATCHES_SOURCES_FAMILIES/

./compile.sh docker \
BUILD_KSRC=yes \
BOARD=arm-64 \
BRANCH=current \
RELEASE=focal \
BUILD_MINIMAL=no \
BUILD_DESKTOP=no \
KERNEL_ONLY=no \
KERNEL_CONFIGURE=no \
CREATE_PATCHES=no \
COMPRESS_OUTPUTIMAGE=sha,gpg,img \
LIB_TAG=jethome
