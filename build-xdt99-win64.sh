#!/usr/bin/env bash
#
# Freeze xdt99's TI-99 tools — `xdm99` (disk manager) and `xhm99` (HFE
# converter) — into one self-contained Windows folder bundle the app downloads
# (WinSource::BundleFolder { dir: "xdt99" } in crates/gwm-core/src/tools.rs).
#
# xdt99 is pure Python and not on PyPI (its scripts are co-located and import a
# shared `xcommon`), so we fetch the release source and PyInstaller-freeze both
# entry points into a single onedir runtime — two `.exe`s next to a shared
# `_internal/`, so both land directly on PATH when the folder is hoisted. Must
# run on Windows (PyInstaller doesn't cross-build), so a windows-latest CI job
# invokes this, not the Linux one.
#
# GPL-3.0: the bundle carries the upstream license + a source note.
#
# Usage:  build-xdt99-win64.sh [OUTDIR]   (default OUTDIR=dist)
set -euo pipefail

XDT99_VER=3.6.5

OUT=$(cd "${1:-dist}" 2>/dev/null && pwd || (mkdir -p "${1:-dist}" && cd "${1:-dist}" && pwd))
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo ">> fetching xdt99 ${XDT99_VER}"
curl -fsSL -o xdt99.zip "https://github.com/endlos99/xdt99/archive/refs/tags/${XDT99_VER}.zip"
python -m zipfile -e xdt99.zip .
SRC="xdt99-${XDT99_VER}"

echo ">> installing pyinstaller"
python -m pip install --quiet --upgrade pip pyinstaller

# Two console exes sharing one onedir runtime → dist/xdt99/{xdm99,xhm99}.exe.
# `xcommon` is a sibling module both scripts import; pin it as a hidden import
# and add the source dir to the path so PyInstaller collects it.
cat > "$SRC/xdt99.spec" <<'PY'
a_dm = Analysis(['xdm99.py'], pathex=['.'], hiddenimports=['xcommon'])
a_hm = Analysis(['xhm99.py'], pathex=['.'], hiddenimports=['xcommon'])

pyz_dm = PYZ(a_dm.pure)
pyz_hm = PYZ(a_hm.pure)

exe_dm = EXE(pyz_dm, a_dm.scripts, [], exclude_binaries=True, name='xdm99', console=True)
exe_hm = EXE(pyz_hm, a_hm.scripts, [], exclude_binaries=True, name='xhm99', console=True)

# Merge the two analyses' runtime files, de-duped by destination so COLLECT
# doesn't choke on the shared Python DLL / stdlib both pull in.
_seen = set()
def _uniq(toc):
    out = []
    for entry in toc:
        dest = entry[0]
        if dest not in _seen:
            _seen.add(dest)
            out.append(entry)
    return out

COLLECT(
    exe_dm, exe_hm,
    _uniq(list(a_dm.binaries) + list(a_hm.binaries)),
    _uniq(list(a_dm.zipfiles) + list(a_hm.zipfiles)),
    _uniq(list(a_dm.datas) + list(a_hm.datas)),
    name='xdt99',
)
PY

echo ">> freezing xdm99 + xhm99 (onedir)"
( cd "$SRC" && python -m PyInstaller --noconfirm --clean xdt99.spec )

DIST="$SRC/dist/xdt99"
echo ">> sanity: both exes present"
ls "$DIST/xdm99.exe" "$DIST/xhm99.exe"

echo ">> packaging (GPL-3.0 license + source note)"
cp "$SRC/COPYING" "$DIST/LICENSE-xdt99.txt" 2>/dev/null \
  || curl -fsSL -o "$DIST/LICENSE-xdt99.txt" "https://www.gnu.org/licenses/gpl-3.0.txt" || true
cat > "$DIST/SOURCE.txt" <<EOF
This bundle contains xdt99 ${XDT99_VER} (GPL-3.0), frozen with PyInstaller.
Source: https://github.com/endlos99/xdt99  (tag ${XDT99_VER})
License: LICENSE-xdt99.txt
EOF

( cd "$SRC/dist" && python -m zipfile -c "$OUT/xdt99-win64.zip" xdt99 )
echo ">> wrote $OUT/xdt99-win64.zip"
ls -la "$OUT/xdt99-win64.zip"
