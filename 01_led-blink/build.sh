#!/bin/bash
source ~/oss-cad-suite/environment

set -e   # ← 重要: どこかでエラーが出たら、そこで止まる

# 設定: トップモジュール名と、ソースファイル一覧
TOP=led_blink
SOURCES="led_blink.v"

# 工程1: 合成
echo "=== Synthesis ==="
yosys -p "read_verilog ${SOURCES}; synth_gowin -top ${TOP} -json ${TOP}.json"

# 工程2: 配置配線
echo "=== Place and Route ==="
nextpnr-gowin --json ${TOP}.json \
              --write ${TOP}_pnr.json \
              --device GW1NR-LV9QN88PC6/I5 \
              --cst led_blink.cst

# 工程3: パッキング
echo "=== Pack ==="
gowin_pack -d GW1N-9C -o ${TOP}.fs ${TOP}_pnr.json

# 工程4: 書き込み
echo "=== Program ==="
openFPGALoader -b tangnano9k ${TOP}.fs

echo "=== Done ==="
