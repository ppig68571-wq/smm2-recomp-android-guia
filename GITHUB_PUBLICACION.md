# Ficha para publicar en GitHub

## Nombre sugerido

`smm2-recomp-android-guia`

## Descripción corta

Guía comunitaria en español para compilar SMM2 Recomp en Android desde tu propio dump legal. Incluye pasos, checklist, notas de rendimiento y herramientas auxiliares; no incluye el juego ni archivos privados.

## Texto para explicar qué es el paquete

Paquete legal para compilar SMM2 Recomp en Android arm64 desde tu propio dump de Super Mario Maker 2 + update 3.0.3.

Incluye:
- Guía paso a paso.
- Prompt PRO para OpenCode + DeepSeek V4.1.
- Checklist.
- Ajustes de rendimiento (Turnip/AdrenoTools, resolución, flags).
- Shim de Vulkan.
- Scripts de build y PGO.

No incluye el juego, ROMs, NSP/XCI, prod.keys, firmware, APK, libsmm2game.so, drivers binarios ni tokens de OCW.

Cada persona compila su propia copia legal para sus propios dispositivos.

## Topics sugeridos

`smm2`, `android`, `recompilation`, `vulkan`, `turnip`, `build-guide`, `spanish`

## Texto inicial para compartir el ZIP con otra IA

Vas a trabajar con el paquete `smm2-recomp-guia-legal` que está en esta carpeta. Leé primero `OPENCODE_PROMPT.md` completo; después leé `PROMPT.md`, `MODS.md` y `CHECKLIST.md`. Seguí ese prompt al pie de la letra y contrasta sus comandos con la documentación oficial actual antes de ejecutarlos.

Mi objetivo es compilar SMM2 Recomp para Android arm64 desde mi propio dump legal de Super Mario Maker 2 + update 3.0.3, instalarlo en mi POCO X6 5G (Snapdragon 7s Gen 2, Adreno 710, 8 GB, Android 13+), configurar mi propia cuenta de OpenCourse World y, si te lo pido, crear el repo público de la guía.

Reglas:
- Pedime las rutas locales del dump, de `prod.keys` y del firmware; no me pidas que pegue su contenido, ni el token de OCW, ni archivos del juego.
- No imprimas ni subas `prod.keys`, firmware, `ocw-config.json`, el token, el APK, `libsmm2game.so`, el juego ni el driver.
- El APK es para mis dispositivos y no se comparte.
- La documentación oficial actual dice que Android todavía no se ha probado en un teléfono físico; trata la instalación en mi POCO como experimental y no prometas compatibilidad ni FPS.
- Si algo falla, mostrame el error completo y esperá instrucciones.

Empezá leyendo los archivos y después pedime los datos que falten. Guiame paso a paso.

## Nota de estado

La compatibilidad y los comandos pueden cambiar con el upstream. Revisa el README oficial y `recomp/README.md` antes de publicar una nueva versión de esta guía. Los datos de rendimiento del POCO X6 incluidos en `MODS.md` son resultados reportados por este paquete y no deben presentarse como pruebas oficiales.
