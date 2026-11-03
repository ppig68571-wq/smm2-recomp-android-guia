# Checklist de build — SMM2 Recomp Android

> **Estado experimental:** consulta [`ESTADO_ANDROID.md`](ESTADO_ANDROID.md) y la documentación oficial actual antes de seguir pasos de build o asumir compatibilidad. El upstream indica que Android se probó en el emulador, no en teléfonos físicos. Las cifras de POCO X6 son reportes de esta guía sin verificación independiente.

Marcá cada casilla antes de pasar al siguiente paso. Si algo falla, no sigas: mostrá el error completo.

## 0. Avisos de uso y privacidad

- [ ] Revisé [`LEGAL.md`](LEGAL.md) y los avisos actuales de SMM2 Recomp.
- [ ] No interpreto que tener archivos propios garantice que extraer, compilar, instalar o usar resultados esté permitido en mi caso.
- [ ] Mantendré archivos del juego, dumps, keys, firmware, tokens, APK y `libsmm2game.so` fuera de repositorios y chats.
- [ ] No voy a subir el juego, ROMs, NSP/XCI, `prod.keys`, firmware, token de OCW, APK ni `libsmm2game.so`.
- [ ] Cada persona que use la guía compila su propio dump y usa su propia cuenta de OCW.

## 1. PC

- [ ] Linux x86_64 (Ubuntu 24.04/25.04, Debian 13, WSL2) o macOS. Probado en Ubuntu/WSL2.
- [ ] `clang`, `lld`, `make`, `cmake`, `ninja-build`, `python3`, `python3-venv`, `git`, `curl`, `unzip`, `zip`, `xz-utils`, `patchelf`, `openjdk-17-jdk-headless`.
- [ ] ~10 GB libres.
- [ ] `nproc` ≥ 4 (con 8 va mejor).

## 2. Android SDK + NDK

- [ ] `ANDROID_HOME` apunta al SDK.
- [ ] `platform-tools`, `build-tools;36.1.0`, `platforms;android-36`, `ndk;29.0.14206865`.
- [ ] `JAVA_HOME` apunta a JDK 17+.
- [ ] `adb devices` muestra el teléfono como `device`.

Verificación:

```bash
echo "$ANDROID_HOME"
ls "$ANDROID_HOME/platform-tools/adb"
ls "$ANDROID_HOME/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
java -version
adb devices
```

## 3. Proyecto

- [ ] Clonado `https://github.com/smm2recomp/smm2recomp` (GPLv3).
- [ ] `make -C recomp venv` terminó.
- [ ] `recomp/tools/venv/bin/python` existe.

```bash
git clone https://github.com/smm2recomp/smm2recomp.git "$HOME/smm2recomp"
cd "$HOME/smm2recomp"
make -C recomp venv
```

## 4. Dump

- [ ] Base RomFS, update ExeFS y update RomFS (o NSP/XCI) disponibles.
- [ ] `recomp/private/smm2/extracted/exefs/main` existe.
- [ ] `recomp/private/smm2/extracted/romfs` existe.
- [ ] `setup.json` generado.
- [ ] Las keys **no** se copiaron ni se imprimieron.

```bash
ls recomp/private/smm2/extracted/exefs/main
ls recomp/private/smm2/extracted/romfs | head
```

## 5. Fuentes y sysdata (recomendado)

- [ ] `recomp/private/smm2/fonts/` tiene `.bfttf`.
- [ ] `recomp/private/smm2/sysdata/` tiene el modelo Mii (`0100000000000802`).
- [ ] `private/` no se comparte.

```bash
ls recomp/private/smm2/fonts | head
ls recomp/private/smm2/sysdata | head
```

## 6. Dependencias Android

- [ ] `$DEPS/lib/libSDL3.so`.
- [ ] `$DEPS/include/SDL3`.
- [ ] `$DEPS/lib/libshaderc_combined.a`.
- [ ] `$DEPS/include/vk_mem_alloc.h`.

```bash
ls "$DEPS/lib/libSDL3.so" "$DEPS/lib/libshaderc_combined.a" "$DEPS/include/vk_mem_alloc.h"
```

## 7. AdrenoTools + shim

- [ ] `$ADRENOTOOLS_DIR/libadrenotools.so`.
- [ ] `$ADRENOTOOLS_DIR/src/hook/libmain_hook.so` y los otros hooks.
- [ ] `$VULKAN_SHIM` existe.
- [ ] `llvm-readelf -d "$VULKAN_SHIM"` muestra `libadrenotools.so`.

```bash
ls "$ADRENOTOOLS_DIR/libadrenotools.so"
ls "$ADRENOTOOLS_DIR"/src/hook/lib*.so
"$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" -d "$VULKAN_SHIM" | grep NEEDED
```

## 8. Generar código

- [ ] `make ... gen` terminó sin errores.
- [ ] `recomp/generated/smm2-0x800000000/` tiene archivos.
- [ ] No se cambió `GUEST_ORIGIN` (Android: `0x800000000`).

```bash
ls recomp/generated/smm2-0x800000000 | head
```

## 9. APK

- [ ] `make ... apk` terminó sin errores.
- [ ] `recomp/build/smm2-android-arm64-0x800000000/SMM2Recomp.apk` existe (~160 MB).
- [ ] `libmain.so` y `libsmm2game.so` tienen el mismo `GAMELIB_ID`.
- [ ] El APK no se comparte.

```bash
B=recomp/build/smm2-android-arm64-0x800000000
ls -l "$B/SMM2Recomp.apk"

# GAMELIB_ID: el .so del juego y libmain.so tienen que coincidir.
ID=$(cat "$B/libsmm2game.so.id")
echo "GAMELIB_ID=$ID"
strings -n 8 "$B/libmain.so" | grep -qx "$ID" \
  && echo "OK: libmain y libsmm2game coinciden" \
  || echo "MISMATCH: borrá $B/obj y $B/rt/gamelib.o, y recompilá con el mismo GENOPT"
```

## 10. Instalar y copiar datos

- [ ] `adb install -r` OK.
- [ ] La app abre y llega al título.
- [ ] `push-data` copió `extracted` (y fuentes/sysdata).
- [ ] El log no muestra “Permission denied”.
- [ ] Si hay “Permission denied”: APK debuggable + `PUSH_INTERNAL=1`.

```bash
adb install -r recomp/build/smm2-android-arm64-0x800000000/SMM2Recomp.apk
adb shell am start -n org.smcraft.smm2recomp/org.libsdl.app.SDLActivity
adb shell tail -20 /sdcard/Android/data/org.smcraft.smm2recomp/files/smm2recomp.log
```

## 11. OCW (online)

- [ ] El usuario creó **su** cuenta en <https://opencourse.world/>.
- [ ] `ocw-config.json` tiene **su** dominio y **su** token (22 caracteres).
- [ ] `smm2mods.ini` tiene `backend=ocw`.
- [ ] El token **no** está en el repo, el chat ni los logs.
- [ ] La app conecta a OCW (log: `[net] ocw ...`).

```bash
adb shell cat /sdcard/Android/data/org.smcraft.smm2recomp/files/smm2mods.ini
# No imprimas ocw-config.json con el token.
```

## 12. Rendimiento y mods (ver `MODS.md`)

- [ ] Si pruebas los ajustes de `smm2.ini` del POCO X6 (`resolution = 25%`, `upscaler = bilinear`, `frame_gen = off`), los tratas como valores experimentales, no como base universal.
- [ ] `recomp.env`: `TU_DEBUG=gmem`, `LARECOMP_AHEAD=0`, `LARECOMP_FPS_INTERVAL=5`, `LARECOMP_VK_PROF=1`.
- [ ] Driver Turnip en `.../files/driver/vulkan.ad07xx.so` (o `libvulkan_freedreno.so`).
- [ ] El log dice `AdrenoTools loaded driver` (no `falling back to the system Vulkan loader`).
- [ ] Probaste `LARECOMP_VK_OPT=1` (shaders optimizados).
- [ ] Probaste `LARECOMP_VK_PRESENT=fifo` (vsync, sin tearing).
- [ ] Si usaste `LARECOMP_ASYNC_SHADERS=1`, verificaste que no falten renders.
- [ ] Si usaste `RECOMP_NO_CORES=1`, verificaste que no haya carreras/glitches.
- [ ] `LARECOMP_VK_NO_GMEM=1` solo si hacía falta compatibilidad (HUD/textos).
- [ ] Mediste 60 s × 3 en la misma escena, con el mismo estado térmico.
- [ ] Usaste la mediana de fps, draws/frame, GPU, exec y draw.
- [ ] Revertiste si no mejoró ≥10 % o rompió visuales/estabilidad.
- [ ] No prometés 30 fps si el dispositivo no llega.
- [ ] El cuello es el hilo principal (~97.6 % de un núcleo); no es la GPU.

## 13. Repo (si vas a publicar la guía)

- [ ] Subís solo `.gitignore`, `README.md`, `PROMPT.md`, `MODS.md`, `OPENCODE_PROMPT.md`, `CHECKLIST.md`, `REPO.md`, `FAQ.md`, `LICENSE.md`, `vulkan-shim/`, `scripts/`.
- [ ] **No** subís `private/`, `generated/`, `build/`, APK, `libsmm2game.so`, `prod.keys`, firmware, `ocw-config.json`, token, logs.
- [ ] El repo no tiene datos de Nintendo.
- [ ] Revisé el alcance y las licencias por archivo en `LICENSE.md`; no asumí que una licencia del código cubra material del juego o dependencias.


