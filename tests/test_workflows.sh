#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null; then
  echo "jq command not found" >&2
  exit 1
fi

for file in workflows/*.json; do
  echo "Validating $file"
  jq empty "$file"
done
