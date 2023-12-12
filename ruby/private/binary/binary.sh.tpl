#!/usr/bin/env bash

{rlocation_function}

realpath() (
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
)
export RUNFILES_DIR="$(realpath "${RUNFILES_DIR:-$0.runfiles}")"

# Find location of JAVA_HOME in runfiles.
if [ -n "{java_bin}" ]; then
  export JAVA_HOME=$(dirname $(dirname $(rlocation "{java_bin}")))
fi

# Set environment variables.
export PATH={toolchain_bindir}:$PATH
{env}

if [ -n "{bundler_command}" ]; then
  export BUNDLE_GEMFILE=$(rlocation $BUNDLE_GEMFILE)
  export BUNDLE_PATH=$(rlocation $BUNDLE_PATH)
fi

{bundler_command} {ruby_binary_name} {binary} {args} "$@"

# vim: ft=bash
