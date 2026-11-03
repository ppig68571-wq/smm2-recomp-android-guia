#!/bin/bash
# PGO experiment for SMM2 Recomp on Android (optional; our -O3/PGO tests did not
# reach +10% on a POCO X6: the guest main thread is the limit).
#
# Usage:
#   scripts/pgo.sh instrument   # build with -fprofile-generate
#   scripts/pgo.sh pull         # pull *.profraw from the phone
#   scripts/pgo.sh merge        # llvm-profdata merge -> pgo.profdata
#   scripts/pgo.sh use          # build with -fprofile-use
set -euo pipefail

MODE=${1:-instrument}
REPO=${REPO:-$HOME/smm2recomp}
ANDROID_HOME=${ANDROID_HOME:-$HOME/android-sdk}
ANDROID_NDK=${ANDROID_NDK:-$ANDROID_HOME/ndk/29.0.14206865}
DEPS=${DEPS:-$HOME/smm2-build/deps-android-arm64}
ADRENOTOOLS_DIR=${ADRENOTOOLS_DIR:-$HOME/smm2-build/libadrenotools/build-android}
VULKAN_SHIM=${VULKAN_SHIM:-$HOME/smm2-build/vulkan-shim/libvulkanshim.so}
JOBS=${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}
HOST_TAG=${HOST_TAG:-linux-x86_64}   # macOS: darwin-x86_64
PROF=${PROF:-$HOME/smm2-build/pgo.profdata}
PROFRAW=${PROFRAW:-$HOME/smm2-build/profraw}
PKG=${PKG:-org.smcraft.smm2recomp}
DEV_PGO="/sdcard/Android/data/$PKG/files/pgo"

export ANDROID_HOME ANDROID_NDK
export PATH="$ANDROID_HOME/platform-tools:$PATH"

cd "$REPO/recomp"
B=build/smm2-android-arm64-0x800000000

build() {
    local genopt="$1"
    rm -rf "$B/obj"
    rm -f "$B/rt/gamelib.o"
    ADRENOTOOLS_DIR="$ADRENOTOOLS_DIR" VULKAN_SHIM="$VULKAN_SHIM" \
        make TARGET=android-arm64 GAME=smm2 \
            ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" \
            GENOPT="$genopt" -j"$JOBS" apk
}

case "$MODE" in
    instrument)
        build "-O2 -fprofile-generate"
        echo
        echo "1. Instalá el APK y agregá a recomp.env:"
        echo "   LLVM_PROFILE_FILE=$DEV_PGO/%p-%c.profraw"
        echo "2. Creá la carpeta y dale permisos:"
        echo "   adb shell mkdir -p $DEV_PGO && adb shell chmod 777 $DEV_PGO"
        echo "3. Jugá 2-3 min en un nivel pesado."
        echo "4. Corré: $0 pull && $0 merge && $0 use"
        ;;
    pull)
        mkdir -p "$PROFRAW"
        adb pull "$DEV_PGO/." "$PROFRAW/"
        ls -l "$PROFRAW"
        ;;
    merge)
        "$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG/bin/llvm-profdata" merge \
            -o "$PROF" "$PROFRAW"/*.profraw
        ls -l "$PROF"
        ;;
    use)
        [ -f "$PROF" ] || { echo "Falta $PROF; corré: $0 merge"; exit 1; }
        build "-O2 -fprofile-use=$PROF"
        ;;
    *)
        echo "Uso: $0 {instrument|pull|merge|use}"
        exit 1
        ;;
esac
