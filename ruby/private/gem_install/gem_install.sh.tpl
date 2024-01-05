#!/usr/bin/env bash


# ctx.actions.run("gem", "install"...) doesn't work for JRuby
#
export LANG=en_US.UTF-8

# Set environment variables.
export PATH={toolchain_bindir}:$PATH
export JAVA_HOME={java_home}
export JAVA_OPTS=-Djdk.io.File.enableADS=true


{gem_binary} \
  install {gem} \
  --wrappers \
  --ignore-dependencies \
  --local \
  --no-document \
  --no-env-shebang \
  --install-dir {install_dir} \
  --bindir {install_dir}/bin

# vim: ft=bash
