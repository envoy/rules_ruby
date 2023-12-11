@echo off
setlocal enableextensions enabledelayedexpansion

{rlocation_function}
set RUNFILES_MANIFEST_ONLY=1

:: Find location of JAVA_HOME in runfiles.
if "{java_bin}" neq "" (
  call :rlocation {java_bin} java_bin
  for %%a in ("%java_bin%\..\..") do set JAVA_HOME=%%~fa
)

:: Set environment variables.
set PATH={toolchain_bindir};%PATH%
{env}

if "{bundler_command}" neq "" (
  call :rlocation %BUNDLE_GEMFILE% BUNDLE_GEMFILE
  call :rlocation %BUNDLE_PATH% BUNDLE_PATH
)

{bundler_command} {ruby_binary_name} {binary} {args} %*

:: vim: ft=dosbatch
