#/bin/bash -x
#
# -x        Print commands and their arguments as they are executed.

# example: "--VAR==7"
print_var() {
  if [ -n "$1" ] ; then
    echo "-- ${1}==${!1}"
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

I=${0##*/}

if [[ $# != 2 ]]; then
  echo "Script to import aml packer needed files from tvip_stb"
  echo
  echo "Usage: "
  echo "  change UBOOT_GIT_VERSION in tvip_stb/platforms/<s52x|s6xx>/private/include.cmake to sha of most recent commit in ssh://git.netsol.su/git/amlogic/linux/uboot-buildroot/uboot.git::branch::tvip49"
  echo "  change UBOOT_PLATFORM to gxl_armbian_tvip<52x|s6xx>_v1 in tvip_stb/platforms/<s52x|s6xx>/private/include.cmake"
  echo "  make build-<s52x|s6xx>"
  echo "  cd build-<s52x|s6xx>"
  echo "  make tvip-firmware-qt5-release"
  echo "  $I <tvip_stb_dir> <s6xx|s52x>"
  echo
  echo "example: ${0##*/} /tvip/tvip_stb s52x"
  echo
  exit 1
fi

TVIP_STB_DIR=$1
PLATFORM=$2

TVIP_STB_INNER_DIR=$TVIP_STB_DIR/build-${PLATFORM}/tvip/firmware-qt5-release/tvipstb


cp -fv $TVIP_STB_INNER_DIR/firmware-img/target/AML_UPGRADE/{meson.dtb,platform_default.conf} AML_UPGRADE/

cp -fv $TVIP_STB_INNER_DIR/firmware-img/target/BOOTLOADER/{ddr_init.bin,u-boot-comp.bin,bootloader} BOOTLOADER/
