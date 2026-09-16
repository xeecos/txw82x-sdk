# Build the TXW82x dual-core firmware from the command line.
#
#   .\build.ps1                 # build Core then App, config FLASH
#   .\build.ps1 -Clean          # clean instead of build
#   .\build.ps1 -CdkRoot D:\C-SKY\CDK
#
# Requires XuanTie CDK (cdk-make.exe). See ENVIRONMENT.md for how to install it.
#
# The build order matters: txw82xApp links and packs against the CPU1 core image,
# its BSS boundary and its CRC, so txw82xCore must be built first. Building only
# the App leaves a stale core inside the firmware image.

param(
    [string]$CdkRoot = $env:CDK_ROOT,
    [string]$Config  = 'FLASH',
    [switch]$Clean,
    [string]$SdkRoot = 'D:\Projects\txw82x_sdk'
)

$ErrorActionPreference = 'Stop'

if (-not $CdkRoot) {
    foreach ($candidate in @('D:\C-SKY\CDK', 'C:\C-SKY\CDK', 'C:\XuanTie\CDK')) {
        if (Test-Path (Join-Path $candidate 'cdk-make.exe')) { $CdkRoot = $candidate; break }
    }
}

if (-not $CdkRoot -or -not (Test-Path (Join-Path $CdkRoot 'cdk-make.exe'))) {
    throw "cdk-make.exe not found. Install XuanTie CDK and pass -CdkRoot <path>, or set `$env:CDK_ROOT."
}

$cdkMake = Join-Path $CdkRoot 'cdk-make.exe'
$action  = if ($Clean) { 'clean' } else { 'build' }

$projects = @(
    @{ Name = 'txw82xCore'; Path = Join-Path $SdkRoot 'project\txw82xCore\txw82xCore.cdkproj' },  # CPU1 - build first
    @{ Name = 'txw82xApp';  Path = Join-Path $SdkRoot 'project\txw82xApp\txw82xApp.cdkproj'  }   # CPU0 - links core image
)

foreach ($proj in $projects) {
    if (-not (Test-Path $proj.Path)) { throw "Project file not found: $($proj.Path)" }
    Write-Host "==> $action $($proj.Name) ($Config)" -ForegroundColor Cyan
    & $cdkMake -p $proj.Path -d $action -c $Config
    if ($LASTEXITCODE -ne 0) {
        throw "cdk-make failed for $($proj.Name) with exit code $LASTEXITCODE"
    }
}

if (-not $Clean) {
    Write-Host ''
    Write-Host 'Build finished. Firmware images are written under project\' -ForegroundColor Green
    Get-ChildItem (Join-Path $SdkRoot 'project') -Filter '*.bin' -ErrorAction SilentlyContinue |
        Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
}
