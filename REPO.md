# Crear el repo de la guía

Este repo contiene **solo la guía, el prompt, el checklist, los mods de rendimiento, el shim y los scripts**. No contiene juego, keys, firmware, APK, `libsmm2game.so` ni tokens.

> Si la otra IA trabaja en Linux/WSL, descomprimí el ZIP ahí y usá esa ruta en `cd`; los comandos son los mismos.

## Nombre sugerido

- `smm2-recomp-android-guia`
- `smm2-recomp-legal-build`
- `smm2-recomp-android`

## Descripción

> Guía legal para compilar SMM2 Recomp en Android desde tu propio dump. Sin juego, keys, firmware ni tokens. Cada persona compila lo suyo con su copia legal.

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

git add .gitignore README.md PROMPT.md MODS.md OPENCODE_PROMPT.md CHECKLIST.md REPO.md FAQ.md LICENSE.md vulkan-shim scripts

# Windows: después del git add, marcá los scripts como ejecutables en el índice:
# git update-index --chmod=+x scripts/build_android.sh scripts/pgo.sh

git commit -m "Guía legal para compilar SMM2 Recomp en Android"
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
3. **Public** (la guía no tiene datos privados).
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

`smm2`, `super-mario-maker-2`, `android`, `recomp`, `vulkan`, `turnip`, `adrenotools`, `legal`, `build-guide`.

## Primer mensaje para la otra IA

> Este repo es solo la guía. Cloná <https://github.com/smm2recomp/smm2recomp> (GPLv3), leé `PROMPT.md` y `MODS.md`, y guiame paso a paso para compilar SMM2 Recomp en Android con mi propio dump. Tengo mi copia legal. No te voy a pasar keys, firmware ni token por chat; el token de OCW lo escribo yo en el teléfono. No subas el APK, el juego, las keys, el firmware, el driver ni el token a ningún lado.

## Licencia

- Guía y scripts: **CC BY 4.0**.
- `vulkan-shim/`: **GPLv3**.
- Proyecto SMM2 Recomp: **GPLv3** (se clona aparte; no está en este repo).
- Nintendo: sin afiliación; sin código ni assets de Nintendo.
