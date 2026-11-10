#!/usr/bin/env bash
# Télécharge les images officielles des monstres depuis le site Dofus Touch.
set -u
mkdir -p tools/official
ok=0; ko=0
while read -r id; do
  [ -z "$id" ] && continue
  out="tools/official/$id.png"
  [ -s "$out" ] && { ok=$((ok+1)); continue; }
  if curl -fsSL --retry 2 -o "$out" "https://static.ankama.com/dofus-touch/www/game/monsters/200/$id.w200h.png"; then
    ok=$((ok+1))
  else
    rm -f "$out"; ko=$((ko+1)); echo "$id" >> tools/official/missing.txt
  fi
done < tools/monster_ids.txt
echo "OK=$ok KO=$ko"
