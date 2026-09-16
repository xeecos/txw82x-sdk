@echo off
REM Activate the TXW82x / TXW828 development environment in the current cmd.exe session.
REM
REM   env.cmd
REM
REM No setlocal: the variables must survive the end of this script so the caller keeps them.
REM Nothing here is persistent; to get the toolchain in every new shell, add its bin
REM directory to your user PATH once - see ENVIRONMENT.md.

set "TXW_SDK_ROOT=D:\Projects\txw82x_sdk"
set "CSKY_TOOLCHAIN=D:\Projects\txw82x_sdk\txw_tools\csky-elfabiv2"
set "PATH=%CSKY_TOOLCHAIN%\bin;%PATH%"

echo TXW82x / TXW828 development environment
echo   SDK       : %TXW_SDK_ROOT%
echo   Toolchain : %CSKY_TOOLCHAIN%

REM Goto labels instead of parenthesised blocks: escaped parens inside a block are
REM fragile in cmd and silently broke the if/else below.
set "GCCVER="
for /f "delims=" %%v in ('"%CSKY_TOOLCHAIN%\bin\csky-elfabiv2-gcc.exe" --version 2^>nul') do if not defined GCCVER set "GCCVER=%%v"
if not defined GCCVER goto gcc_missing
echo   Compiler  : %GCCVER%
goto gdb_check
:gcc_missing
echo   Compiler  : NOT FOUND

:gdb_check
REM The standalone public toolchain ships gdb.exe without libexpat-1.dll, so gdb
REM cannot start until XuanTie CDK - which provides a complete toolchain - is installed.
REM Use "||" rather than "if errorlevel 1": a DLL load failure exits with the negative
REM NTSTATUS 0xC000007B, and "if errorlevel 1" only tests for >= 1, so it would not fire.
"%CSKY_TOOLCHAIN%\bin\csky-elfabiv2-gdb.exe" --version >nul 2>&1 || goto gdb_bad
echo   GDB       : ok
goto cdk_check
:gdb_bad
echo   GDB       : NOT USABLE - libexpat-1.dll missing, install XuanTie CDK

:cdk_check
if not defined CDK_ROOT goto cdk_missing
echo   CDK       : %CDK_ROOT%
goto end
:cdk_missing
echo   CDK       : not configured - set CDK_ROOT after installing XuanTie CDK

:end
