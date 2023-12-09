#!/usr/bin/env bash

{rlocation_function}

# Find location of JAVA_HOME in runfiles.
if [ -n "{java_bin}" ]; then
  export JAVA_HOME=$(dirname $(dirname $(rlocation "{java_bin}")))
fi

# Set environment variables.
export PATH={toolchain_bindir}:$PATH
{env}

if [ -n "{bundler_command}" ]; then
  export BUNDLE_DEPLOYMENT=true
  export BUNDLE_GEMFILE=$(rlocation $BUNDLE_GEMFILE)
  export BUNDLE_PATH=$(rlocation $BUNDLE_PATH)/bundle
fi

{bundler_command} {ruby_binary_name} {binary} {args} $@

# vim: ft=bash
