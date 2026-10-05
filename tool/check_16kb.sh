#!/usr/bin/env bash
# Verifies that a release APK is compatible with 16 KB memory page devices
# (required by Google Play for apps targeting Android 15+).
#
# Checks, in order:
#   1. native libraries are STORED (uncompressed) and 16 KB aligned in the zip
#   2. every ELF LOAD segment is aligned to at least 16 KB
#   3. the manifest declares extractNativeLibs="false"
#
# Usage: tool/check_16kb.sh [path/to/app-release.apk]

set -euo pipefail

APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
PAGE_SIZE=16384

[[ -f "$APK" ]] || { echo "APK not found: $APK" >&2; exit 1; }

pick_latest() { ls "$1" 2>/dev/null | sort -V | tail -1; }

BUILD_TOOLS="$SDK/build-tools/$(pick_latest "$SDK/build-tools")"
NDK="$SDK/ndk/$(pick_latest "$SDK/ndk")"
READELF=$(find "$NDK/toolchains/llvm/prebuilt" -name 'llvm-readelf' 2>/dev/null | head -1)

[[ -x "$BUILD_TOOLS/zipalign" ]] || { echo "zipalign not found under $SDK/build-tools" >&2; exit 1; }
[[ -x "$BUILD_TOOLS/aapt2" ]] || { echo "aapt2 not found under $SDK/build-tools" >&2; exit 1; }
[[ -n "$READELF" ]] || { echo "llvm-readelf not found under $SDK/ndk" >&2; exit 1; }

status=0

echo "==> 1/3  zip alignment (-P 16)"
if "$BUILD_TOOLS/zipalign" -c -P 16 -v 4 "$APK" >/dev/null 2>&1; then
  echo "    PASS  native libs are 16 KB aligned and uncompressed"
else
  echo "    FAIL  run: $BUILD_TOOLS/zipalign -c -P 16 -v 4 $APK"
  status=1
fi

echo "==> 2/3  ELF LOAD segment alignment"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
unzip -q "$APK" 'lib/*' -d "$workdir" 2>/dev/null || true

if [[ -d "$workdir/lib" ]]; then
  while IFS= read -r so; do
    # llvm-readelf prints the alignment as the last field, e.g. 0x10000.
    aligns=$("$READELF" -l "$so" | awk '/^ *LOAD/ { print $NF }')

    if [[ -z "$aligns" ]]; then
      echo "    FAIL  ${so#"$workdir"/} - could not read any LOAD segment"
      status=1
      continue
    fi

    bad=0
    for a in $aligns; do
      # Convert 0x-prefixed hex via bash arithmetic (macOS awk has no strtonum).
      if (( $((a)) % PAGE_SIZE != 0 )); then
        bad=1
      fi
    done

    if (( bad )); then
      echo "    FAIL  ${so#"$workdir"/} has a LOAD segment below 16 KB alignment"
      status=1
    else
      echo "    PASS  ${so#"$workdir"/} ($(echo "$aligns" | tr '\n' ' '))"
    fi
  done < <(find "$workdir/lib" -name '*.so' | sort)
else
  echo "    SKIP  no native libraries in this APK"
fi

echo "==> 3/3  extractNativeLibs"
# Capture first: piping straight into `grep -q` makes aapt2 die of SIGPIPE,
# which `set -o pipefail` would then report as a failed check.
manifest=$("$BUILD_TOOLS/aapt2" dump xmltree --file AndroidManifest.xml "$APK" 2>/dev/null || true)
if [[ "$manifest" == *"extractNativeLibs"*"=false"* ]]; then
  echo "    PASS  extractNativeLibs=false"
else
  echo "    FAIL  extractNativeLibs must be false"
  status=1
fi

echo
if (( status == 0 )); then
  echo "16 KB page size: COMPATIBLE"
else
  echo "16 KB page size: NOT COMPATIBLE"
fi
exit $status
