#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o verbose

for SARFILE in $(ls -tr /var/log/sa/sa[0-3]*)
do
  DATE=$(stat -c %z ${SARFILE} | cut -d' ' -f 1)
  CSVFILE=$(hostname)_${DATE}.csv

  # CPU使用状況
  sadf -dt -- -u      ${SARFILE} | tr ';' ',' > sar_-u_${CSVFILE}
  # ロードアベレージ状況
  sadf -dt -- -q      ${SARFILE} | tr ';' ',' > sar_-q_${CSVFILE}
  # メモリ使用状況
  sadf -dt -- -r      ${SARFILE} | tr ';' ',' > sar_-r_${CSVFILE}
  # ブロックデバイスの活性度
  sadf -dt -- -dp     ${SARFILE} | tr ';' ',' > sar_-dp_${CSVFILE}
  # ネットワーク使用状況
  sadf -dt -- -n DEV  ${SARFILE} | tr ';' ',' > sar_-n_DEV_${CSVFILE}
  # ネットワークソケット使用状況
  sadf -dt -- -n SOCK ${SARFILE} | tr ';' ',' > sar_-n_SOCK_${CSVFILE}
  # コンテキストスイッチ状況
  sadf -dt -- -w      ${SARFILE} | tr ';' ',' > sar_-w_${CSVFILE}
  # スワップ使用状況
  sadf -dt -- -S      ${SARFILE} | tr ';' ',' > sar_-S_${CSVFILE}
done
