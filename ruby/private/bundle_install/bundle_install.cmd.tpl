@echo off

REM set BUNDLE_ALLOW_OFFLINE_INSTALL=true
set BUNDLE_BIN={binstubs_path}
set BUNDLE_DEPLOYMENT=1
set BUNDLE_DISABLE_SHARED_GEMS=1
set BUNDLE_DISABLE_VERSION_CHECK=1
REM set BUNDLE_FROZEN=true
set BUNDLE_GEMFILE={gemfile_path}
set BUNDLE_IGNORE_CONFIG=1
set BUNDLE_PATH={bundle_path}
set BUNDLE_SHEBANG={ruby_path}
REM set BUNDLE_USER_HOME={home_path}
REM set GEM_PATH={gem_path}
set PATH={path};%PATH%

{ruby_path} {bundler_path} install --local

:: vim: ft=dosbatch
