#!/usr/bin/env bash


# ctx.actions.run("gem", "install"...) doesn't work for JRuby
#
export LANG=en_US.UTF-8

# Set environment variables.
export PATH={toolchain_bindir}:$PATH

if [ '{gem}' = 'external/bundle/vendor/cache/bundler-2.1.4.gem' ]; then
  {gem_binary} \
    install {gem} \
    --wrappers \
    --ignore-dependencies \
    --local \
    --no-document \
    --no-env-shebang \
    --install-dir {install_dir} \
    --bindir {install_dir}/bin \
    --quiet \
    --silent
fi

# vim: ft=bash
