<div align="center">

# 🍄 SMM2 Recomp para Android
### Guía comunitaria para compilar desde tu propio dump

**Sigue el proceso con calma, conserva tus archivos privados y verifica cada paso.**

[![Android](https://img.shields.io/badge/Android-13%2B-3DDC84?logo=android&logoColor=white)](#compatibilidad)
[![Arquitectura](https://img.shields.io/badge/ABI-arm64--v8a-6f42c1)](#compatibilidad)
[![Vulkan](https://img.shields.io/badge/Gráficos-Vulkan%201.3-AC162C?logo=vulkan&logoColor=white)](#compatibilidad)
[![Idioma](https://img.shields.io/badge/Guía-español-blue)](#)
[![Sin archivos del juego](https://img.shields.io/badge/Contenido-del%20usuario%20solamente-success)](#privacidad-y-legalidad)

</div>

> [!IMPORTANT]
> Esta es una guía comunitaria, no un APK. Necesitas tu propia copia legal de *Super Mario Maker 2* y su actualización 3.0.3. El proyecto oficial indica que Android se compila desde el código fuente. Su documentación actual informa que Android ha arrancado en el emulador y que todavía no se ha probado en un teléfono físico. Consulta siempre el estado y las instrucciones oficiales antes de compilar.

## 🧭 Navegación

- [Qué es este paquete](#qué-es-este-paquete)
- [Estado y compatibilidad](#estado-y-compatibilidad)
- [Estado y fuentes](ESTADO_ANDROID.md)
- [Archivos](#qué-incluye)
- [Empezar](#empezar)
- [Mensaje para la IA](#mensaje-para-la-ia)
- [Privacidad y legalidad](#privacidad-y-legalidad)
- [Licencias y créditos](#licencias-y-créditos)

## 🎮 Qué es este paquete

Paquete legal para compilar **SMM2 Recomp en Android arm64** desde tu propio dump de *Super Mario Maker 2* + update 3.0.3.

Incluye:

- Guía paso a paso para preparar el entorno, generar el código y compilar el APK.
- Prompt PRO para OpenCode + DeepSeek V4.1.
- Checklist de preparación, build e instalación.
- Notas de rendimiento sobre Turnip/AdrenoTools, resolución y flags del runtime.
- Shim de Vulkan y su generador de stubs.
- Scripts auxiliares para build Android y el experimento PGO.

**No incluye** el juego, ROMs, NSP/XCI, `prod.keys`, firmware, APK, `libsmm2game.so`, drivers binarios ni tokens de OpenCourse World. Cada persona trabaja con su propia copia y mantiene sus datos privados.

## 📡 Estado y compatibilidad

SMM2 Recomp es un proyecto de recompilación estática. La guía describe una ruta experimental para Android; no implica que todos los teléfonos sean compatibles.

| Dato | Estado que documenta el proyecto oficial |
|---|---|
| Android | Android 13 o posterior, arm64 y Vulkan 1.3 con las funciones requeridas |
| Prueba Android publicada | Emulador Android arm64; arranque y curso inicial |
| Teléfono físico | La documentación oficial consultada indica que todavía no se ha probado |
| Memoria | El juego usa alrededor de 3.2 GB de heap; se recomienda disponer de 8 GB de RAM |

Las cifras del POCO X6 5G incluidas en `MODS.md` son **mediciones reportadas por esta guía**, no resultados certificados por el equipo oficial. El rendimiento varía por teléfono, driver, temperatura y escena. No se promete una tasa de FPS.

Antes de ejecutar los pasos, revisa [README oficial](https://github.com/smm2recomp/smm2recomp) y [recomp/README oficial](https://github.com/smm2recomp/smm2recomp/blob/main/recomp/README.md). Las rutas y herramientas del upstream pueden cambiar.

## 📦 Qué incluye

| Archivo | Para qué sirve |
|---|---|
| `PROMPT.md` | Manual de build, instalación, datos, OCW, rendimiento y PGO. |
| `OPENCODE_PROMPT.md` | Prompt completo para OpenCode + DeepSeek V4.1. |
| `MODS.md` | Ajustes gráficos, driver, flags y protocolo de medición. |
| `CHECKLIST.md` | Lista de verificación antes, durante y después del build. |
| `FAQ.md` | Respuestas a dudas comunes y solución de errores. |
| `REPO.md` | Pasos y controles para preparar una publicación. |
| `LICENSE.md` | Alcance de las licencias de la guía y del shim. |
| `vulkan-shim/` | Código fuente del shim, generador y pasos para compilarlo. |
| `scripts/build_android.sh` | Wrapper opcional para generar y compilar el APK. |
| `scripts/pgo.sh` | Experimento opcional de Profile Guided Optimization. |
| `GITHUB_PUBLICACION.md` | Descripción, temas y texto inicial para presentar el paquete. |
| `ESTADO_ANDROID.md` | Diferencia el estado oficial de Android y las mediciones reportadas por esta guía. |

## 🚀 Empezar

1. Lee esta página y revisa las instrucciones actuales del [proyecto oficial](https://github.com/smm2recomp/smm2recomp).
2. Descomprime este paquete en Linux, macOS o WSL2. Los comandos incluidos se escribieron principalmente para Linux/WSL2.
3. Abre `OPENCODE_PROMPT.md` y pásaselo a tu asistente junto con los demás archivos indicados.
4. Ten a mano las **rutas locales** de tus propios archivos. No pegues keys, tokens ni contenido del dump en un chat.
5. Sigue `PROMPT.md` y marca cada paso de `CHECKLIST.md`. Si un comando falla, detente y revisa el error completo.
6. Usa `MODS.md` solo después de lograr un build funcional; mide un ajuste por vez.

### Requisitos generales

- Un ordenador compatible con las instrucciones actuales del upstream; Linux/WSL2 es el camino descrito por esta guía.
- Android SDK, NDK, JDK y dependencias en las versiones requeridas por el estado actual del proyecto.
- Teléfono Android arm64 con Vulkan compatible, si vas a experimentar en hardware físico.
- Dump legal de SMM2 base y update 3.0.3.

> [!WARNING]
> No copies comandos a ciegas. El upstream cambia y esta guía comunitaria puede quedar desactualizada. Confirma versiones, rutas y objetivos de `make` en la documentación oficial antes de cada build.

## 🤖 Mensaje para la IA

Puedes copiar este mensaje y adjuntar el ZIP del paquete:

```markdown
Vas a trabajar con el paquete `smm2-recomp-guia-legal` que está en esta carpeta. Lee primero `OPENCODE_PROMPT.md` completo; después lee `PROMPT.md`, `MODS.md` y `CHECKLIST.md`. Antes de ejecutar comandos, compara las instrucciones con la documentación oficial actual de SMM2 Recomp y señala cualquier diferencia.

Mi objetivo es compilar SMM2 Recomp para Android arm64 desde mi propio dump legal de Super Mario Maker 2 + update 3.0.3, instalarlo en mi POCO X6 5G (Snapdragon 7s Gen 2, Adreno 710, 8 GB, Android 13+), configurar mi propia cuenta de OpenCourse World y, si te lo pido, preparar el repo público de esta guía.

Reglas:
- Pídeme rutas locales del dump, de `prod.keys` y del firmware; no me pidas que pegue su contenido, el token de OCW ni archivos del juego.
- No imprimas ni subas `prod.keys`, firmware, `ocw-config.json`, el token, el APK, `libsmm2game.so`, el juego ni el driver.
- El APK es para mis dispositivos y no se comparte.
- La guía informa que el proyecto oficial todavía no ha probado Android en un teléfono físico. Trata cualquier prueba en mi POCO como experimental; no prometas compatibilidad ni FPS.
- Muéstrame el comando y explica qué modifica antes de ejecutarlo. Si algo falla, muéstrame el error completo y espera.

Empieza leyendo los archivos y después pídeme los datos que falten. Guíame paso a paso.
```

## 🔐 Privacidad y legalidad

Este repositorio contiene documentación y código auxiliar. No debe contener material del juego ni archivos personales. No subas, entre otros:

- ROMs, NSP/XCI, `prod.keys` o firmware.
- APK, `libsmm2game.so`, `libmain.so` ni archivos generados desde un dump.
- `ocw-config.json`, tokens, contraseñas o cookies.
- Drivers binarios de terceros, logs privados o datos de usuario.

Cada usuario debe obtener y usar sus propios archivos, respetar las licencias aplicables y las condiciones de los servicios que utilice. Esta guía no es asesoría legal ni está afiliada a Nintendo.

## 📜 Licencias y créditos

- La guía y sus scripts se ofrecen bajo CC BY 4.0, según `LICENSE.md`.
- `vulkan-shim/` se ofrece bajo GPLv3, según `LICENSE.md`.
- SMM2 Recomp mantiene su licencia y atribuciones en el [repositorio oficial](https://github.com/smm2recomp/smm2recomp).
- *Super Mario Maker 2* es una marca de Nintendo. Este paquete no está afiliado ni respaldado por Nintendo.

## 🤝 Contribuir

Las mejoras de redacción, correcciones de pasos y reportes reproducibles son bienvenidos. Incluye versiones de herramientas y mensajes de error relevantes, pero elimina rutas personales, tokens, claves, dumps y cualquier dato privado antes de compartir un log.

<div align="center">

**Compila con tu propia copia. Mide, documenta y comparte solo lo que tienes derecho a compartir.**

</div>

