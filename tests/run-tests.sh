#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$DIR/test_workflows.sh"
bash "$DIR/test_migrations.sh"
