#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPU="$SCRIPT_DIR/../la32r-exam/cdp_ede_local-master/mycpu_env/myCPU"
OUTPUT="$(mktemp "${TMPDIR:-/tmp}/tb_xadd2w.XXXXXX")"
trap 'rm -f "$OUTPUT"' EXIT

iverilog -g2012 -s tb_xadd2w -I "$CPU" -o "$OUTPUT" \
  "$SCRIPT_DIR/tb_xadd2w.v" \
  "$CPU/ID_stage.v" "$CPU/EX_stage.v" "$CPU/regfile.v" \
  "$CPU/alu.v" "$CPU/tools.v"

vvp "$OUTPUT"
