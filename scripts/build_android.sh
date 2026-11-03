#!/bin/bash
# Build SMM2 Recomp for Android arm64 from your own dump.
# Edit the paths below (or export them before running).
# Linux/WSL2: the defaults work. macOS: set JAVA_HOME and ANDROID_NDK explicitly.
set -euo pipefail

REPO=${REPO:-$HOME/smm2recomp}
ANDROID_HOME=${ANDROID_HOME:-$HOME/android-sdk}
ANDROID_NDK=${ANDROID_NDK:-$ANDROID_HOME/ndk/29.0.14206865}
DEPS=${DEPS:-$HOME/smm2-build/deps-android-arm64}
ADRENOTOOLS_DIR=${ADRENOTOOLS_DIR:-$HOME/smm2-build/libadrenotools/build-android}
VULKAN_SHIM=${VULKAN_SHIM:-$HOME/smm2-build/vulkan-shim/libvulkanshim.so}
JOBS=${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}
JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}

export ANDROID_HOME ANDROID_NDK JAVA_HOME
export PATH="$ANDROID_HOME/platform-tools:$PATH"

cd "$REPO"

[ -f recomp/private/smm2/extracted/exefs/main ] || {
    echo "Falta el dump: recomp/private/smm2/extracted/exefs/main"
    echo "Corré el paso 4 de PROMPT.md (setup del dump) primero."
    exit 1
}
[ -f "$VULKAN_SHIM" ] || {
    echo "Falta VULKAN_SHIM=$VULKAN_SHIM"
    echo "Compilalo con vulkan-shim/README.md."
    exit 1
}
[ -f "$ADRENOTOOLS_DIR/libadrenotools.so" ] || {
    echo "Falta ADRENOTOOLS_DIR=$ADRENOTOOLS_DIR/libadrenotools.so"
    echo "Compilá AdrenoTools (vulkan-shim/README.md)."
    exit 1
}

echo "== venv =="
make -C recomp venv

echo "== deps Android =="
ANDROID_HOME="$ANDROID_HOME" recomp/tools/android_deps.sh "$DEPS"

echo "== generar código del juego =="
make -C recomp TARGET=android-arm64 GAME=smm2 gen

echo "== APK =="
ADRENOTOOLS_DIR="$ADRENOTOOLS_DIR" VULKAN_SHIM="$VULKAN_SHIM" \
    make -C recomp TARGET=android-arm64 GAME=smm2 \
        ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" -j"$JOBS" apk

APK="recomp/build/smm2-android-arm64-0x800000000/SMM2Recomp.apk"
ls -l "$APK"
echo
echo "APK: $APK"
echo "Instalá con: adb install -r \"$APK\""
echo "Después: make -C recomp TARGET=android-arm64 GAME=smm2 ANDROID_HOME=\"$ANDROID_HOME\" DEPS=\"$DEPS\" push-data"
