#!/usr/bin/env bash
set -u
P=https://proxyconnection.touch.dofus.com
mkdir -p tools/touch
for f in config.json assetsVersions.json; do
  curl -sS -o tools/touch/$f -w "%{http_code} %{content_type} %{size_download} $f\n" "$P/$f"
done
head -c 600 tools/touch/config.json; echo; head -c 600 tools/touch/assetsVersions.json; echo
V=$(python3 -c "import json;print(json.load(open('tools/touch/assetsVersions.json')).get('assetsVersion',''))" 2>/dev/null)
B=$(python3 -c "import json;print(json.load(open('tools/touch/config.json')).get('buildVersion',''))" 2>/dev/null)
echo "assets=$V build=$B"
curl -sS -o tools/touch/assetMap.json -w "%{http_code} %{size_download} assetMap\n" "$P/assetMap.json"
for c in Monsters SubAreas MapPositions WorldMaps Areas SuperAreas; do
  curl -sS -X POST -H "Content-Type: application/json" -d "{\"class\":\"$c\"}" \
    -o tools/touch/$c.json -w "%{http_code} %{size_download} $c\n" "$P/data/map?lang=fr&v=$B"
done
python3 - <<'P'
import json,re
try:
    a=json.load(open('tools/touch/assetMap.json'))
    files=a.get('files',a)
    names=list(files.keys()) if isinstance(files,dict) else []
    print('assetMap entries',len(names))
    for pat in ['world','monster','Monster','bones','worldmap']:
        m=[n for n in names if pat in n]
        print(pat,len(m),m[:8])
except Exception as e: print('assetMap err',e)
for c in ['Monsters','SubAreas','MapPositions','WorldMaps']:
    try:
        d=json.load(open(f'tools/touch/{c}.json')); k=list(d.keys())[:1]; print(c,len(d),k, json.dumps(d[k[0]],ensure_ascii=False)[:400])
    except Exception as e: print(c,'err',e)
P
