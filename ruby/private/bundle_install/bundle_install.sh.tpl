#!/usr/bin/env bash

export BUNDLE_ALLOW_OFFLINE_INSTALL="true"
export BUNDLE_BIN={binstubs_path}
export BUNDLE_DEPLOYMENT="true"
export BUNDLE_DISABLE_SHARED_GEMS="true"
export BUNDLE_FROZEN="true"
export BUNDLE_GEMFILE={gemfile_path}
export BUNDLE_IGNORE_CONFIG="true"
export BUNDLE_PATH={bundle_path}
export BUNDLE_SHEBANG={ruby_path}
export BUNDLE_USER_HOME={home_path}
export GEM_PATH={gem_path}
export PATH={path}:$PATH

{ruby_path} {bundler_path} install --full-index

# vim: ft=bash
