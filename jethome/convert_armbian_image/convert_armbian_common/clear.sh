#/bin/bash -x
#
# -x        Print commands and their arguments as they are executed.

rm -v --interactive {data,system_a}.PARTITION AML_UPGRADE/{data,system}.img *.img
