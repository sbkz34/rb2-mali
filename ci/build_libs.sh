#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/work/RB2-Android"
# The native CMake project only reaches the SDK when generated game sources exist.
# Give it a placeholder so it configures; libmain.so is never built.
GEN="$HOME/work/fake-gen"
mkdir -p "$GEN"
echo 'set(GENERATED_SOURCES "${CMAKE_CURRENT_LIST_DIR}/placeholder.cpp")' > "$GEN/sources.cmake"
echo '// placeholder' > "$GEN/placeholder.cpp"
echo '#pragma once' > "$GEN/rb2_pch.h"
NDK="$ANDROID_HOME/ndk/$NDK_VERSION"
CMAKE="$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/cmake"
OUT="$HOME/work/native-build"
FLAGS="-O3 -mtune=cortex-a715 -g -DNDEBUG"   # same as tools/android/build_native.sh
"$CMAKE" -S android/native -B "$OUT" -G Ninja \
  -DCMAKE_MAKE_PROGRAM="$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/ninja" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-29 -DANDROID_STL=c++_shared \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_C_FLAGS_RELWITHDEBINFO="$FLAGS" -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="$FLAGS" \
  -DTHPS_GEN_DIR="$GEN" -DTHPS_SDK="$HOME/work/rexglue-sdk-android"
"$CMAKE" --build "$OUT" --parallel "$(nproc)" --target rexruntime rexgpu-xenos rb2probe
