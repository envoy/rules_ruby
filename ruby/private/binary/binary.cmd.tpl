@echo off
setlocal enableextensions enabledelayedexpansion

set RUNFILES_MANIFEST_ONLY=1
{rlocation_function}



:: Find location of JAVA_HOME in runfiles.
@REM if "{java_bin}" neq "" (
  call :rlocation {java_bin} java_bin
  for %%a in ("%java_bin%\..\..") do set JAVA_HOME=%%~fa
  echo "foo"
  echo "%java_bin%"
  echo "%JAVA_HOME%"
@REM )
  @REM echo "%java_bin%"
  @REM echo "%JAVA_HOME%"
@REM dir external\remotejdk11_win_arm64\bin\
@REM echo {java_bin}


@REM :: Set environment variables.
set PATH={toolchain_bindir};%PATH%
{env}

@REM if "{bundler_command}" neq "" (
    echo "%BUNDLE_PATH%"

  call :rlocation %BUNDLE_GEMFILE% BUNDLE_GEMFILE
  call :rlocation %BUNDLE_PATH% BUNDLE_PATH


  dir "%BUNDLE_PATH%"
  @REM exit 1
@REM )

{bundler_command} {ruby_binary_name} {binary} {args} %*

:: vim: ft=dosbatch
