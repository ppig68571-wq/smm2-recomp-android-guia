# Preguntas frecuentes

> **Estado experimental:** consulta [`ESTADO_ANDROID.md`](ESTADO_ANDROID.md) y la documentación oficial actual antes de seguir pasos de build o asumir compatibilidad. El upstream indica que Android se probó en el emulador, no en teléfonos físicos. Las cifras de POCO X6 son reportes de esta guía sin verificación independiente.

## Legal

**¿Esto garantiza que mi uso sea legal o que no me demanden?**
No. No podemos determinarlo: depende de las leyes de tu jurisdicción, cómo obtuviste y procesaste los archivos, las licencias y las condiciones aplicables. Tener una copia propia no resuelve por sí solo esas preguntas. Lee [`LEGAL.md`](LEGAL.md), los avisos upstream y consulta a un profesional jurídico si necesitas una respuesta para tu caso.

**¿Puedo compartir el APK?**
Esta guía no recomienda publicar ni enviar APKs o bibliotecas generadas desde archivos del juego. Revisa las instrucciones actuales del proyecto upstream y la ley aplicable antes de compartir cualquier resultado. La licencia GPL del código del proyecto no licencia el juego ni resuelve los derechos sobre contenido generado.

**¿Puedo prestar mi cuenta de OCW o usar la de otra persona?**
Trata el token como una credencial privada. Para saber si se permite compartir cuentas o tokens, consulta los términos actuales de OpenCourse World; esta guía no hace esa determinación.

**¿Puedo vender el APK?**
No uses esta FAQ como autorización para vender o redistribuir un APK. La GPL del código del proyecto no concede derechos sobre el juego ni sobre los archivos generados. Verifica derechos, licencias y leyes con asesoramiento cualificado antes de cualquier distribución comercial.

## Compatibilidad

**¿Qué teléfonos sirven?**
Android 13+, **arm64-v8a**, **Vulkan 1.3** (dynamic rendering, timeline semaphores, 8-bit storage, scalar block layout), **8 GB de RAM (mínimo práctico; 6 GB no soportado)** y ~3–4 GB de almacenamiento. El APK es **arm64 only**: no corre en 32 bits ni x86.

**¿Qué Snapdragon?**
El upstream consultado indica Android 13+, arm64, Vulkan 1.3 con las funciones requeridas y recomienda 8 GB o más; sus pruebas Android son en emulador, no en teléfono físico. Esta guía contiene cifras reportadas de POCO X6, aún sin verificación independiente. No hay lista oficial de teléfonos soportados ni FPS garantizados. Ver `ESTADO_ANDROID.md`.

**¿Cuánta RAM?**
**8 GB es el mínimo práctico** (el guest usa ~3.2 GB de heap). 6 GB no está soportado; 4 GB no es recomendable. Si tenés 6 GB, puede arrancar, pero no lo presentes como compatible.

**¿Necesito root?**
No. El build y la instalación son sin root. El driver Turnip se carga con AdrenoTools, sin root.

**¿Necesito una PC?**
Sí. El juego se compila en la PC (Linux/WSL2 o macOS); el teléfono solo ejecuta el APK.

**¿Funciona en Windows?**
Sí, con **WSL2 + Ubuntu**. El camino probado fue Ubuntu/WSL2. También macOS.

**¿Cuánto tarda?**
Depende de la PC: dependencias ~10–20 min, `gen` ~10–30 min, APK ~5–15 min. La primera vez es lo más lento.

## Juego y datos

**¿Puedo usar solo el juego base?**
No: el proyecto necesita el **update 3.0.3** (ExeFS + RomFS). Sin el update, no pasa la verificación.

**¿De dónde saco las keys/firmware?**
De tu propia consola o de tu propio dump. No se comparten. Se usan solo para extraer fuentes/sysdata; el script las lee en el lugar y no las copia.

**¿Qué pasa si no genero fonts/sysdata?**
El runtime sustituye una fuente del host (se ve distinto) y el juego puede detenerse en el primer Mii por falta del modelo Mii. Es recomendable generarlos.

**¿Por qué el APK pesa ~160 MB?**
`libsmm2game.so` es el código del juego recompilado (~140 MB) y va dentro del APK. Es normal.

## Rendimiento

**¿Por qué no llega a 30 fps?**
El cuello es el **hilo principal del juego** (~97.6 % de un núcleo en nuestra prueba). La GPU (18 ms/frame) y el render (8 ms/frame) no son el límite. `-O3` y PGO no garantizan una mejora.

**¿`-O3` ayuda?**
En nuestra prueba no: 19.0 fps en frío y 20.25 en caliente vs 21.0 del `-O2`. El hilo de render mejoró, pero el hilo principal sigue igual. Se revirtió.

**¿PGO ayuda?**
Es experimental. En nuestra prueba quedó a medias por un reinicio; el cuello sigue siendo el hilo principal. Está incluido como opcional en `PROMPT.md` y `scripts/pgo.sh`.

**¿Qué mods usaron para obtener más FPS?**
Están todos en **`MODS.md`**. En resumen: driver **Turnip** con **AdrenoTools** + shim, `TU_DEBUG=gmem` (Adreno 710/720), `resolution = 25%`, `upscaler = bilinear`, `frame_gen = off`, y flags de runtime (`LARECOMP_AHEAD=0`, `LARECOMP_VK_OPT=1`, `LARECOMP_VK_PRESENT=fifo`, etc.). No hay un mod mágico: el cuello es el hilo principal del juego.

**¿Qué es `TU_DEBUG=gmem`?**
Es un flag de Turnip que fuerza el renderizado por tiles en la GMEM de la GPU. En Adreno 710/720 (POCO X6 5G) suele mejorar el rendimiento y evitar glitches. Si ves artefactos, probá `TU_DEBUG=sysmem` o quitá el flag.

**¿Dónde pongo el driver Turnip?**
En `/sdcard/Android/data/org.smcraft.smm2recomp/files/driver/vulkan.ad07xx.so` (o `libvulkan_freedreno.so`). El shim lo copia a la carpeta interna y lo carga con AdrenoTools. Si no hay driver, usa el loader del sistema. El driver **no** va al repo.

**¿`frame_gen = 120` sirve para FPS?**
No para FPS reales: genera frames intermedios y consume GPU. Para medir rendimiento, `frame_gen = off`.

**¿Qué flags son peligrosas?**
`LARECOMP_ASYNC_SHADERS=1` puede hacer que SMM2 pierda renders de una sola vez; `RECOMP_NO_CORES=1` puede provocar carreras/glitches. `LARECOMP_VK_NO_GMEM=1` es compatibilidad, no velocidad. Probalas de a una y revertí si rompen.

**¿Puedo bajar la resolución?**
Sí, en `smm2.ini` (`resolution = 25%`, `50%`, `75%`, `dynamic`, `match`). En el POCO X6 el 25 % fue el baseline; en un flagship probá 50 % o 75 %. Cambiá una cosa a la vez.

**¿Puedo usar mando?**
Sí: Bluetooth o USB por SDL. También teclado.

## Online

**¿Qué es OCW?**
OpenCourse World, un servicio online alternativo para SMM2. Cada persona se registra y usa su cuenta.

**¿Puedo jugar online con Nintendo?**
No. El mod usa OCW, no los servidores de Nintendo.

**¿Qué es el token?**
La credencial de tu cuenta de OCW. Es secreto: no va al repo, ni al chat, ni a los logs. El runtime lo redacta en los logs.

## Errores

**“built for another version” / crash al arrancar**
`GAMELIB_ID` distinto entre `libmain.so` y `libsmm2game.so`. Borrá `build/smm2-android-arm64-0x800000000/obj` y `build/smm2-android-arm64-0x800000000/rt/gamelib.o`, y recompilá con los mismos `GENOPT`.

**`INSTALL_FAILED_VERSION_DOWNGRADE`**
El APK nuevo tiene `versionCode` menor que el instalado. Recompilá (el build usa minutos desde 1970, así que sube) o desinstalá (pierde datos). El parche de manifiesto + `apksigner` es avanzado y no recomendado.

**“Permission denied” leyendo `extracted/`**
Android 11+ y archivos copiados por adb. Compilá con `RECOMP_ANDROID_DEBUGGABLE=1` y usá `PUSH_INTERNAL=1`.

**No arranca / crash de Vulkan**
El teléfono necesita Vulkan 1.3 con las extensiones requeridas. Probá el driver stock o un Turnip compatible; mirá `adb logcat`.

**OCW no conecta**
Revisá `backend=ocw`, `ocw-config.json` (dominio/token), TLS 1.2, `net_log=1`, `log=1`. El token se redacta en los logs.

## Repo

**¿Puedo publicar o reutilizar esta guía?**
Consulta el alcance y las condiciones por archivo en [`LICENSE.md`](LICENSE.md). Esa declaración cubre solo contribuciones originales que el publicador pueda licenciar; materiales de terceros mantienen sus propios términos. Comprueba también las políticas de GitHub.

**¿Puedo publicar el APK o el `libsmm2game.so`?**
El repositorio no está destinado a alojar esos binarios. Si estás considerando redistribuirlos, no asumas que esta guía o la GPL te autorizan: consulta las normas, condiciones y asesoramiento jurídico aplicables.

**¿Puedo publicar el `vulkan-shim`?**
La licencia indicada para las contribuciones originales del shim figura en [`LICENSE.md`](LICENSE.md). Verifica procedencia, dependencias y obligaciones de licencia antes de redistribuirlo.


