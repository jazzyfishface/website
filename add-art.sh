#!/bin/bash
# add-art.sh — drop art onto the website the easy way.
#
# USAGE:  ./add-art.sh "/path/to/photo.jpg" "Caption for the picture"
#         ./add-art.sh "/path/to/photo.jpg"          (no caption)
#
# What it does:
#   1. shrinks the image to 1400px max (originals are 10-15MB; the web needs ~200KB)
#   2. renames it lowercase-with-hyphens and drops it in art/
#   3. prints the HTML block for you to paste into portfolio.html
#
# It NEVER overwrites: if the name is taken it adds -2, -3, etc.

set -e
SRC="$1"
CAPTION="${2:-}"

if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "Usage: ./add-art.sh \"/path/to/image.jpg\" \"Optional caption\"" >&2
  exit 1
fi

# lowercase, spaces+underscores -> hyphens, strip anything weird, force .jpg
base=$(basename "$SRC")
base="${base%.*}"
name=$(printf '%s' "$base" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' _' '--' \
  | sed 's/[^a-z0-9-]//g; s/--*/-/g; s/^-//; s/-$//')
[ -z "$name" ] && name="art"

out="art/$name.jpg"
i=2
while [ -e "$out" ]; do
  out="art/$name-$i.jpg"
  i=$((i+1))
done

sips -Z 1400 "$SRC" --out "$out" -s format jpeg -s formatOptions 80 >/dev/null

size=$(du -h "$out" | cut -f1)
echo ""
echo "✅ Saved $out ($size)"
echo ""
echo "Paste this into portfolio.html, inside <div class=\"gallery\">:"
echo "--------------------------------------------------------------"
echo "        <figure>"
echo "            <img src=\"$out\" alt=\"${CAPTION:-describe the artwork here}\">"
echo "            <figcaption>${CAPTION:-Add a caption}</figcaption>"
echo "        </figure>"
echo "--------------------------------------------------------------"
