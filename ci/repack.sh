#!/usr/bin/env bash
set -euo pipefail
set -euo pipefail
NDK="$ANDROID_HOME/ndk/$NDK_VERSION"
BT="$ANDROID_HOME/build-tools/$BUILD_TOOLS"
STRIP="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
NM="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm"
W="$HOME/work/apk" && mkdir -p "$W/new/lib/arm64-v8a" "$W/old" && cd "$W"
curl -fsSL -o official.apk "$RELEASE_APK"
echo "$RELEASE_SHA256  official.apk" | sha256sum -c -
find_lib() { find "$HOME/work/native-build" "$HOME/work/rexglue-sdk-android/out" -name "$1" -type f 2>/dev/null | head -1 || true; }
for so in librexruntimerd.so librexgpu-xenosrd.so librb2probe.so; do
  src="$(find_lib "$so")"; [ -n "$src" ] || { echo "missing $so"; exit 1; }
  cp "$src" "new/lib/arm64-v8a/$so"
  "$STRIP" --strip-unneeded "new/lib/arm64-v8a/$so"
  unzip -q -o official.apk "lib/arm64-v8a/$so" -d old
  echo "== $so: official $(stat -c%s old/lib/arm64-v8a/$so) bytes, new $(stat -c%s new/lib/arm64-v8a/$so) bytes"
done
# Interface check: libmain.so (kept from the official APK) must find every symbol it uses.
unzip -q -o official.apk lib/arm64-v8a/libmain.so -d old
"$NM" -D --undefined-only old/lib/arm64-v8a/libmain.so | awk '{print $NF}' | sort -u > need.txt
"$NM" -D --defined-only old/lib/arm64-v8a/librexruntimerd.so | awk '{print $NF}' | sort -u > old_def.txt
"$NM" -D --defined-only new/lib/arm64-v8a/librexruntimerd.so | awk '{print $NF}' | sort -u > new_def.txt
comm -12 need.txt old_def.txt > need_from_runtime.txt
missing="$(comm -23 need_from_runtime.txt new_def.txt)"
echo "libmain.so uses $(wc -l < need_from_runtime.txt) runtime symbols"
if [ -n "$missing" ]; then echo "MISSING in rebuilt runtime:"; echo "$missing" | head -50; exit 1; fi
for so in librexgpu-xenosrd.so; do
  "$NM" -D --defined-only old/lib/arm64-v8a/$so | awk '{print $NF}' | sort -u > a.txt
  "$NM" -D --defined-only new/lib/arm64-v8a/$so | awk '{print $NF}' | sort -u > b.txt
  gone="$(comm -23 a.txt b.txt)"
  if [ -n "$gone" ]; then echo "Symbols gone from $so:"; echo "$gone" | head -50; exit 1; fi
done
# Proof that the rebuilt libraries carry the Mali patch.
grep -q "memory export will be skipped" new/lib/arm64-v8a/librexruntimerd.so || { echo "runtime lacks the patch"; exit 1; }
grep -q "Vertex shader memexport skipped" new/lib/arm64-v8a/librexgpu-xenosrd.so || { echo "GPU plugin lacks the patch"; exit 1; }
grep -q "vertex shader memory export is skipped" new/lib/arm64-v8a/librb2probe.so || { echo "probe lacks the patch"; exit 1; }
# Replace the libraries (stored, like the original), align and sign.
cp official.apk unsigned.apk
zip -q -d unsigned.apk 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.EC' 'META-INF/*.MF' || true
(cd new && zip -q -0 ../unsigned.apk lib/arm64-v8a/*.so)
"$BT/zipalign" -f -P 16 4 unsigned.apk aligned.apk
keytool -genkeypair -keystore rb2mali.jks -alias rb2mali -keyalg RSA -keysize 2048 \
  -validity 10000 -storepass rb2mali -keypass rb2mali -dname "CN=RB2 Mali" > /dev/null 2>&1
"$BT/apksigner" sign --ks rb2mali.jks --ks-pass pass:rb2mali --key-pass pass:rb2mali \
  --out RB2-Android-Mali.apk aligned.apk
"$BT/apksigner" verify --print-certs RB2-Android-Mali.apk | head -3
ls -la RB2-Android-Mali.apk
summary="patch strings found in all 3 libs; libmain needs $(wc -l < need_from_runtime.txt) runtime symbols, all present"
for so in librexruntimerd.so librexgpu-xenosrd.so librb2probe.so; do
  summary="$summary%0A$so: official $(stat -c%s old/lib/arm64-v8a/$so) B, new $(stat -c%s new/lib/arm64-v8a/$so) B"
done
summary="$summary%0AAPK sha256 $(sha256sum RB2-Android-Mali.apk | cut -c1-64), $(stat -c%s RB2-Android-Mali.apk) B"
echo "::notice title=Mali APK check::$summary"
