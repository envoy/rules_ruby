#!/usr/bin/env bash


# ctx.actions.run("gem", "install"...) doesn't work for JRuby
#
export LANG=en_US.UTF-8

# Set environment variables.
export PATH={toolchain_bindir}:$PATH

if [ '{gem}' = 'external/bundle/vendor/cache/bundler-2.2.19.gem' ]; then
  {gem_binary} \
    install {gem} \
    --local \
    --quiet \
    --silent
fi

# vim: ft=bash
