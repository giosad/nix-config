#!/usr/bin/env zsh
set -euo pipefail
cd "${0:A:h}"
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#workmbp
