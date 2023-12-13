@echo on

set BUNDLE_ALLOW_OFFLINE_INSTALL=true
set BUNDLE_BIN={binstubs_path}
set BUNDLE_DEPLOYMENT=true
set BUNDLE_DISABLE_SHARED_GEMS=true
set BUNDLE_FROZEN=true
set BUNDLE_GEMFILE={gemfile_path}
set BUNDLE_IGNORE_CONFIG=true
set BUNDLE_PATH={bundle_path}
set BUNDLE_SHEBANG={ruby_path}
set BUNDLE_USER_HOME={home_path}
set GEM_PATH={gem_path}
set PATH={path};%PATH%

{ruby_path} {bundler_path} install --full-index

:: vim: ft=dosbatch
