#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/work" && cd "$HOME/work"
git clone "$UPSTREAM" RB2-Android
cd RB2-Android
git checkout -q "$UPSTREAM_COMMIT"
git -c user.name=ci -c user.email=ci@localhost am "$GITHUB_WORKSPACE/patches/rb2-android-mali-support.patch"
git log --oneline -2
