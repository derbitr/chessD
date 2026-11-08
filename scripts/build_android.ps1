# Script de compilacao para Android do chessD
$ErrorActionPreference = "Stop"

if (-not (Get-Command cargo-ndk -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando cargo-ndk..."
    cargo install cargo-ndk
}

Write-Host "Configurando targets do Rust..."
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

$jniLibsDir = "$PSScriptRoot\..\android\app\src\main\jniLibs"
New-Item -ItemType Directory -Force -Path "$jniLibsDir\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsDir\armeabi-v7a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsDir\x86_64" | Out-Null

Write-Host "Compilando bibliotecas nativas Rust para Android..."
Set-Location "$PSScriptRoot\..\rust_core"
cargo ndk -t arm64-v8a -o "$jniLibsDir" build --release
cargo ndk -t armeabi-v7a -o "$jniLibsDir" build --release
cargo ndk -t x86_64 -o "$jniLibsDir" build --release

Write-Host "Compilando Flutter APK Release..."
Set-Location "$PSScriptRoot\.."
flutter build apk --release

Write-Host "APK gerado com sucesso em: build\app\outputs\flutter-apk\app-release.apk"
