#!/usr/bin/env bash


# ctx.actions.run("gem", "install"...) doesn't work for JRuby

# Set environment variables.
export PATH={toolchain_bindir}:$PATH

{gem_binary} \
  install {gem} \
  --wrappers \
  --ignore-dependencies \
  --local \
  --no-document \
  --no-env-shebang \
  --install-dir {install_dir} \
  --bindir {install_dir}/bin \
  # --quiet \
  # --silent

# vim: ft=bash
