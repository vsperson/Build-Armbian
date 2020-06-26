#/bin/bash

FW_ENV_CONFIG=fw_env.config

# example: "--VAR==7"
print_var() {
  if [ -n "$1" ] ; then
    echo "-- ${1}==${!1}"
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

print_cmd_title() {
    if [ -n "$1" ] ; then
    echo "###### ${1} ######"
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

self_name() {
  echo ${0##*/}
}

extract_partition() {
  if [[ -n "$1" || -n "$2" || -n "$3" || -n "$4" || -n "$5" ]] ; then
    local PART_NAME="$1"
    local INPUT_FILE="$2"
    local SKIP="$3"
    local COUNT="$4"
    local OUTPUT_FILE="$5"

    print_cmd_title "Extracting $PART_NAME partition from $INPUT_FILE to $OUTPUT_FILE ..."
    dd status=progress bs=1b skip=$SKIP count=$COUNT if=$INPUT_FILE of=$OUTPUT_FILE # 1b = 512 bytes
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

repack_boot_partition() {
  if [[ -n "$1" || -n "$2" || -n "$3" ]] ; then
    local BOOT_PART=$1
    local SRC_DTB_NAME=$2
    local DST_DTB_NAME=$3
    print_cmd_title "Repacking $BOOT_PART to add $DST_DTB_NAME ..."
    local TMP_DIR=$(mktemp -d -t armbian-mnt-XXXXXXXXXX)
    mount -v -o loop,rw $1 $TMP_DIR
    cp -v $SRC_DTB_NAME $TMP_DIR/dtb/amlogic/$DST_DTB_NAME
    umount -v $TMP_DIR/
    rm -rv $TMP_DIR/
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

repack_rootfs_partition() {
  if [[ -n "$1" ]] ; then
    print_cmd_title "Repacking $1 to add $FW_ENV_CONFIG ..."
    local TMP_DIR=$(mktemp -d -t armbian-mnt-XXXXXXXXXX)
    mount -v -o loop,rw $1 $TMP_DIR
    cp -v $FW_ENV_CONFIG $TMP_DIR/etc/
    umount -v $TMP_DIR
    rm -rv $TMP_DIR
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

shrink_rootfs_partition() {
  local CURRENT_SIZE_BYTES=$(du -B1 $1 | cut -f1)
  local CURRENT_SIZE_HUMAN=$(du -h $1 | cut -f1)
  local MAX_CAPACITY=4680843264 # value is obtained from console error when flash very big image file through USB Burning Tool
  if [[ -n "$1" ]] ; then
    print_cmd_title  "Shrinking $1 size. Current size is $CURRENT_SIZE_HUMAN ($CURRENT_SIZE_BYTES bytes) ..."
    e2fsck -f $1
    if (( ${CURRENT_SIZE_BYTES} > ${MAX_CAPACITY} )); then
      echo "Current size ${CURRENT_SIZE_BYTES} bytes greater than burning-tool max available capacity ${MAX_CAPACITY}. Shrinking file system..."
      echo "resize2fs $1 $((${MAX_CAPACITY}/1024))K"
      resize2fs $1 $((${MAX_CAPACITY}/1024))K
    else
      echo "Current size ${CURRENT_SIZE_BYTES} bytes fits to burning-tool max available capacity ${MAX_CAPACITY}. No need to shrink file system"
    fi
    local NEW_CURRENT_SIZE_BYTES=$(du -B1 $1 | cut -f1)
    local NEW_CURRENT_SIZE_HUMAN=$(du -h $1 | cut -f1)
    echo -e "New minimized $1 size is $NEW_CURRENT_SIZE_HUMAN ($NEW_CURRENT_SIZE_BYTES bytes) \n"
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

get_input_img() {
  if [[ -n "$1" ]] ; then
    local EXTENSION=${1##*.}
    if [[ "$EXTENSION" = "img" ]]; then
      INPUT_IMG=$1
    elif [[ "$EXTENSION" = "xz" ]]; then
      extract_img_from_xz "$1"
    else
      exit 1
    fi
  else
      echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

extract_img_from_xz() {
  if [[ -n "$1" ]] ; then
    print_cmd_title  "Extracting img file from archive $1 ..."
    # local TMP_DIR=$(mktemp -p ./ -d -t armbian-extract-XXXXXXXXXX)
    TMP_DIR=.
    local INPUT_XZ_BASENAME=$(basename ${1})
    local INPUT_IMG_BASENAME=$(basename ${1%.*})
    cp -fv $1 $TMP_DIR/
    unxz -dfv --threads=0 $TMP_DIR/$INPUT_XZ_BASENAME
    INPUT_IMG=$TMP_DIR/$INPUT_IMG_BASENAME
  else
      echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

detect_partitions() {
  if [ -n "$1" ] ; then
    print_cmd_title "Detecting paritions in $1"
    DETECTED_PARTITIONS=$(fdisk -l $1 | grep -P -A 100 "Device.+Boot.+Start.+End.+Sectors.+Size.+Id.+Type")
    if [[ -n "$DETECTED_PARTITIONS" ]]; then
      echo "Detected paritions in $1:"
      echo "$DETECTED_PARTITIONS"
    else
      echo "fdisk unable to detect paritions in $1"
      exit 1
    fi
  
    BOOT_PARTITION=$(echo "$DETECTED_PARTITIONS" | head -n2 | tail -n1)
    BOOT_PARTITION_START=$(echo "$BOOT_PARTITION" | awk '{print $2}')      # in sectors. sector size is 512 bytes
    BOOT_PARTITION_SIZE=$(echo "$BOOT_PARTITION" | awk '{print $4}')
    ROOTFS_PARTITION=$(echo "$DETECTED_PARTITIONS" | head -n3 | tail -n1)
    ROOTFS_PARTITION_START=$(echo "$ROOTFS_PARTITION" | awk '{print $2}')
    ROOTFS_PARTITION_SIZE=$(echo "$ROOTFS_PARTITION" | awk '{print $4}')
  
    echo
  
    print_var BOOT_PARTITION
    print_var BOOT_PARTITION_START
    print_var BOOT_PARTITION_SIZE
    print_var ROOTFS_PARTITION
    print_var ROOTFS_PARTITION_START
    print_var ROOTFS_PARTITION_SIZE
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

a113x_usage() {
  if [[ -n "$1" ]] ; then
    echo "Script to convert Armbian* img to A113X img"
    echo
    echo "Usage: $1 <armbian_img_or_xz> <output_img>"
    echo
    echo "examples:"
    echo "  1) $1 Armbian_20.05.5_Arm-64_bionic_current_5.7.0-rc7.img.xz a113x_armbian.img"
    echo "  2) $1 Armbian_20.05.5_Arm-64_bionic_current_5.7.0-rc7.img    a113x_armbian.img"
    echo
    echo
    echo
    echo "* Armbian fork for TV boxes (GitHub - 150balbes)"
    exit 1
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}

s905_usage() {
  if [[ -n "$1" || -n "$2" ]] ; then
    echo "Script to convert Armbian* image to $2 image"
    echo
    echo "Usage: $1 <armbian_img_or_xz> <output_img>"
    echo
    echo "examples:"
    echo "  1) $1 Armbian_20.05.5_Arm-64_bionic_current_5.7.0-rc7.img.xz $2_armbian.img"
    echo "  2) $1 Armbian_20.05.5_Arm-64_bionic_current_5.7.0-rc7.img    $2_armbian.img"
    echo
    echo
    echo
    echo "* Armbian fork for TV boxes (GitHub - 150balbes)"
    exit 1
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}
