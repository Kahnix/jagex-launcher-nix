#!/usr/bin/env bash
# Requires: curl, grep, sed.
# Bumps package.nix to the version advertised by the launcher's own
# electron-updater feed. The feed already carries the sha512, so nothing is
# downloaded.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

feed=$(curl -fsSL https://rs-launcher-updates.runescape.com/production/latest-linux.yml)
version=$(grep -m1 '^version:' <<<"$feed" | sed 's/^version: *//')
sha512=$(grep -m1 '^sha512:' <<<"$feed" | sed 's/^sha512: *//')

current=$(grep -m1 'version = "' package.nix | sed -E 's/.*"(.*)".*/\1/')
if [[ "$version" == "$current" ]]; then
  echo "jagex-launcher is up to date ($current)"
  exit 0
fi

sed -i -E \
  -e "s|version = \"[^\"]*\";|version = \"$version\";|" \
  -e "s|hash = \"sha512-[^\"]*\";|hash = \"sha512-$sha512\";|" \
  package.nix

echo "jagex-launcher: $current -> $version"
