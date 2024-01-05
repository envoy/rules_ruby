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
# export BUNDLE_ALLOW_OFFLINE_INSTALL="true"
export BUNDLE_BIN={binstubs_path}
# export BUNDLE_CACHE_PATH={cache_path}
export BUNDLE_DEPLOYMENT=1
export BUNDLE_DISABLE_SHARED_GEMS=1
export BUNDLE_DISABLE_VERSION_CHECK=1
export BUNDLE_GEMFILE={gemfile_path}
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_PATH={bundle_path}
export BUNDLE_SHEBANG={ruby_path}
# export BUNDLE_USER_HOME=$(pwd)
# export GEM_PATH={gem_path}
export PATH={path}:$PATH
export JAVA_HOME={java_home}
export JAVA_OPTS=-Djdk.io.File.enableADS=true


export LANG=en_US.UTF-8

{ruby_path} {bundler_path} install --local

# {bundler_path} --version
# {bundler_path} _2.2.3_ --version
# exit 1
# {bundler_path} _2.2.19_ install --local

# vim: ft=bash
