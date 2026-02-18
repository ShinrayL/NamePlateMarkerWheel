# NamePlateMarkerWheel - Sync to WoW (Simple Version)

$Src = "$PSScriptRoot\src"

# 检测 WoW 路径
$Dest = $null
$TestPaths = @(
    "F:\World of Warcraft\_retail_\Interface\AddOns\NamePlateMarkerWheel"
)

foreach ($path in $TestPaths) {
    if (Test-Path (Split-Path $path)) {
        $Dest = $path
        break
    }
}

if (-not $Dest) {
    $Dest = $TestPaths[0]
}

Write-Host "Source: $Src"
Write-Host "Destination: $Dest"

if (-not (Test-Path $Dest)) {
    New-Item -ItemType Directory -Path $Dest -Force
}

Copy-Item "$Src\*.lua" $Dest -Force
Copy-Item "$Src\*.toc" $Dest -Force

Write-Host "Sync completed!"
