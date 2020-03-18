setenv dtb_addr 0x1000000
setenv env_addr 0x1040000
setenv kernel_addr 0x11000000
setenv initrd_addr 0x13000000
setenv boot_start booti ${kernel_addr} ${initrd_addr} ${dtb_addr}
setenv addmac 'if printenv mac; then setenv bootargs ${bootargs} mac=${mac}; elif printenv eth_mac; then setenv bootargs ${bootargs} mac=${eth_mac}; elif printenv ethaddr; then setenv bootargs ${bootargs} mac=${ethaddr}; fi'
if fatload mmc 0 ${env_addr} uEnv.txt && env import -t ${env_addr} ${filesize}; setenv bootargs ${APPEND}; then if fatload mmc 0 ${kernel_addr} ${LINUX}; then if fatload mmc 0 ${initrd_addr} ${INITRD}; then if fatload mmc 0 ${dtb_addr} ${FDT}; then run addmac; run boot_start; fi; fi; fi; fi;
