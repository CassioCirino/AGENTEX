param(
  [string]$OutDir = "dist",
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$msbuild = $null
try {
  $cmd = Get-Command msbuild -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($cmd -ne $null) {
    $msbuild = $cmd.Source
  }
} catch {
}

if (-not $msbuild) {
  $candidates = @(
    "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v2.0.50727\MSBuild.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) {
      $msbuild = $c
      break
    }
  }
}

if (-not $msbuild) {
  Write-Host "MSBuild not found. Install Build Tools or .NET Framework SDK."
  exit 1
}

& $msbuild ".\src\DtLegacyAgent.csproj" /p:Configuration=$Configuration
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
Copy-Item -Force ".\src\bin\$Configuration\DtLegacyAgent.exe" "$OutDir\DtLegacyAgent.exe"
Copy-Item -Force ".\install.cmd" "$OutDir\install.cmd"
Copy-Item -Force ".\uninstall.cmd" "$OutDir\uninstall.cmd"
Copy-Item -Force ".\agent.conf.example" "$OutDir\agent.conf.example"

Write-Host "Package ready at $OutDir"
