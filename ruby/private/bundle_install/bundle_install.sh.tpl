#!/usr/bin/env bash

# export BUNDLE_BIN="bazel-out/darwin_arm64-fastbuild/bin/external/bundle_fetch/bin"
# # export BUNDLE_DEPLOYMENT="true"
# export BUNDLE_GEMFILE="external/bundle_fetch/Gemfile"
# export BUNDLE_PATH="../../bazel-out/darwin_arm64-fastbuild/bin/external/bundle_fetch/vendor/bundle"
# export BUNDLE_CACHE_PATH="../../bazel-out/darwin_arm64-fastbuild/bin/external/bundle_fetch/vendor/cache"
# export BUNDLE_SHEBANG="external/rules_ruby_dist/dist/bin/ruby"

# cp -r "bazel-out/darwin_arm64-fastbuild/bin/external/bundle_fetch/vendor" external/bundle_fetch/
# ls -l external/bundle_fetch/

# cp -r {config_path} .
# cp -r {config_path} external/bundle_fetch

external/rules_ruby_dist/dist/bin/bundle install --local --no-cache

# vim: ft=bash
