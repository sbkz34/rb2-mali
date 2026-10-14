#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/work"
bash RB2-Android/tools/android/prepare_sdk.sh
tail -3 rexglue-sdk-android/.android-patches/.applied
