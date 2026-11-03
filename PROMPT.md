# PROMPT: compilar SMM2 Recomp para Android desde tu propio dump

> **Estado experimental:** consulta [`ESTADO_ANDROID.md`](ESTADO_ANDROID.md) y la documentación oficial actual antes de seguir pasos de build o asumir compatibilidad. El upstream indica que Android se probó en el emulador, no en teléfonos físicos. Las cifras de POCO X6 son reportes de esta guía sin verificación independiente.

> Copiá y pegá este prompt en la IA que va a hacer el build (OpenCode/DeepSeek, Claude, etc.).
> La IA debe seguir las reglas y pedirte las rutas, pero **nunca** debe pedirte ni imprimir `prod.keys`, firmware, el token de OCW ni el contenido del juego.

---

## 0. Rol y reglas duras

Eres un agente técnico que ayuda a compilar **SMM2 Recomp** para **Android arm64** en Linux/WSL2 (o macOS), a partir del **dump legal del usuario**.

Reglas que no se negocian:

1. **Legalidad:** el usuario debe tener una copia legal de *Super Mario Maker 2* base + update **3.0.3**. Si no la tiene, detente.
2. **Secretos:** no pidas, copies, imprimas ni subas `prod.keys`, firmware, `ocw-config.json`, el token de OCW, ROMs, NSP/XCI, `libsmm2game.so` ni APKs. Las keys y el token se quedan en la máquina del usuario; el token se escribe a mano en el teléfono.
3. **No distribuir:** el APK resultante es para los dispositivos del usuario. El proyecto lo dice: *"it is for your own devices only, never to be shared"*. Si el usuario pide publicarlo o regalarlo, explícale que no se puede; sí se puede compartir esta guía y el runtime/recompilador (GPLv3), no el código generado del juego.
4. **Antes de `rm -rf`:** confirma, y borra solo artefactos de build (`obj`, `rt/gamelib.o`, `apk/`). Nunca borres `private/`, `generated/`, `save/` ni datos del usuario sin backup.
5. **Un cambio a la vez:** para rendimiento, cambia una variable, mide 60 s × 3, usa la mediana y revierte si no mejora ≥10 % o rompe algo.
6. **Errores completos:** si un comando falla, muestra la salida completa y no inventes resultados.
7. **Nada de navegador/cuentas del usuario:** no uses su Chrome, su GitHub ni sus sesiones. Si hay que publicar algo, que lo haga el usuario.

---

## 1. Datos que debes pedir (sin secretos en el chat)

Pide al usuario, como **rutas locales** (no valores):

- Dump base: carpeta del **RomFS** base (`smm2-romfs`) o el `.nsp`/`.xci` base.
- Update 3.0.3: carpeta del **ExeFS** (`smm2-v303-exefs`) y del **RomFS** (`smm2-v303-romfs`) o el `.nsp` del update.
- `prod.keys` (ruta) y carpeta de firmware (`.../registered`) para fuentes/sysdata. **No los leas en voz alta ni los imprimas.**
- `hactool` (ruta) si ya lo tiene; si no, se compila con el proyecto.
- SDK de Android (`ANDROID_HOME`), versión del NDK (`29.0.14206865`), carpeta de deps.
- Serial del teléfono (`adb devices`), modelo, RAM, versión de Android.
- Para OCW: que él mismo se registre en <https://opencourse.world/> y guarde **su** dominio y **su** token. Tú no los ves.

Si el usuario no tiene el dump, **no continúes**: explícale que necesita su copia legal.

---

## 2. Requisitos del sistema

Camino probado: **Ubuntu/WSL2 x86_64**. macOS puede servir, pero **no lo probamos**; Android se compila en el host, no en el teléfono.

> **macOS:** no es el camino probado. Si lo usás: `xcode-select --install`; `brew install cmake ninja python git curl patchelf openjdk@17`; reemplazá `linux-x86_64` por `darwin-x86_64` en las rutas del NDK, `nproc` por `sysctl -n hw.ncpu`, y `recomp/tools/build_hactool.sh linux-x86_64` por `macos-arm64` (o `macos-x86_64`). El resto de los comandos es igual.

```bash
sudo apt update
sudo apt install -y clang lld make cmake ninja-build python3 python3-venv python3-pip \
  git curl unzip zip xz-utils patchelf openjdk-17-jdk-headless
```

- **Android SDK** con `platform-tools`, `build-tools;36.1.0`, `platforms;android-36`, `ndk;29.0.14206865`.
- **JDK 17+** (`JAVA_HOME` apuntando al JDK).
- **~10 GB libres** (juego ~3 GB + build).

### Teléfono: mínimo y compatibilidad

El APK es **arm64 only** y necesita **Android 13+**, **Vulkan 1.3** (dynamic rendering, timeline semaphores, 8-bit storage, scalar block layout) y **8 GB de RAM (mínimo práctico; 6 GB no soportado)**. **No es “cualquier teléfono”**: si no cumple esto, no arranca o va muy lento.

| Nivel | SoC / GPU | RAM | Android | Expectativa |
|---|---|---|---|---|
| **Reporte experimental de esta guía, no verificado por upstream** | Snapdragon 7s Gen 2 / Adreno 710 (POCO X6 5G) | 8 GB | 13+ | ~20–21 fps en niveles pesados; no es garantía |
| Otros teléfonos arm64 | Compatibilidad no verificada; consulta los requisitos Vulkan del upstream | 8 GB o más recomendado | 13+ | sin garantía de arranque o FPS |
| No verificado | Otros SoC/GPU y teléfonos físicos | — | — | no hay una lista oficial de dispositivos probados en hardware |
| No soportado | 32-bit / x86 | — | — | el APK es arm64 only |

El POCO X6 aparece como reporte experimental de esta guía, no como mínimo oficialmente soportado ni dispositivo validado por upstream. No se garantizan 30 fps. Consulta ESTADO_ANDROID.md.

Variables de ejemplo (adaptalas):

```bash
export REPO="$HOME/smm2recomp"
export GUIDE="$HOME/smm2-recomp-guia-legal"   # donde descomprimiste este ZIP
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_NDK="$ANDROID_HOME/ndk/29.0.14206865"
export DEPS="$HOME/smm2-build/deps-android-arm64"
export ADRENOTOOLS_DIR="$HOME/smm2-build/libadrenotools/build-android"
export VULKAN_SHIM="$HOME/smm2-build/vulkan-shim/libvulkanshim.so"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

Si el SDK no está:

```bash
mkdir -p "$ANDROID_HOME/cmdline-tools"
# Descargá "commandlinetools-linux" de https://developer.android.com/studio#command-tools
# y descomprimilo en "$ANDROID_HOME/cmdline-tools/latest"
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  "platform-tools" "build-tools;36.1.0" "platforms;android-36" "ndk;29.0.14206865"
```

---

## 3. Proyecto y entorno Python

```bash
git clone https://github.com/smm2recomp/smm2recomp.git "$REPO"
cd "$REPO"
make -C recomp venv          # una vez: entorno del recompilador
```

Si ya tenés el checkout, usalo. El proyecto es **GPLv3**; no redistribuyas el código generado del juego.

---

## 4. Preparar el dump (legal)

### 4.1 Desde carpetas extraídas

```bash
make -C recomp GAME=smm2 setup \
  DUMP_BASE_ROMFS="/ruta/smm2-romfs" \
  DUMP_UPDATE_EXEFS="/ruta/smm2-v303-exefs" \
  DUMP_UPDATE_ROMFS="/ruta/smm2-v303-romfs"
```

Salida: `recomp/private/smm2/extracted/{exefs,romfs}` + `setup.json`. El script verifica los build IDs/hashes de 3.0.3 y **no copia keys**.

### 4.2 Desde NSP/XCI (con hactool y las keys del usuario)

```bash
# hactool 1.4.0: si no lo tenés, el proyecto lo compila (necesita zig)
# Linux/WSL2: linux-x86_64 | macOS: macos-arm64 o macos-x86_64
recomp/tools/fetch_zig.sh
recomp/tools/build_hactool.sh linux-x86_64
# -> recomp/build/hactool-linux-x86_64/hactool

python3 recomp/games/smm2/setup.py \
  --source "/ruta/base.nsp" \
  --source "/ruta/update.nsp" \
  --keys "/ruta/prod.keys" \
  --hactool "recomp/build/hactool-linux-x86_64/hactool" \
  --out recomp/private/smm2/extracted
# macOS: usá --hactool "recomp/build/hactool-macos-arm64/hactool" (o macos-x86_64)
```

Las keys se pasan a hactool y se leen en el lugar; la salida de hactool se enmascara. No las imprimas.

### 4.3 Fuentes y sysdata (opcional pero recomendado)

Sin esto, el runtime sustituye una fuente del host y el juego puede detenerse en el primer Mii (falta el modelo Mii).

```bash
python3 recomp/games/smm2/sysdata.py \
  --firmware "/ruta/firmware/registered" \
  --keys "/ruta/prod.keys" \
  --hactool "recomp/build/hactool-linux-x86_64/hactool" \
  --data recomp/private/smm2
```

Salida: `private/smm2/fonts/` y `private/smm2/sysdata/<title id>/`. **No compartas `private/`**: contiene datos del juego.

Verificá:

```bash
ls recomp/private/smm2/extracted/exefs/main
ls recomp/private/smm2/extracted/romfs
ls recomp/private/smm2/fonts 2>/dev/null | head
ls recomp/private/smm2/sysdata 2>/dev/null | head
```

---

## 5. Dependencias de Android (SDL3, shaderc, VMA)

```bash
ANDROID_HOME="$ANDROID_HOME" recomp/tools/android_deps.sh "$DEPS"
```

El script compila **SDL3 3.4.18**, **shaderc v2026.1** y **VMA 3.3.0** para `arm64-v8a` en `$DEPS`. Necesita `cmake`, `ninja`, `curl`, `git`, `python3`. No contiene nada del juego.

---

## 6. AdrenoTools + shim de Vulkan (driver custom)

El APK probado usa un **shim** que carga un driver Turnip custom vía **AdrenoTools**, en vez del driver Adreno stock. Si no tenés el shim, el build del APK falla; en `vulkan-shim/` de este repo está el código y las instrucciones.

### 6.1 AdrenoTools

```bash
git clone https://github.com/bylaws/libadrenotools "$HOME/smm2-build/libadrenotools"
cmake -S "$HOME/smm2-build/libadrenotools" -B "$ADRENOTOOLS_DIR" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-33 \
  -DCMAKE_BUILD_TYPE=Release
cmake --build "$ADRENOTOOLS_DIR" -j"$(nproc)"
```

Debe quedar `$ADRENOTOOLS_DIR/libadrenotools.so` y `$ADRENOTOOLS_DIR/src/hook/lib*.so`.

### 6.2 Vulkan-Headers + shim

```bash
git clone https://github.com/KhronosGroup/Vulkan-Headers "$HOME/smm2-build/Vulkan-Headers"
mkdir -p "$HOME/smm2-build/vulkan-shim"
cp "$GUIDE/vulkan-shim/shim.c" "$HOME/smm2-build/vulkan-shim/"
cp "$GUIDE/vulkan-shim/gen_shim.py" "$HOME/smm2-build/vulkan-shim/"
cd "$HOME/smm2-build/vulkan-shim"
VULKAN_CORE_H="$HOME/smm2-build/Vulkan-Headers/include/vulkan/vulkan_core.h" \
SHIM_OUT="$HOME/smm2-build/vulkan-shim" \
python3 gen_shim.py
"$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android33-clang" \
  -shared -fPIC -O2 \
  -I"$HOME/smm2-build/libadrenotools/include" \
  -I"$HOME/smm2-build/Vulkan-Headers/include" \
  -o libvulkanshim.so shim.c stubs.S \
  -L"$ADRENOTOOLS_DIR" -ladrenotools -llog -ldl -landroid
export VULKAN_SHIM="$HOME/smm2-build/vulkan-shim/libvulkanshim.so"
```

El shim copia el driver custom desde `.../files/driver/` (`vulkan.ad07xx.so` o `libvulkan_freedreno.so`) y, si no hay, cae al loader del sistema. El nombre del paquete está hardcodeado en `shim.c` (`org.smcraft.smm2recomp`); si cambiás `RECOMP_ANDROID_PACKAGE`, cambialo también ahí.

> Alternativa sin driver custom: editar `recomp/tools/make_android_apk.sh` para no reemplazar `libvulkan.so` por el shim. **No está probado**; el camino probado es el shim.

---

## 7. Generar el código del juego para Android

```bash
cd "$REPO"
make -C recomp TARGET=android-arm64 GAME=smm2 gen
```

Genera `recomp/generated/smm2-0x800000000/` (el guest de Android vive en `0x800000000`, no en `0x7000000000`). Tarda varios minutos.

---

## 8. Compilar el APK

```bash
cd "$REPO"
ADRENOTOOLS_DIR="$ADRENOTOOLS_DIR" VULKAN_SHIM="$VULKAN_SHIM" \
  make -C recomp TARGET=android-arm64 GAME=smm2 \
    ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" -j"$(nproc)" apk
```

Salida: `recomp/build/smm2-android-arm64-0x800000000/SMM2Recomp.apk` (~160 MB).

Notas:
- El APK lleva `libmain.so` (runtime), `libsmm2game.so` (código generado de **tu** dump), `libSDL3.so`, el shim y AdrenoTools.
- **No compartas** el APK ni `libsmm2game.so`.
- Si cambiás `GENOPT` (por ejemplo `-O3` o PGO), borrá **`build/smm2-android-arm64-0x800000000/obj`** y **`build/smm2-android-arm64-0x800000000/rt/gamelib.o`** antes de recompilar. El `obj/` tiene el código generado compilado con el `GENOPT` viejo; `gamelib.o` tiene el `GAMELIB_ID`. El `GAMELIB_ID` cambia con los flags; si `libmain.so` y `libsmm2game.so` no coinciden, el juego crashea con “built for another version”.

---

## 9. Instalar y copiar los datos del juego

```bash
adb devices
export ADB_SERIAL="<serial>"
# Si hay más de un dispositivo, agregá -s "$ADB_SERIAL" a cada comando adb.

adb install -r recomp/build/smm2-android-arm64-0x800000000/SMM2Recomp.apk

# Copia extracted/ (exefs+romfs), fonts/ y sysdata/ (~3 GB, tarda)
make -C recomp TARGET=android-arm64 GAME=smm2 \
  ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" ADB_SERIAL="$ADB_SERIAL" push-data
```

Si no generaste `fonts`/`sysdata`, copiá solo `extracted`:

```bash
recomp/tools/android_push_data.sh recomp/private/smm2 extracted
```

Abrir:

```bash
adb shell am start -n org.smcraft.smm2recomp/org.libsdl.app.SDLActivity
```

Log: `/sdcard/Android/data/org.smcraft.smm2recomp/files/smm2recomp.log` (y `adb logcat -s smm2recomp`).

**Si la app no puede leer lo que copió adb** (“Permission denied” en el log): compilá un APK debuggable y usá la carpeta interna:

```bash
RECOMP_ANDROID_DEBUGGABLE=1 make -C recomp TARGET=android-arm64 GAME=smm2 \
  ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" apk install
make -C recomp TARGET=android-arm64 GAME=smm2 \
  ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" PUSH_INTERNAL=1 push-data
```

---

## 10. OpenCourse World (online) — cuenta propia

Cada persona se registra en <https://opencourse.world/>, acepta los términos y obtiene **su** dominio y **su** token (22 caracteres). No se comparten cuentas.

1. En el teléfono, en `/sdcard/Android/data/org.smcraft.smm2recomp/files/`, creá `ocw-config.json`:

```json
{ "domain": "<tu-dominio>", "token": "<tu-token-de-22-caracteres>" }
```

   - `domain`: máximo 29 caracteres.
   - `token`: exactamente 22; es secreto. **No lo pegues en el chat ni en un repo.**
   - `ip`: opcional, para un servidor propio.

2. En `smm2mods.ini`, en la misma carpeta:

```ini
backend=ocw
```

3. Reiniciá la app. Sin `backend=ocw` el config se ignora; sin config, el backend queda offline.

Para depurar (sin exponer el token): `net_log=1` y `log=1`; el runtime redacta el token en los logs. TLS es **1.2**; OCW lo acepta.

---

## 11. Mods y rendimiento (FPS) — una variable a la vez

> **No hay un mod mágico que garantice 30 fps.** Lo que usamos en el **POCO X6 5G** (Snapdragon 7s Gen 2, Adreno 710, 8 GB) fue un conjunto de ajustes de **driver, resolución y runtime**. Todos se aplican **sin root**. La referencia completa, con el detalle de cada flag, está en **`MODS.md`**.

### 11.1 Configuración que quedó instalada (base medida)

`.../files/smm2.ini`:

```ini
resolution = 25%
upscaler = bilinear
frame_gen = off
```

`.../files/recomp.env` (una `NAME=value` por línea):

```ini
TU_DEBUG=gmem
LARECOMP_AHEAD=0
LARECOMP_FPS_INTERVAL=5
LARECOMP_VK_PROF=1
```

Además:

- **Driver Turnip custom** cargado con **AdrenoTools** a través de `libvulkanshim.so`.
- Driver en `.../files/driver/vulkan.ad07xx.so` (build Turnip compatible con Adreno 710/720).
- APK con `GENOPT=-O2` (el `-O3` se probó y se revirtió).

### 11.2 Flags que probamos (no todos a la vez)

```ini
LARECOMP_VK_OPT=1
LARECOMP_ASYNC_SHADERS=1
LARECOMP_VK_NO_GMEM=1
RECOMP_NO_CORES=1
LARECOMP_VK_PRESENT=fifo
```

| Flag | Qué hace | Riesgo / cuándo usarlo |
|---|---|---|
| `LARECOMP_VK_OPT=1` | Shaders compilados con optimización de shaderc. | Compila más lento; probalo con el juego estable. |
| `LARECOMP_ASYNC_SHADERS=1` | Compila en segundo plano y saltea draws mientras compila. | **SMM2 pierde renders de una sola vez**; solo prueba. |
| `LARECOMP_VK_NO_GMEM=1` | Fuerza copias por draw (sin import de memoria). | **Compatibilidad**, no velocidad; puede costar FPS. |
| `RECOMP_NO_CORES=1` | Sin exclusividad por núcleo (LAS). | **SMM2 tiene carreras**; solo prueba. |
| `LARECOMP_VK_PRESENT=fifo` | VSync FIFO. | Sin tearing; si ya estás bajo 60, no limita. |

### 11.3 Driver Turnip (la mejora más grande)

El shim busca el driver en:

```
/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/vulkan.ad07xx.so
/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/libvulkan_freedreno.so
```

Instalación:

```bash
PKG=org.smcraft.smm2recomp
adb shell mkdir -p /sdcard/Android/data/$PKG/files/driver
adb push vulkan.ad07xx.so /sdcard/Android/data/$PKG/files/driver/
adb shell am force-stop $PKG
adb shell am start -n $PKG/org.libsdl.app.SDLActivity
```

En el log debe decir `AdrenoTools loaded driver`. Si dice `falling back to the system Vulkan loader`, el driver no se copió o no es compatible.

Para **Adreno 710/720** usá un Turnip con soporte **GMEM** y `TU_DEBUG=gmem`. Para Adreno 725/730/740/750/830, probá el Turnip más reciente; si rompe, volvé al stock. Si ya tenés el driver en el teléfono, extraelo con `adb pull`; si no, buscá un build Turnip para tu GPU en un proyecto comunitario (por ejemplo `Vauzi-17/710` o `K11MCH1/AdrenoToolsDrivers`). No hay un driver universal. El driver **no** va al repo.

### 11.4 Cómo medir

1. Dejá el teléfono en el mismo estado térmico entre pruebas.
2. Cargá la misma escena (mismo nivel, misma posición).
3. Esperá 60 s a que se estabilicen shaders/caché.
4. Medí **60 s × 3** con `LARECOMP_VK_PROF=1` y `LARECOMP_FPS_INTERVAL=5`.
5. Usá la **mediana** de `fps`, `draws/frame`, `gpu ms/frame`, `cpu exec ms/frame`, `draw ms/frame`.
6. Mantené el cambio solo si mejora **≥10 %** y no rompe visuales/estabilidad; si no, revertí.

```bash
PKG=org.smcraft.smm2recomp
adb shell tail -f /sdcard/Android/data/$PKG/files/smm2recomp.log | grep '\[vk\]'
```

### 11.5 Nuestra referencia (POCO X6 5G, `-O2`)

| Métrica | Valor |
|---|---|
| Nivel pesado | **~21.0 fps** |
| Título | **~30.6 fps** |
| Draws/frame | **276.7** |
| GPU | **17.9 ms/frame** |
| CPU exec | **8.55 ms/frame** |
| Draw | **2.45 ms/frame** |
| Hilo principal guest | **~97.6 % de un núcleo** |

El cuello es el **hilo principal del juego**, no la GPU. Por eso bajar resolución ayuda menos de lo que uno espera, y `-O3`/PGO no garantizan 30 fps.

### 11.6 Lo que NO ayudó

| Cambio | Resultado | Decisión |
|---|---|---|
| `GENOPT=-O3` | 19.0 fps en frío / 20.25 en caliente vs **21.0** del `-O2`; más draws (297.5 vs 276.7). | **Revertido** al `-O2`. |
| `frame_gen = 120` | Genera frames intermedios; no aumenta la simulación y consume GPU. | **Off**. |
| Resolución alta / AA | Más carga de GPU; el límite es CPU. | **25 % + bilinear** en el POCO. |
| PGO | Quedó a medias por un reinicio; el cuello sigue siendo el hilo principal. | **Opcional/experimental** (`scripts/pgo.sh`). |

### 11.7 Orden recomendado

1. APK `-O2` estable, llegando al título.
2. Driver Turnip + `TU_DEBUG=gmem` (si tu GPU es Adreno 710/720).
3. `resolution = 50%`, medir; después `25%`, medir.
4. `upscaler = bilinear`.
5. `frame_gen = off`.
6. `LARECOMP_VK_OPT=1`.
7. `LARECOMP_VK_PRESENT=fifo`.
8. Recién ahí los experimentales: `LARECOMP_ASYNC_SHADERS=1`, `RECOMP_NO_CORES=1`.
9. `LARECOMP_VK_NO_GMEM=1` **solo** si hay HUD/textos faltantes o el teléfono no soporta import de memoria.

Si un paso no da ≥10 %, **revertilo**. No acumules cambios sin medir.

---

## 12. PGO (opcional, experimental)

En nuestra prueba el PGO quedó a medias por un reinicio y el `-O3` no ayudó; el cuello sigue siendo el hilo principal. Probalo solo si querés experimentar.

### 12.1 Build instrumentado

```bash
cd "$REPO/recomp"
B=build/smm2-android-arm64-0x800000000
rm -rf "$B/obj"
rm -f "$B/rt/gamelib.o"
ADRENOTOOLS_DIR="$ADRENOTOOLS_DIR" VULKAN_SHIM="$VULKAN_SHIM" \
  make TARGET=android-arm64 GAME=smm2 \
    ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" \
    GENOPT="-O2 -fprofile-generate" -j"$(nproc)" apk
```

Instalá ese APK y agregá a `recomp.env`:

```ini
LLVM_PROFILE_FILE=/sdcard/Android/data/org.smcraft.smm2recomp/files/pgo/%p-%c.profraw
```

Creá la carpeta y dale permisos:

```bash
adb shell mkdir -p /sdcard/Android/data/org.smcraft.smm2recomp/files/pgo
adb shell chmod 777 /sdcard/Android/data/org.smcraft.smm2recomp/files/pgo
```

Jugá **2–3 min** en un nivel pesado. El modo `%c` escribe el perfil periódicamente (no hace falta cerrar limpio). Después:

```bash
mkdir -p "$HOME/smm2-build/profraw"
adb pull /sdcard/Android/data/org.smcraft.smm2recomp/files/pgo/. "$HOME/smm2-build/profraw/"
"$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-profdata" merge \
  -o "$HOME/smm2-build/pgo.profdata" "$HOME"/smm2-build/profraw/*.profraw
```

### 12.2 Build final con el perfil

```bash
cd "$REPO/recomp"
B=build/smm2-android-arm64-0x800000000
rm -rf "$B/obj"
rm -f "$B/rt/gamelib.o"
ADRENOTOOLS_DIR="$ADRENOTOOLS_DIR" VULKAN_SHIM="$VULKAN_SHIM" \
  make TARGET=android-arm64 GAME=smm2 \
    ANDROID_HOME="$ANDROID_HOME" DEPS="$DEPS" \
    GENOPT="-O2 -fprofile-use=$HOME/smm2-build/pgo.profdata" -j"$(nproc)" apk
```

Instalá, medí 60 s × 3 y compará contra el `-O2` (21.0 fps). Mantené solo si mejora ≥10 % y no rompe nada; si no, volvé al APK `-O2`.

---

## 13. Troubleshooting

| Síntoma | Causa / solución |
|---|---|
| `INSTALL_FAILED_VERSION_DOWNGRADE` | El APK nuevo tiene `versionCode` menor que el instalado. Recompilá (el build usa minutos desde 1970, así que sube) o desinstalá (pierde datos). El parche de manifiesto + `apksigner` es avanzado y no recomendado. |
| “built for another version” / crash al arrancar | `GAMELIB_ID` distinto entre `libmain.so` y `libsmm2game.so`. Borrá `build/.../obj` y `build/.../rt/gamelib.o`, y recompilá con los mismos `GENOPT`. |
| `Permission denied` leyendo `extracted/` | Android 11+ y archivos copiados por adb. Compilá con `RECOMP_ANDROID_DEBUGGABLE=1` y usá `PUSH_INTERNAL=1`. |
| Crash de Vulkan / no arranca | El teléfono necesita Vulkan 1.3 con dynamic rendering, timeline semaphores, 8-bit storage y scalar block layout. Probá el driver stock (sin shim) o un Turnip compatible. Mirá `adb logcat`. |
| OCW no conecta | `backend=ocw` + `ocw-config.json` con dominio/token correctos; TLS 1.2; `net_log=1`, `log=1`. El token se redacta en logs. |
| Tirones por shaders | Dejá calentar el nivel; `LARECOMP_ASYNC_SHADERS=1`; no borres `cache/` si no hace falta. |
| No llega a 30 fps | El límite es el hilo principal del juego. `-O3`/PGO no garantizan nada; bajá resolución o aceptá ~20 fps. |
| `libsmm2game.so` enorme | Es normal (~140 MB); el APK ~160 MB. No lo subas a ningún lado. |

---

## 14. Checklist final

- [ ] El usuario tiene su copia legal y su dump 3.0.3.
- [ ] `private/smm2/extracted/exefs/main` existe.
- [ ] `private/smm2/fonts` y `sysdata` (si se generaron).
- [ ] `DEPS` tiene `libSDL3.so`, `include/SDL3`, `include/shaderc`, `libshaderc_combined.a`, `vk_mem_alloc.h`.
- [ ] `ADRENOTOOLS_DIR/libadrenotools.so` y hooks existen.
- [ ] `VULKAN_SHIM` existe y `shim.c` tiene el package correcto.
- [ ] `make ... apk` terminó sin errores.
- [ ] `adb install -r` OK; la app abre y llega al título.
- [ ] `push-data` copió `extracted` (y fuentes/sysdata).
- [ ] OCW: cada uno con **su** cuenta; el token no está en el repo ni en el chat.
- [ ] El APK **no** se comparte; el repo solo tiene guía/scripts/shim.

---

## 15. Legal (resumen)

- Proyecto no afiliado a Nintendo. *Super Mario Maker 2* y sus nombres son marcas de Nintendo.
- No se distribuye código ni assets de Nintendo. Cada persona necesita su copia legal y compila lo suyo.
- El APK y `libsmm2game.so` son para los dispositivos del usuario; **no se publican**.
- El proyecto es **GPLv3**; si distribuís el runtime/recompilador, cumplí la licencia. El código generado del juego no se distribuye.
- OpenCourse World: cuentas y tokens personales; no se comparten.
- Esta guía: **CC BY 4.0**.


