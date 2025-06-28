#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o verbose

LANG=C

date | tee boot.txt
who -b |
  tee -a boot.txt

date | tee memory.txt
sar -r | grep -E '(kb|Ave)' |
  tee -a memory.txt
free |
  tee -a memory.txt

date | tee disk.txt
df -hT -x tmpfs -x devtmpfs |
  sed -e 's/ on/On/' -e ':L;N;s/\n / /g;bL' |
  awk 'NR==1;NR>1{print|"sort -k7"}' |
  column -t |
  tee -a disk.txt
