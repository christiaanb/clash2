#!/bin/bash
set -xeou pipefail

# Check that clash-dev works
echo "" > clash-dev.result
echo 'main >> writeFile "clash-dev.result" "success"' | ./clash-dev
if [[ "$(cat clash-dev.result)" != "success" ]]; then
  echo "clash-dev test failed"
  exit 1
fi
