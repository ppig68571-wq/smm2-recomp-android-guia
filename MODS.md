# Mods y ajustes de rendimiento (FPS) — SMM2 Recomp Android

> **Estado experimental:** consulta [`ESTADO_ANDROID.md`](ESTADO_ANDROID.md) y la documentación oficial actual antes de seguir pasos de build o asumir compatibilidad. El upstream indica que Android se probó en el emulador, no en teléfonos físicos. Las cifras de POCO X6 son reportes de esta guía sin verificación independiente.

> **No hay un mod mágico que garantice 30 fps.** Lo que usamos en el **POCO X6 5G** (Snapdragon 7s Gen 2, Adreno 710, 8 GB) fue un conjunto de ajustes de **driver, resolución y runtime**. Todos se aplican **sin root**. Cambiá **una variable a la vez** y medí.

Este archivo es la referencia completa de los ajustes que probamos. El manual de build está en `PROMPT.md`; el checklist, en `CHECKLIST.md`.

---

## 1. Resumen: lo que quedó instalado y lo que solo probamos

### 1.1 Configuración que quedó en el teléfono (base medida)

`.../files/smm2.ini`:

```ini
resolution = 25%
upscaler = bilinear
frame_gen = off
```

`.../files/recomp.env`:

```ini
TU_DEBUG=gmem
LARECOMP_AHEAD=0
LARECOMP_FPS_INTERVAL=5
LARECOMP_VK_PROF=1
```

Además:

- **Driver Turnip custom** cargado con **AdrenoTools** a través de `libvulkanshim.so`.
- Driver en `.../files/driver/vulkan.ad07xx.so` (build Turnip compatible con Adreno 710/720; ver §2).
- APK compilado con `GENOPT=-O2` (el `-O3` se probó y se revirtió; ver §7).

### 1.2 Flags que probamos en experimentos (no todos a la vez)

```ini
LARECOMP_VK_OPT=1
LARECOMP_ASYNC_SHADERS=1
LARECOMP_VK_NO_GMEM=1
RECOMP_NO_CORES=1
LARECOMP_VK_PRESENT=fifo
```

No los actives todos juntos. Cada uno tiene un costo o un riesgo; están explicados en §4.

---

## 2. Driver Turnip + AdrenoTools (la mejora más grande)

El APK usa un **shim de Vulkan** (`libvulkanshim.so`) que, en vez del driver Adreno stock, carga un **Turnip** custom desde la carpeta de la app usando **AdrenoTools**. No hace falta root.

### 2.1 Qué hace el shim

1. Al arrancar, busca un driver en:
   - `/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/vulkan.ad07xx.so`
   - `/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/libvulkan_freedreno.so`
2. Lo copia a la carpeta interna de la app (`/data/user/0/org.smcraft.smm2recomp/files/driver/`).
3. Lo carga con `adrenotools_open_libvulkan()`.
4. Si no hay driver custom o falla, cae al **loader del sistema** (`/system/lib64/libvulkan.so`).

El shim y AdrenoTools están en el APK; el driver **no** está en el APK ni en este repo. Cada persona lo descarga de su proyecto.

### 2.2 Instalar el driver en el teléfono

```bash
PKG=org.smcraft.smm2recomp
adb shell mkdir -p /sdcard/Android/data/$PKG/files/driver
adb push vulkan.ad07xx.so /sdcard/Android/data/$PKG/files/driver/
adb shell ls -l /sdcard/Android/data/$PKG/files/driver/
```

Reiniciá la app:

```bash
adb shell am force-stop $PKG
adb shell am start -n $PKG/org.libsdl.app.SDLActivity
```

En el log (`.../files/smm2recomp.log`) debería aparecer:

```
[SMM2Shim] copied driver .../driver/vulkan.ad07xx.so -> .../files/driver/vulkan.ad07xx.so
[SMM2Shim] AdrenoTools loaded driver vulkan.ad07xx.so
```

Si aparece `no custom driver found` o `falling back to the system Vulkan loader`, el driver no se copió o no es compatible.

### 2.3 Qué driver usar

- **Adreno 710/720** (POCO X6 5G, Snapdragon 7s Gen 2): un build **Turnip con soporte GMEM**. Los builds llamados “Gmem” o los que documentan `TU_DEBUG=gmem` para 710/720 son los candidatos.
- **Adreno 725/730/740/750/830** (Snapdragon 7+ Gen 2/3, 8 Gen 1/2/3, 8 Elite): probá el Turnip más reciente para tu GPU; si no arranca o tiene artefactos, volvé al driver stock.
- **Adreno 6xx o anterior / Snapdragon 6 Gen 1 o menor**: no está soportado por esta guía; el shim puede caer al driver stock.

**Dónde conseguirlo:** si ya lo tenés en el teléfono, extraelo con `adb pull /sdcard/Android/data/$PKG/files/driver/vulkan.ad07xx.so`. Si no, usá un build **Turnip para tu GPU** de un proyecto comunitario (por ejemplo `Vauzi-17/710` para Adreno 710/720/722, o `K11MCH1/AdrenoToolsDrivers`); verificá que sea **arm64**, **Vulkan 1.3+** y para tu Adreno. No hay un driver universal: si crashea, glitchea o ignora `TU_DEBUG=gmem`, volvé al driver stock o probá otro build.

> El driver es un binario de terceros (Mesa/Turnip). **No lo subas al repo** y no lo redistribuyas fuera de su licencia. Descargalo de su proyecto oficial.

### 2.4 Si el driver rompe la app

1. Borrá el driver:
   ```bash
   adb shell rm -rf /sdcard/Android/data/$PKG/files/driver
   adb shell rm -rf /sdcard/Android/data/$PKG/files/temp
   ```
2. Reiniciá la app: el shim usa el loader del sistema.
3. Si querés probar otro driver, copialo de nuevo y reiniciá.

El shim **no** borra el driver si falla; por eso conviene probar de a uno.

---

## 3. `smm2.ini` — video y resolución

Ubicación normal (APK no debuggable):

```
/sdcard/Android/data/org.smcraft.smm2recomp/files/smm2.ini
```

Si usaste un APK **debuggable** con `PUSH_INTERNAL=1`, la carpeta es interna:

```
/data/data/org.smcraft.smm2recomp/files/smm2.ini
```

### 3.1 Ajustes que usamos

```ini
resolution = 25%
upscaler = bilinear
frame_gen = off
```

| Ajuste | Qué hace | Por qué lo usamos | Costo |
|---|---|---|---|
| `resolution = 25%` | Renderiza el juego al 25 % de la resolución de salida y lo escala. | Es la mayor ganancia de FPS en el POCO X6. | Imagen borrosa; textos/UI pueden verse menos nítidos. |
| `upscaler = bilinear` | Escalado bilineal barato. | Menos costo de GPU que `sharp`. | Un poco más suave/borroso. |
| `frame_gen = off` | Apaga la generación de frames intermedios. | No aumenta los FPS reales de simulación y consume GPU. | Menos “suavidad” artificial; nada real. |

### 3.2 Opciones válidas de `resolution`

El runtime acepta:

- `resolution = match` — resolución de la pantalla (máxima calidad, más lenta).
- `resolution = dynamic` — resolución dinámica (ajusta sola; puede variar el FPS).
- `resolution = 75%` (o `67%`), `50%`, `25%`.
- `resolution = 1`, `2`, `3`, `4` — multiplicador interno (1x–4x; más alto = más lento).

Para el POCO X6 5G: **25 %**. Para un flagship: probá **50 %** o **75 %**; si querés máxima calidad, `match`.

### 3.3 Otras opciones que pueden dar FPS (opcionales, no medidas por nosotros)

| Ajuste | Efecto | Nota |
|---|---|---|
| `antialias = off` | Apaga SMAA. | Puede dar unos FPS; no lo medimos en el POCO. |
| `show_fps = 1` | Muestra el contador de FPS. | No cambia rendimiento; sirve para medir. |
| `aspect = original` | Relación 16:9 original. | No es rendimiento; evita estirar. |

No cambies `antialias` y `resolution` al mismo tiempo: no vas a saber qué mejoró.

### 3.4 Editar y subir el archivo

```bash
PKG=org.smcraft.smm2recomp
adb pull /sdcard/Android/data/$PKG/files/smm2.ini ./smm2.ini
# editá smm2.ini en tu PC
adb push ./smm2.ini /sdcard/Android/data/$PKG/files/smm2.ini
adb shell am force-stop $PKG
adb shell am start -n $PKG/org.libsdl.app.SDLActivity
```

Si la app usa la carpeta interna:

```bash
adb push ./smm2.ini /data/local/tmp/smm2.ini
adb shell run-as $PKG cp /data/local/tmp/smm2.ini files/smm2.ini
adb shell run-as $PKG chmod 644 files/smm2.ini
```

---

## 4. `recomp.env` — flags del runtime

Ubicación normal:

```
/sdcard/Android/data/org.smcraft.smm2recomp/files/recomp.env
```

Formato: **una `NAME=value` por línea**. Las líneas que empiezan con `#` son comentarios. El runtime las carga al arrancar y las imprime en el log como `[env] NAME=value (recomp.env)`.

### 4.1 Flags de la base medida

```ini
TU_DEBUG=gmem
LARECOMP_AHEAD=0
LARECOMP_FPS_INTERVAL=5
LARECOMP_VK_PROF=1
```

| Flag | Qué hace | Nota |
|---|---|---|
| `TU_DEBUG=gmem` | Fuerza a Turnip a usar **GMEM** (renderizado por tiles en la SRAM de la GPU). | Clave en Adreno 710/720. Si ves artefactos, probá `TU_DEBUG=sysmem` (más lento) o quitá el flag. |
| `LARECOMP_AHEAD=0` | Apaga el **compile-ahead** de shaders. | Menos CPU y menos caché; puede aumentar el tirón del primer uso de un shader. Para jugar después de calentar, el default (compile-ahead) puede ser mejor. |
| `LARECOMP_FPS_INTERVAL=5` | Escribe una línea de profiling cada 5 s. | Solo medición. |
| `LARECOMP_VK_PROF=1` | Activa las líneas `[vk] ... fps ...` del backend Vulkan. | Solo medición. |

### 4.2 Flags que probamos (experimentales)

| Flag | Qué hace | Resultado / riesgo |
|---|---|---|
| `LARECOMP_VK_OPT=1` | Compila los shaders con optimización de shaderc (`-O` performance) en vez de la ruta rápida. | Shaders más rápidos en runtime; compilación más lenta. Probalo después de tener el juego estable. |
| `LARECOMP_ASYNC_SHADERS=1` | Compila shaders en segundo plano y **saltea los draws** mientras compilan. | Puede subir FPS durante la compilación, pero **SMM2 pierde renders de una sola vez** (artefactos). No lo dejes como default si ves cosas raras. |
| `LARECOMP_VK_NO_GMEM=1` | Fuerza “sin import de memoria del host”: usa copias por draw. | **Compatibilidad**, no velocidad. Puede arreglar HUD/textos faltantes en teléfonos sin import; suele costar rendimiento. Usalo solo si hace falta. |
| `RECOMP_NO_CORES=1` | Corre los hilos del guest sin exclusividad por núcleo (comportamiento de LAS). | Puede dar FPS, pero **SMM2 tiene carreras** (glitches/inestabilidad). Solo experimento. |
| `LARECOMP_VK_PRESENT=fifo` | Presenta con vsync FIFO. | Sin tearing; si tu FPS ya está por debajo de 60, no te limita. Alternativas: `immediate` (puede rasgar) o `mailbox`. |

### 4.3 Flags de diagnóstico (no son para FPS)

| Flag | Para qué |
|---|---|
| `LARECOMP_VK_PROF=1` + `LARECOMP_FPS_INTERVAL=5` | Medir fps, draws/frame, GPU ms, exec ms, draw ms. |
| `LARECOMP_AHEAD=force` | Forzar compile-ahead (ignora el sello de caché). |
| `LARECOMP_AHEAD=map` | Solo traducir, no compilar. |
| `LARECOMP_AHEAD_LOG=1` | Ver qué shaders se compilan ahead. |
| `LARECOMP_NO_BDA=1` | Volver al binding de storage buffer viejo (compatibilidad). |
| `LARECOMP_VK_NO_BDA=1` | Igual que el anterior, específico de Vulkan. |
| `LARECOMP_LOG_GAPS=<ms>` | Loguear frames que tardaron más de ese tiempo. |
| `LARECOMP_LOG_WAITS=<ms>` | Loguear draws que esperaron por shader/pipeline. |

### 4.4 Flags de compatibilidad para Samsung / One UI (opcional, no probado por nosotros)

Si tenés artefactos de texturas en un Samsung con One UI, probá:

```ini
FD_DEV_FEATURES=enable_tp_ubwc_flag_hint=1
```

Es un flag de Freedreno/Turnip; no es parte de nuestra configuración medida. Si no mejora, quitálo.

### 4.5 Editar y subir `recomp.env`

```bash
PKG=org.smcraft.smm2recomp
adb pull /sdcard/Android/data/$PKG/files/recomp.env ./recomp.env
# editá recomp.env en tu PC
adb push ./recomp.env /sdcard/Android/data/$PKG/files/recomp.env
adb shell am force-stop $PKG
adb shell am start -n $PKG/org.libsdl.app.SDLActivity
```

Si la app usa la carpeta interna:

```bash
adb push ./recomp.env /data/local/tmp/recomp.env
adb shell run-as $PKG cp /data/local/tmp/recomp.env files/recomp.env
adb shell run-as $PKG chmod 644 files/recomp.env
```

---

## 5. Cómo medir (protocolo que usamos)

1. Dejá el teléfono **frío** o en el mismo estado térmico entre pruebas.
2. Cargá **la misma escena** (mismo nivel, misma posición, mismo clima).
3. Esperá **60 s** a que se estabilicen shaders/caché.
4. Medí **60 s × 3**, con `LARECOMP_VK_PROF=1` y `LARECOMP_FPS_INTERVAL=5`.
5. Usá la **mediana** de:
   - `fps`
   - `draws/frame`
   - `gpu ms/frame`
   - `cpu exec ms/frame`
   - `draw ms/frame`
6. Compará contra la base. **Mantené el cambio solo si mejora ≥10 %** y no rompe visuales/estabilidad.
7. Si empeora o rompe, **revertí** el archivo y reiniciá.

### 5.1 Nuestra referencia (POCO X6 5G, `-O2`)

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

### 5.2 Dónde ver los números

```bash
PKG=org.smcraft.smm2recomp
adb shell tail -f /sdcard/Android/data/$PKG/files/smm2recomp.log | grep '\[vk\]'
```

O:

```bash
adb logcat -s smm2recomp | grep '\[vk\]'
```

---

## 6. Orden recomendado para tocar cosas

1. **APK `-O2` estable** instalado y llegando al título.
2. **Driver Turnip** + `TU_DEBUG=gmem` (si tu GPU es Adreno 710/720).
3. **`resolution = 50%`** y medir; después **25%** y medir.
4. **`upscaler = bilinear`**.
5. **`frame_gen = off`**.
6. **`LARECOMP_VK_OPT=1`**.
7. **`LARECOMP_VK_PRESENT=fifo`** (si no lo tenías).
8. Recién ahí los experimentales: `LARECOMP_ASYNC_SHADERS=1`, `RECOMP_NO_CORES=1`.
9. `LARECOMP_VK_NO_GMEM=1` **solo** si hay HUD/textos faltantes o el teléfono no soporta import de memoria.

Si un paso no da ≥10 %, **revertilo**. No acumules cambios sin medir.

---

## 7. Lo que NO ayudó (y por qué)

| Cambio | Resultado | Decisión |
|---|---|---|
| `GENOPT=-O3` | 19.0 fps en frío / 20.25 en caliente vs **21.0** del `-O2`; más draws (297.5 vs 276.7). | **Revertido** al `-O2`. |
| `frame_gen = 120` | Genera frames intermedios; no aumenta la simulación y consume GPU. | **Off**. |
| Resolución alta / AA | Más carga de GPU; el límite es CPU. | **25 % + bilinear** en el POCO. |
| PGO | Quedó a medias por un reinicio; el cuello sigue siendo el hilo principal. | **Opcional/experimental** (`scripts/pgo.sh`). |
| `LARECOMP_ASYNC_SHADERS=1` | Puede dar FPS, pero pierde renders de una sola vez. | **Solo prueba**; no default. |
| `RECOMP_NO_CORES=1` | Puede dar FPS, pero SMM2 tiene carreras. | **Solo prueba**; no default. |
| `LARECOMP_VK_NO_GMEM=1` | Compatibilidad, no velocidad. | **Solo si hace falta**. |

---

## 8. Expectativas reales por gama

| Gama | Ejemplo | Qué esperar |
|---|---|---|
| **Reporte de esta guía, no verificado por upstream** | POCO X6 5G (SD 7s Gen 2, Adreno 710, 8 GB) | ~20–21 fps en niveles pesados; título ~30 fps. No es una garantía ni compatibilidad oficial. |
| Alta media | SD 7+ Gen 2/3 | Mejor GPU; el CPU sigue siendo el límite. Probá 50 % de resolución. |
| Flagship | SD 8 Gen 1/2/3, 8+ Gen 1, 8 Elite | Más margen de GPU; **30 fps no garantizados** en niveles pesados. |
| No soportado | SD 6 Gen 1 o menor, 4–6 GB, 32-bit/x86, Android <13, sin Vulkan 1.3 | Puede no arrancar o ir a 5–10 fps. |

**No prometas 30 fps.** El port es CPU-bound en el hilo principal del juego. Los flags y el driver mejoran la GPU y la estabilidad, pero no cambian el techo del hilo principal.

---

## 9. Legal

- El driver Turnip es software de terceros (Mesa); se descarga de su proyecto y **no se incluye** en este repo.
- Este repositorio no está destinado a alojar APK, `libsmm2game.so`, archivos del juego, keys, firmware, drivers binarios ni tokens.
- Las licencias declaradas para contribuciones originales y sus límites están en `LICENSE.md`; verifica procedencia y dependencias.
- No tomes esta guía como conclusión sobre la legalidad de extraer, compilar, usar online o redistribuir. Consulta `LEGAL.md`, avisos upstream y asesoría cualificada para una decisión concreta.


