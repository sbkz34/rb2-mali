#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/work" && cd "$HOME/work"
git clone "$UPSTREAM" RB2-Android
cd RB2-Android
git checkout -q "$UPSTREAM_COMMIT"
git -c user.name=ci -c user.email=ci@localhost am "$GITHUB_WORKSPACE/patches/rb2-android-mali-support.patch"
git log --oneline -2
# The SDK derives its version from `git describe` in CMAKE_SOURCE_DIR (this repo, android/native);
# this repo's v1.2.x tags would read as an SDK version above its 0.10 floor and stop CMake.
git tag -l | xargs -r git tag -d > /dev/null
