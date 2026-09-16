# Activate the TXW82x / TXW828 development environment in the current PowerShell session.
#
#   . .\env.ps1          (dot-source it so the current session keeps the variables)
#
# Nothing here is persistent: to make the toolchain available in every new shell,
# add the toolchain bin directory to your user PATH once - see ENVIRONMENT.md.

$ErrorActionPreference = 'Stop'

$ToolchainRoot = 'D:\Projects\txw82x_sdk\txw_tools\csky-elfabiv2'
$SdkRoot       = 'D:\Projects\txw82x_sdk'

# XuanTie CDK is required to build the SDK. Needed here for two things: reporting
# whether it is present, and locating the 32-bit libexpat-1.dll that gdb needs.
$CdkRoot = $env:CDK_ROOT
if (-not $CdkRoot) {
    foreach ($candidate in @('D:\C-SKY\CDK', 'C:\C-SKY\CDK', 'C:\XuanTie\CDK')) {
        if (Test-Path (Join-Path $candidate 'cdk-make.exe')) { $CdkRoot = $candidate; break }
    }
}
if ($CdkRoot) { $env:CDK_ROOT = $CdkRoot }

$env:TXW_SDK_ROOT   = $SdkRoot
$env:CSKY_TOOLCHAIN = $ToolchainRoot
$env:Path           = "$ToolchainRoot\bin;$env:Path"

# The standalone toolchain's gdb.exe is a 32-bit build needing libexpat-1.dll, which that
# package does not ship; CDK installs a matching 32-bit copy under its MinGW runtime.
# Appended rather than prepended so CDK's make.exe and DLLs cannot shadow anything else
# on PATH - Windows searches the whole PATH when resolving a dependent DLL.
$cskyMinGW = if ($CdkRoot) { Join-Path $CdkRoot 'CSKY\MinGW\bin' }
if ($cskyMinGW -and (Test-Path $cskyMinGW)) { $env:Path = "$env:Path;$cskyMinGW" }

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

$gdb = Join-Path $ToolchainRoot 'bin\csky-elfabiv2-gdb.exe'
if (Test-Path $gdb) {
    $gdbVer = & $gdb --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  GDB       : $gdbVer"
    } else {
        Write-Host '  GDB       : NOT USABLE - libexpat-1.dll missing (install XuanTie CDK)' -ForegroundColor Yellow
    }
}

if ($CdkRoot) {
    Write-Host "  CDK       : $CdkRoot"
} else {
    Write-Host '  CDK       : not found - required to build, see ENVIRONMENT.md section 5' -ForegroundColor Yellow
}
