# Vulkan shim + AdrenoTools

`libvulkanshim.so` es un loader mínimo: en vez de usar el driver Adreno stock, carga un driver **Turnip** custom desde la carpeta de la app usando **AdrenoTools**. Si no encuentra el driver custom, cae al loader del sistema.

El APK de SMM2 Recomp se parchea para pedir `libvulkanshim.so` en lugar de `libvulkan.so`; por eso el build del APK necesita este `.so`.

## Requisitos

- Android NDK r29 (`29.0.14206865`) o compatible. En macOS, usá `darwin-x86_64` en las rutas del NDK.
- [AdrenoTools](https://github.com/bylaws/libadrenotools) (arm64).
- [Vulkan-Headers](https://github.com/KhronosGroup/Vulkan-Headers).
- Python 3.

## 1. Compilar AdrenoTools

```bash
export NDK=/opt/android-sdk/ndk/29.0.14206865
git clone https://github.com/bylaws/libadrenotools "$HOME/smm2-build/libadrenotools"
cmake -S "$HOME/smm2-build/libadrenotools" -B "$HOME/smm2-build/libadrenotools/build-android" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-33 \
  -DCMAKE_BUILD_TYPE=Release
cmake --build "$HOME/smm2-build/libadrenotools/build-android" -j"$(nproc)"
```

Debe quedar:

```
libadrenotools/build-android/libadrenotools.so
libadrenotools/build-android/src/hook/libmain_hook.so
libadrenotools/build-android/src/hook/libhook_impl.so
libadrenotools/build-android/src/hook/libfile_redirect_hook.so
libadrenotools/build-android/src/hook/libgsl_alloc_hook.so
```

## 2. Generar las tablas del shim

```bash
git clone https://github.com/KhronosGroup/Vulkan-Headers "$HOME/smm2-build/Vulkan-Headers"
cd "$HOME/smm2-build/vulkan-shim"   # esta carpeta
VULKAN_CORE_H="$HOME/smm2-build/Vulkan-Headers/include/vulkan/vulkan_core.h" \
SHIM_OUT="$PWD" \
python3 gen_shim.py
```

Genera `globals.h`, `init.h` y `stubs.S` (un stub por comando Vulkan; con los Vulkan-Headers actuales son **775**).

## 3. Compilar el shim

```bash
"$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android33-clang" \
  -shared -fPIC -O2 \
  -I"$HOME/smm2-build/libadrenotools/include" \
  -I"$HOME/smm2-build/Vulkan-Headers/include" \
  -o libvulkanshim.so shim.c stubs.S \
  -L"$HOME/smm2-build/libadrenotools/build-android" -ladrenotools \
  -llog -ldl -landroid
```

Verificá:

```bash
"$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" -d libvulkanshim.so | grep NEEDED
# libadrenotools.so, liblog.so, libdl.so, libandroid.so, libc.so
```

## 4. Usarlo en el build del APK

```bash
export ADRENOTOOLS_DIR="$HOME/smm2-build/libadrenotools/build-android"
export VULKAN_SHIM="$HOME/smm2-build/vulkan-shim/libvulkanshim.so"
make -C recomp TARGET=android-arm64 GAME=smm2 \
  ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" -j"$(nproc)" apk
```

`recomp/tools/make_android_apk.sh` copia `libadrenotools.so`, los hooks y el shim al APK, y parchea `libmain.so` para que pida `libvulkanshim.so`.

## 5. Driver custom en el teléfono

El shim busca, en este orden:

```
/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/vulkan.ad07xx.so
/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/libvulkan_freedreno.so
```

Copiá ahí el Turnip que uses (por ejemplo, el `vulkan.ad07xx.so` de un paquete de driver Turnip para Adreno). Si no hay ninguno, el shim usa el driver del sistema.

## 6. Nombre del paquete

`shim.c` tiene hardcodeado:

```c
const char *internal = "/data/user/0/org.smcraft.smm2recomp/files";
const char *external = "/storage/emulated/0/Android/data/org.smcraft.smm2recomp/files";
```

Si compilás con otro `RECOMP_ANDROID_PACKAGE`, cambiá esas dos rutas y volvé a compilar el shim.

## Licencia

GPLv3, igual que el proyecto. No contiene código ni assets de Nintendo.
