#!/bin/sh

mixer() {
  parm=${4:-on}
  amixer -c "$1" sset "$2" "$3" $parm >/dev/null 2>&1
  amixer -c "$1" sset "$2" $parm >/dev/null 2>&1
}

card=AMLGX
echo $card

# Amlogic GX HDMI and S/PDIF
  mixer $card 'AIU HDMI CTRL SRC' 'I2S'
  mixer $card 'AIU SPDIF SRC SEL' 'SPDIF'
