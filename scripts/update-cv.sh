#!/bin/zsh
# Rebuild the site CV from the Overleaf project synced to Dropbox.
#
#   scripts/update-cv.sh          compile, refresh cv/, then show what changed
#   scripts/update-cv.sh --push   ...and commit + push, which publishes the site
#
# Writes cv/cv.pdf (download), cv/page-N.png (the pages shown on the CV page),
# and research/index.qmd (generated from the CV's Publications, Working Papers
# and Presentations sections).
set -euo pipefail

SRC="${CV_SRC:-$HOME/Library/CloudStorage/Dropbox/Apps/Overleaf/CV/main.tex}"
SITE="${0:A:h:h}"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH"

cp "$SRC" "$BUILD/main.tex"
(cd "$BUILD" && latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex >/dev/null) \
  || { echo "LaTeX failed; see $BUILD/main.log"; trap - EXIT; exit 1; }

setopt null_glob
rm -f "$SITE"/cv/page-*.png
cp "$BUILD/main.pdf" "$SITE/cv/cv.pdf"
pdftocairo -png -r 170 "$BUILD/main.pdf" "$SITE/cv/page"
# pdftocairo pads page numbers (page-1 or page-01); normalize to page-N.png
for f in "$SITE"/cv/page-*.png; do
  n="${${f:t:r}#page-}"; mv -f "$f" "$SITE/cv/page-$((10#$n)).png" 2>/dev/null || true
done

# list the pages for cv/index.qmd to include
: > "$SITE/cv/_pages.md"
for i in $(seq 1 $(ls "$SITE"/cv/page-*.png | wc -l)); do
  echo "![](page-$i.png){.cv-page fig-alt=\"CV page $i\" loading=\"lazy\"}" >> "$SITE/cv/_pages.md"
  echo >> "$SITE/cv/_pages.md"
done

python3 "$SITE/scripts/cv_to_research.py" "$SRC" "$SITE/research/index.qmd"

echo "CV updated: $(ls "$SITE"/cv/page-*.png | wc -l | tr -d ' ') page(s)"
git -C "$SITE" status --short cv/ research/

if [[ "${1:-}" == "--push" ]]; then
  git -C "$SITE" add cv/ research/
  git -C "$SITE" commit -m "Update CV and Research page from Overleaf" && git -C "$SITE" push
fi
