@echo off

set PATH={toolchain_bindir};%PATH%
set JAVA_HOME={java_home}
set JAVA_OPTS=-Djdk.io.File.enableADS=true

{gem_binary} ^
  install {gem} ^
  --wrappers ^
  --ignore-dependencies ^
  --local ^
  --no-document ^
  --no-env-shebang ^
  --install-dir {install_dir} ^
  --bindir {install_dir}/bin

:: vim: ft=dosbatch
