@echo off

set PATH={toolchain_bindir};%PATH%
set JAVA_HOME={java_home}

if "{gem}" == "external/bundle/vendor/cache/bundler-2.2.19.gem" (
  {gem_binary} ^
    install {gem} ^
    --wrappers ^
    --ignore-dependencies ^
    --local ^
    --no-document ^
    --no-env-shebang ^
    --install-dir {install_dir} ^
    --bindir {install_dir}/bin
)

:: vim: ft=dosbatch
