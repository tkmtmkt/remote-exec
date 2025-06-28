#!/usr/bin/env bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
BASE_DIR=$(cd ${SCRIPT_DIR}/..;pwd)

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o verbose

if [ -d /var/log/sa ]; then
  SAR_DIR=/var/log/sa
elif [ -d /va/log/sysstat ]; then
  SAR_DIR=/va/log/sysstat
else
  exit 1
fi

for SARFILE in $(ls -tr ${SAR_DIR}/sa[0-3][0-9])
do
  DATE=$(stat -c %y ${SARFILE} | cut -d' ' -f 1)
  CSVFILE=$(hostname)_${DATE}.csv

  sadf -dt -- -r      ${SARFILE} > sar_-r_${CSVFILE}      # メモリ使用状況
  sadf -dt -- -q      ${SARFILE} > sar_-q_${CSVFILE}      # ロードアベレージ
  sadf -dt -- -u      ${SARFILE} > sar_-u_${CSVFILE}      # CPU使用状況
  sadf -dt -- -dp     ${SARFILE} > sar_-dp_${CSVFILE}     # HDD帯域幅使用状況
  sadf -dt -- -n DEV  ${SARFILE} > sar_-n_DEV_${CSVFILE}  # ネットワーク使用状況
  sadf -dt -- -n SOCK ${SARFILE} > sar_-n_SOCK_${CSVFILE} # ネットワークソケット使用状況
  sadf -dt -- -w      ${SARFILE} > sar_-w_${CSVFILE}      # コンテキストスイッチ状況
  sadf -dt -- -S      ${SARFILE} > sar_-S_${CSVFILE}      # スワップ使用状況
  # 以下のデータは/etc/sysstat.confのSDAC_OPTIONSを
  # SDAC_OPTIONS="-S XDISK"に変更する必要あり。
  sadf -dt -- -F      ${SARFILE} > sar_-F_${CSVFILE}      # ディスク使用状況
done
