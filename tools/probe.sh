#!/usr/bin/env bash
UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36"
for u in \
  "https://static.ankama.com/dofus-touch/www/game/monsters/200/126.w200h.png" \
  "https://static.ankama.com/dofus-touch/www/game/monsters/200/126.png" \
  "https://static.ankama.com/dofus/www/game/monsters/200/126.w200h.png" \
  "https://static.ankama.com/dofus/www/game/monsters/200/126.png" \
  "https://static.ankama.com/dofus-touch/www/game/monsters/100/126.png" \
  "https://www.dofus-touch.com/fr/mmorpg/encyclopedie/monstres/126-souris-grise" ; do
  for mode in plain browser; do
    if [ $mode = plain ]; then args=(); else args=(-A "$UA" -e "https://www.dofus-touch.com/fr/mmorpg/encyclopedie/monstres"); fi
    curl -sS -L "${args[@]}" -o /tmp/p -w "$mode %{http_code} %{content_type} %{size_download} $u\n" "$u"
    if [ "$mode" = browser ] && [[ "$u" == *encyclopedie* ]]; then grep -oE 'https://static\.ankama\.com[^"]+monsters[^"]+' /tmp/p | sort -u | head -5; grep -oE 'og:image" content="[^"]+' /tmp/p | head -2; fi
  done
done
