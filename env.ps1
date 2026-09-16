# Activate the TXW82x / TXW828 development environment in the current PowerShell session.
#
#   . .\env.ps1          (dot-source it so the current session keeps the variables)
#
# Nothing here is persistent: to make the toolchain available in every new shell,
# add the toolchain bin directory to your user PATH once - see ENVIRONMENT.md.

$ErrorActionPreference = 'Stop'

$ToolchainRoot = 'D:\Projects\txw82x_sdk\txw_tools\csky-elfabiv2'
$SdkRoot       = 'D:\Projects\txw82x_sdk'

$env:TXW_SDK_ROOT   = $SdkRoot
$env:CSKY_TOOLCHAIN = $ToolchainRoot
$env:Path           = "$ToolchainRoot\bin;$env:Path"

Write-Host 'TXW82x / TXW828 development environment' -ForegroundColor Cyan
Write-Host "  SDK       : $SdkRoot"
Write-Host "  Toolchain : $ToolchainRoot"

$gcc = Join-Path $ToolchainRoot 'bin\csky-elfabiv2-gcc.exe'
if (Test-Path $gcc) {
    $ver = & $gcc --version | Select-Object -First 1
    Write-Host "  Compiler  : $ver"
} else {
    Write-Warning "Compiler not found at $gcc"
}

# The standalone public toolchain ships gdb.exe without libexpat-1.dll, so gdb
# cannot start until XuanTie CDK (which provides a complete toolchain) is installed.
$gdb = Join-Path $ToolchainRoot 'bin\csky-elfabiv2-gdb.exe'
if (Test-Path $gdb) {
    $null = & $gdb --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host '  GDB       : NOT USABLE - libexpat-1.dll missing (install XuanTie CDK)' -ForegroundColor Yellow
    } else {
        Write-Host '  GDB       : ok'
    }
}

if ($env:CDK_ROOT) {
    Write-Host "  CDK       : $env:CDK_ROOT"
} else {
    Write-Host '  CDK       : not configured (set CDK_ROOT after installing XuanTie CDK)' -ForegroundColor Yellow
}
