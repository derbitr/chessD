# Script de compilacao para Windows do chessD
param (
    [string]$Version = "v1.0.4"
)
$ErrorActionPreference = "Stop"

Write-Host "Iniciando compilacao do Rust Core..."
Set-Location "$PSScriptRoot\..\rust_core"
cargo build --release

Write-Host "Compilando Flutter Windows Release..."
Set-Location "$PSScriptRoot\.."
flutter build windows --release

Write-Host "Copiando rust_core.dll para a pasta de release..."
$releaseDir = "$PSScriptRoot\..\build\windows\x64\runner\Release"
Copy-Item "$PSScriptRoot\..\rust_core\target\release\rust_core.dll" -Destination "$releaseDir\rust_core.dll" -Force

Write-Host "Criando pacote zip portatil..."
$zipPath = "$PSScriptRoot\..\build\chessD-$Version-windows-x64.zip"
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force

Write-Host "Concluido com sucesso: $zipPath"
