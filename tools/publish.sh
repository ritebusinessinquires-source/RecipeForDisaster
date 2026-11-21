#!/usr/bin/env bash
# Build the place file and publish it to Roblox.
# Needs an Open Cloud API key with universe-places:write: export ROBLOX_API_KEY=...
set -euo pipefail
UNIVERSE_ID="${UNIVERSE_ID:-10778121901}"
PLACE_ID="${PLACE_ID:-77411074610403}"
VERSION_TYPE="${1:-Published}"   # Published or Saved
cd "$(dirname "$0")/.."
python3 tools/build_place.py build/RecipeForDisaster.rbxlx
curl --fail-with-body -s -X POST \
  -H "x-api-key: ${ROBLOX_API_KEY:?set ROBLOX_API_KEY}" \
  -H "Content-Type: application/xml" \
  --data-binary @build/RecipeForDisaster.rbxlx \
  "https://apis.roblox.com/universes/v1/${UNIVERSE_ID}/places/${PLACE_ID}/versions?versionType=${VERSION_TYPE}"
echo
