#!/usr/bin/env bash
# One-shot bootstrap for a new machine.
#   git clone https://github.com/luke-h1/skills && cd skills && ./install.sh
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/bin/skill" install
