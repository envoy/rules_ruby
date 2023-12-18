#!/usr/bin/env bash

set -euo pipefail

# # --- begin runfiles.bash initialization v2 ---
# set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
# source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
# source "$0.runfiles/$f" 2>/dev/null || \
# source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
# source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
# { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# # --- end runfiles.bash initialization v2 ---

# export RUNFILES_DIR="${RUNFILES_DIR:-$0.runfiles}"
# ls -al $RUNFILES_DIR


# export BUNDLE_FROZEN="true"
# export BUNDLE_PATH={bundle_path}
# export BUNDLE_ALLOW_OFFLINE_INSTALL="true"
export BUNDLE_BIN={binstubs_path}
export BUNDLE_CACHE_PATH=$(realpath {cache_path})
export BUNDLE_DEPLOYMENT=1
# export BUNDLE_DISABLE_SHARED_GEMS="true"
export BUNDLE_GEMFILE={gemfile_path}
# export BUNDLE_IGNORE_CONFIG="true"
# export BUNDLE_SHEBANG={ruby_path}
export BUNDLE_USER_HOME=$(pwd)
# export GEM_PATH={gem_path}
export PATH={path}:$PATH

# ls -al $BUNDLE_CACHE_PATH

{ruby_path} {bundler_path} install --local

cp -R $(dirname {gemfile_path})/vendor/bundle/ {bundle_path}


# vim: ft=bash
