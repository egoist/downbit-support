#!/usr/bin/env bash
# Fetches the FFmpeg builds of the platforms Downbit runs on, checks each
# against the SHA-256 sum its source publishes, and repackages its ffmpeg
# alone as ffmpeg-<os>-<arch>.zip, with checksums.sha256 of them, the tag of
# the release (ffmpeg-<version>) and its notes, in the folder given.
#
# macOS and Linux: Martin Riedl's release builds, signed and notarized.
# Windows: BtbN's GPL builds of the same release branch.
set -euo pipefail

out=$(realpath -m "${1:-out}")
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

riedl=https://ffmpeg.martin-riedl.de/redirect/latest
btbn=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest

get() { curl -fsSL --retry 4 --retry-delay 5 "$@"; }

# check FILE SUM: the file's SHA-256 is SUM.
check() {
  local got
  got=$(sha256sum "$1" | cut -d' ' -f1)
  if [[ "$got" != "${2,,}" ]]; then
    echo "$1: SHA-256 $got, its source says $2" >&2
    exit 1
  fi
}

# repackage ZIP NAME BINARY: the archive's BINARY alone, as NAME.zip.
repackage() {
  local dir="$work/$2"
  mkdir -p "$dir"
  unzip -q "$1" -d "$dir"
  local bin
  bin=$(find "$dir" -type f -name "$3" -print -quit)
  if [[ -z "$bin" ]]; then
    echo "$1 has no $3" >&2
    exit 1
  fi
  chmod 755 "$bin"
  file "$bin"
  (cd "$(dirname "$bin")" && zip -q -X -9 "$out/$2.zip" "$3")
}

notes="$work/sources.md"
: >"$notes"

# Martin Riedl's: the latest release's URL redirects to the build's own,
# whose sum is beside it, as .sha256.
for p in macos/arm64:darwin-arm64 macos/amd64:darwin-amd64 linux/amd64:linux-amd64 linux/arm64:linux-arm64; do
  src=${p%%:*} name=ffmpeg-${p##*:}
  url=$(curl -fsSLI --retry 4 -o /dev/null -w '%{url_effective}' "$riedl/$src/release/ffmpeg.zip")
  get -o "$work/$name.src.zip" "$url"
  sum=$(get "$url.sha256" | grep -m 1 -oiE '\b[0-9a-f]{64}\b')
  check "$work/$name.src.zip" "$sum"
  repackage "$work/$name.src.zip" "$name" ffmpeg
  echo "- \`$name.zip\`: $url (SHA-256 \`$sum\`)" >>"$notes"
done

# The version, of the build this runner runs.
unzip -q -o "$out/ffmpeg-linux-amd64.zip" -d "$work/run"
first=$("$work/run/ffmpeg" -version | sed -n 1p)
version=$(sed -E 's/^ffmpeg version n?([0-9][0-9.]*).*/\1/' <<<"$first")
if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  echo "can't tell the version: $first" >&2
  exit 1
fi
branch=$(echo "$version" | cut -d. -f1-2)

# BtbN's: the latest build of the same release branch, its sum in the
# release's list.
get -o "$work/btbn.sha256" "$btbn/checksums.sha256"
for p in win64:windows-amd64 winarm64:windows-arm64; do
  src=ffmpeg-n$branch-latest-${p%%:*}-gpl-$branch.zip name=ffmpeg-${p##*:}
  sum=$(awk -v n="$src" '$2 == n || $2 == "*" n { print $1 }' "$work/btbn.sha256")
  if [[ -z "$sum" ]]; then
    echo "BtbN has no $src: its builds are $(awk '{ print $2 }' "$work/btbn.sha256" | grep -E 'win(arm)?64-gpl-[0-9]' | tr '\n' ' ')" >&2
    exit 1
  fi
  get -o "$work/$name.src.zip" "$btbn/$src"
  check "$work/$name.src.zip" "$sum"
  repackage "$work/$name.src.zip" "$name" ffmpeg.exe
  echo "- \`$name.zip\`: $btbn/$src (SHA-256 \`$sum\`)" >>"$notes"
done

(cd "$out" && sha256sum ffmpeg-*.zip >checksums.sha256)
echo "ffmpeg-$version" >"$out/tag"
cat >"$out/notes.md" <<NOTES
FFmpeg $version, for Downbit to convert with: each archive holds \`ffmpeg\` alone (\`ffmpeg.exe\` on Windows), as built upstream, checked against the SHA-256 sum its source publishes. FFmpeg is licensed under the GPL; its source is at https://ffmpeg.org/releases/ffmpeg-$version.tar.xz.

Sources:
$(cat "$notes")

SHA-256 of these archives:
\`\`\`
$(cat "$out/checksums.sha256")
\`\`\`
NOTES
cat "$out/notes.md"
