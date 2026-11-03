# Crear el repo de la guía

Este repo contiene **solo la guía, el prompt, el checklist, los mods de rendimiento, el shim y los scripts**. No contiene juego, keys, firmware, APK, `libsmm2game.so` ni tokens.

> Si la otra IA trabaja en Linux/WSL, descomprimí el ZIP ahí y usá esa ruta en `cd`; los comandos son los mismos.

## Nombre sugerido

- `smm2-recomp-android-guia`
- `smm2-recomp-legal-build`
- `smm2-recomp-android`

## Descripción

> Guía comunitaria independiente sobre SMM2 Recomp en Android. No contiene archivos del juego, keys, firmware ni tokens. No ofrece asesoría legal; consulta `LEGAL.md`.

## Estructura

```
.
├── .gitignore
├── README.md
├── PROMPT.md
├── MODS.md
├── OPENCODE_PROMPT.md
├── CHECKLIST.md
├── REPO.md
├── FAQ.md
├── LICENSE.md
├── LEGAL.md
├── vulkan-shim/
│   ├── README.md
│   ├── shim.c
│   └── gen_shim.py
└── scripts/
    ├── build_android.sh
    └── pgo.sh
```

## Subir

```bash
# Linux/WSL2/macOS:
cd /ruta/a/smm2-recomp-guia-legal
# Windows PowerShell:
# cd "C:\ruta\a\smm2-recomp-guia-legal"

git init

# Linux/WSL2/macOS:
chmod +x scripts/*.sh

git add .gitignore README.md PROMPT.md MODS.md OPENCODE_PROMPT.md CHECKLIST.md REPO.md FAQ.md LICENSE.md LEGAL.md vulkan-shim scripts

# Windows: después del git add, marcá los scripts como ejecutables en el índice:
# git update-index --chmod=+x scripts/build_android.sh scripts/pgo.sh

git commit -m "Publicar guía Android de SMM2 Recomp"
git branch -M main

# Creá el repo vacío en GitHub y después:
git remote add origin https://github.com/<tu-usuario>/<tu-repo>.git
git push -u origin main
```

### Con GitHub CLI

```bash
gh auth login
gh repo create <tu-usuario>/<tu-repo> --public --source=. --remote=origin --push
```

### Con la web

1. GitHub → **New repository**.
2. Nombre: `smm2-recomp-android-guia`.
3. Elige visibilidad según tu objetivo y revisa el contenido antes de publicar; una guía pública no queda libre de reclamos por contener material de terceros.
4. **No** agregues README, `.gitignore` ni licencia desde la web (ya están).
5. Subí los archivos o usá los comandos de arriba.

## Verificación antes de subir

```bash
# No debe haber nada de esto:
git status --short

# 1) Archivos prohibidos por nombre/extensión (no por menciones en la guía):
git ls-files | grep -Ei '\.(apk|aab|so|nsp|xci|nca|keys|profraw|profdata|log)$|(^|/)prod\.keys$|(^|/)ocw-config\.json$' \
  && echo "HAY ARCHIVOS PROHIBIDOS: no subas esto" \
  || echo "OK: sin archivos prohibidos"

# 2) Secretos reales (clave privada o token con valor):
grep -RInE 'BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|"token"[[:space:]]*:[[:space:]]*"[A-Za-z0-9_-]{10,}"' . --exclude-dir=.git \
  && echo "HAY SECRETOS: no subas esto" \
  || echo "OK: sin secretos"

# Tamaño del repo (debe ser chico, < 1 MB):
du -sh .
```

Si `grep` encuentra algo, **no lo subas**: revisá y borrá ese archivo.

## Lo que NO va al repo

- `private/`, `generated/`, `build/` del proyecto.
- APK, `libsmm2game.so`, `libmain.so`.
- `prod.keys`, firmware, NSP/XCI, ROMs.
- `ocw-config.json`, el token de OCW.
- Driver Turnip binario (`vulkan.ad07xx.so`, `libvulkan_freedreno.so`).
- `smm2recomp.log`, capturas con rutas privadas.
- Cualquier archivo de Nintendo.

## Topics sugeridos

`smm2`, `super-mario-maker-2`, `android`, `recomp`, `vulkan`, `turnip`, `adrenotools`, `build-guide`, `spanish`.

## Primer mensaje para la otra IA

> Este repo contiene una guía comunitaria, no archivos del juego. Cloná <https://github.com/smm2recomp/smm2recomp>, leé `PROMPT.md`, `MODS.md` y `LEGAL.md`, y guiame paso a paso con mis propios archivos. No te voy a pasar keys, firmware ni token por chat; no subas APKs, archivos del juego, claves, firmware, drivers ni credenciales. No emitas conclusiones jurídicas sobre mi situación.

## Licencias y avisos

- Las licencias declaradas para contribuciones originales y sus límites están en `LICENSE.md`.
- Los componentes externos mantienen sus licencias; verifica sus avisos antes de redistribuir.
- El proyecto SMM2 Recomp tiene sus propios avisos en su repositorio; su licencia no cubre el juego ni los archivos generados.
- Revisa `LEGAL.md`; esta guía no determina si un uso concreto es legal ni garantiza que no haya reclamos.
- Nintendo: este proyecto independiente no pretende incluir archivos del juego y no está afiliado ni respaldado por Nintendo. Consulta `LEGAL.md` para el alcance y los límites de esta declaración.
