#/bin/bash -x
#
# -x        Print commands and their arguments as they are executed.

set -e # Exit immediately if a command exits with a non-zero status
set -u # Treat unset variables and parameters as an error

. ../convert_armbian_common/functions.sh

I=$(self_name)

if [[ $# != 2 ]]; then
  a113x_usage "$I"
fi

INPUT_FILE=$1
OUTPUT_IMG=$2

SYSTEM_IMG=system_a.PARTITION
DATA_IMG=data.PARTITION

DTB_SRC_NAME=meson-axg-s400.dtb
DTB_DST_NAME=meson-axg-s420-jethome.dtb

get_input_img "$INPUT_FILE"

echo

detect_partitions "$INPUT_IMG"

echo

extract_partition "BOOT" "$INPUT_IMG" "$BOOT_PARTITION_START" "$BOOT_PARTITION_SIZE" "$SYSTEM_IMG"

echo

repack_boot_partition "$SYSTEM_IMG" "$DTB_SRC_NAME" "$DTB_DST_NAME"

echo

extract_partition "ROOTFS" "$INPUT_IMG" "$ROOTFS_PARTITION_START" "$ROOTFS_PARTITION_SIZE" "$DATA_IMG"

echo

repack_rootfs_partition "$DATA_IMG"

echo

shrink_rootfs_partition "$DATA_IMG"

echo

print_cmd_title "Packing $OUTPUT_IMG ..."
./aml_image_v2_packer -r image.cfg ./ $OUTPUT_IMG
