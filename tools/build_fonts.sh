#!/usr/bin/env bash
# Rebuild the subset WOFF2 fonts from the Google Fonts (OFL) sources.
# Latin fonts keep only ASCII/symbols; Chinese fonts keep the characters used in the app.
# Requires: curl, python3 with fonttools + brotli. Usage: bash tools/build_fonts.sh
set -euo pipefail
GAME="$(cd "$(dirname "$0")/../app" && pwd)"
WORK="$(mktemp -d)"
BASE=https://raw.githubusercontent.com/google/fonts/main/ofl
curl -sSfo "$WORK/dela.ttf" "$BASE/delagothicone/DelaGothicOne-Regular.ttf"
curl -sSfo "$WORK/zen-bold.ttf" "$BASE/zenmarugothic/ZenMaruGothic-Bold.ttf"
curl -sSfo "$WORK/zen-black.ttf" "$BASE/zenmarugothic/ZenMaruGothic-Black.ttf"
curl -sSfo "$WORK/qingke.ttf" "$BASE/zcoolqingkehuangyou/ZCOOLQingKeHuangYou-Regular.ttf"
curl -sSfo "$WORK/noto.ttf" "$BASE/notosanssc/NotoSansSC%5Bwght%5D.ttf"
python3 - "$GAME" "$WORK" <<'PY'
import sys, pathlib
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
game, work = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
chars = set()
for f in [*game.glob('*.html'), *game.glob('*.css'), *game.glob('js/*.js')]:
    chars |= set(f.read_text(encoding='utf-8'))
chars |= set('０１２３４５６７８９＋−×÷＝，。、・！？「」（）：；…～—')
latin = ''.join(chr(c) for c in range(0x20, 0x7f)) + '×÷−＝＋·•☆★♪‹›⌫∞…%'
cjk = ''.join(sorted(c for c in chars if ord(c) >= 0x2E80))
(work / 'latin.txt').write_text(latin, encoding='utf-8')
(work / 'cjk.txt').write_text(cjk + latin, encoding='utf-8')
for w in (700, 900):
    instancer.instantiateVariableFont(TTFont(work / 'noto.ttf'), {'wght': w}).save(work / f'noto{w}.ttf')
PY
sub() { python3 -m fontTools.subset "$WORK/$1" --text-file="$WORK/$2" --flavor=woff2 --layout-features='*' --output-file="$GAME/fonts/$3"; }
sub dela.ttf latin.txt dela-gothic-one.woff2
sub zen-bold.ttf latin.txt zen-maru-gothic-bold.woff2
sub zen-black.ttf latin.txt zen-maru-gothic-black.woff2
sub qingke.ttf cjk.txt zcool-qingke.woff2
sub noto700.ttf cjk.txt noto-sans-sc-bold.woff2
sub noto900.ttf cjk.txt noto-sans-sc-black.woff2
rm -rf "${WORK:?}"
echo "fonts rebuilt in $GAME/fonts"
