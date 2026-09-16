# Fetch and verify the toolchain the SDK needs but that is not committed to git.
#
#   .\setup_tools.ps1
#
# Downloads the XuanTie C-SKY GCC toolchain and the XuanTie DebugServer package into
# txw_tools\dl, checks each SHA256 against the value published in the vendor's README,
# then extracts them into txw_tools. Safe to re-run: anything already in place is skipped.
#
# This does NOT install XuanTie CDK. CDK is required to actually build the SDK and is a
# manual download - see ENVIRONMENT.md section 5.

$ErrorActionPreference = 'Stop'

$Root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Tools = Join-Path $Root 'txw_tools'
$Dl    = Join-Path $Tools 'dl'

$Artifacts = @(
    @{
        Label  = 'XuanTie C-SKY GCC toolchain (Windows MinGW, minilibc)'
        Url    = 'https://github.com/Taixin-Semiconductor/XuanTie-CSKY-Toolchains/raw/master/csky-elfabiv2-tools-mingw-minilibc-20250328.tar.gz'
        Sha256 = '3EB0FA8681F0996136902171855DB974659674ED3D6EBE7DDC6A601DDC0F27F2'
        Local  = Join-Path $Dl 'csky-toolchain.tgz'
        Target = Join-Path $Tools 'csky-elfabiv2'
        Kind   = 'tar'
    },
    @{
        Label  = 'XuanTie DebugServer V5.18.10 (Windows installer)'
        Url    = 'https://github.com/Taixin-Semiconductor/XuanTie-DebugServer/raw/master/XuanTie-DebugServer-windows-V5.18.10-20260603-2008.zip'
        Sha256 = '588C5919441C9D6D5CFC18CAB2DB88147ACAB57ABBC06FDD437DBB6B6AC10C8F'
        Local  = Join-Path $Dl 'debugserver.zip'
        Target = Join-Path $Tools 'xuantie-debugserver'
        Kind   = 'zip'
    }
)

New-Item -ItemType Directory -Force -Path $Dl | Out-Null

foreach ($a in $Artifacts) {
    Write-Host "==> $($a.Label)" -ForegroundColor Cyan

    if (Test-Path $a.Local) {
        Write-Host '    archive already present, skipping download'
    } else {
        Write-Host '    downloading...'
        Invoke-WebRequest -Uri $a.Url -OutFile $a.Local -UseBasicParsing
    }

    $actual = (Get-FileHash -Path $a.Local -Algorithm SHA256).Hash
    if ($actual -ne $a.Sha256) {
        throw "SHA256 mismatch for $($a.Local)`n  expected: $($a.Sha256)`n  actual:   $actual"
    }
    Write-Host '    sha256 ok'

    if (Test-Path $a.Target) {
        Write-Host "    already extracted at $($a.Target), skipping"
        continue
    }

    if ($a.Kind -eq 'tar') {
        New-Item -ItemType Directory -Force -Path $a.Target | Out-Null
        tar -xzf $a.Local -C $a.Target
        if ($LASTEXITCODE -ne 0) { throw "tar extraction failed with exit code $LASTEXITCODE" }
    } else {
        Expand-Archive -Path $a.Local -DestinationPath $a.Target -Force
    }
    Write-Host "    extracted to $($a.Target)"
}

Write-Host ''
Write-Host 'Toolchain ready.' -ForegroundColor Green
Write-Host 'Next: . .\env.ps1   then   .\build.ps1' -ForegroundColor Green
Write-Host 'Reminder: building also needs XuanTie CDK - see ENVIRONMENT.md section 5.' -ForegroundColor Yellow
