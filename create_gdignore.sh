#!/usr/bin/env bash
set -euo pipefail

BASE="assets/third_party/inputs/kenney_input-prompts_1.4"

used=(
  "Keyboard & Mouse"
  "Xbox Series"
  "PlayStation Series"
  "Nintendo Switch"
  "Steam Deck"
)

unused=(
  "Flairs"
  "Generic"
  "Nintendo Gamecube"
  "Nintendo Switch 2"
  "Nintendo Wii"
  "Nintendo WiiU"
  "Playdate"
  "Steam Controller"
  "Touch"
)

gd_used='*
!*/
!Default/
!Default/*
!*.png
!*.xml
'

echo "Base path: $BASE"
echo

for f in "${used[@]}"; do
  dir="$BASE/$f"
  if [ ! -d "$dir" ]; then
    echo "Warning: no existe la carpeta: $dir" >&2
    continue
  fi
  out="$dir/.gdignore"
  printf "%s" "$gd_used" > "$out"
  echo "Creado: $out"
done

for f in "${unused[@]}"; do
  dir="$BASE/$f"
  if [ ! -d "$dir" ]; then
    echo "Warning: no existe la carpeta: $dir" >&2
    continue
  fi
  out="$dir/.gdignore"
  printf "%s" "*" > "$out"
  echo "Creado: $out (ignore everything)"
done

echo
echo "Hecho. Ahora puedes contar los .import antes y después."
