#!/bin/bash
# add-from-photos.sh — autofeed the WEBSITE ART Photos album into the site.
#
# WORKFLOW:
#   1. In Apple Photos, drag art into the album "WEBSITE ART".
#   2. Run:  ./add-from-photos.sh
#   It resizes each NEW photo to web size, drops it in art/, and prints the
#   <figure> blocks to paste into portfolio.html.
#
# INCREMENTAL & SAFE: re-run it anytime. Photos already imported are skipped
# (matched by filename in art/). It only COPIES from Photos — never deletes,
# never edits your library, never overwrites a file in art/.

set -e
OSX="$HOME/.claude/skills/photos-export/.venv/bin/osxphotos"
ALBUM="WEBSITE PICS"
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"
ART="$SITE_DIR/art"
TMP="$SITE_DIR/.photos-tmp"     # gitignored scratch, deleted at the end

[ -x "$OSX" ] || { echo "osxphotos not found at $OSX" >&2; exit 1; }
mkdir -p "$ART"
rm -rf "$TMP"; mkdir -p "$TMP"

echo "Reading album \"$ALBUM\" from Photos..."
# Date-prefixed original name = stable identity + matches Jaz's naming convention.
"$OSX" export "$TMP" --album "$ALBUM" \
  --filename "{created.strftime,%Y-%m%d}_{original_name}" \
  --download-missing --retry 3 --skip-edited --skip-bursts \
  --convert-to-jpeg >/dev/null 2>&1

new=0; skipped=0
FIGS="$TMP/figures.txt"; : > "$FIGS"
shopt -s nullglob nocaseglob
for src in "$TMP"/*.jpg "$TMP"/*.jpeg "$TMP"/*.png "$TMP"/*.heic; do
  base=$(basename "$src"); base="${base%.*}"
  name=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' \
        | sed 's/[^a-z0-9-]//g; s/--*/-/g; s/^-//; s/-$//')
  [ -z "$name" ] && name="art"
  out="$ART/$name.jpg"
  if [ -e "$out" ]; then skipped=$((skipped+1)); continue; fi   # already on site
  sips -Z 1400 "$src" --out "$out" -s format jpeg -s formatOptions 80 >/dev/null 2>&1
  new=$((new+1))
  printf '        <figure>\n            <img src="art/%s.jpg" alt="TODO describe this artwork">\n            <figcaption>Caption</figcaption>\n        </figure>\n\n' "$name" >> "$FIGS"
done

echo ""
echo "✅ $new new image(s) added to art/   ($skipped already there, skipped)"
if [ "$new" -gt 0 ]; then
  echo ""
  echo "Paste these into portfolio.html, inside your gallery div:"
  echo "--------------------------------------------------------------"
  cat "$FIGS"
  echo "--------------------------------------------------------------"
fi
rm -rf "$TMP"
