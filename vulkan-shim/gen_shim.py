#!/usr/bin/env python3
"""Generate the Vulkan loader shim's tables from Vulkan-Headers.

Usage:
    VULKAN_CORE_H=/path/to/Vulkan-Headers/include/vulkan/vulkan_core.h \
    SHIM_OUT=/path/to/vulkan-shim \
    python3 gen_shim.py

Writes globals.h, init.h and stubs.S next to this script (or SHIM_OUT).
"""
import os
import re

HDR = os.environ.get("VULKAN_CORE_H", "/usr/include/vulkan/vulkan_core.h")
OUT = os.environ.get("SHIM_OUT", os.path.dirname(os.path.abspath(__file__)))
os.makedirs(OUT, exist_ok=True)

with open(HDR, "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# Match Vulkan command declarations: VKAPI_ATTR <ret> VKAPI_CALL vkName(
pat = re.compile(r"VKAPI_ATTR\s+[A-Za-z0-9_*\s]+?\s+VKAPI_CALL\s+(vk[A-Za-z0-9_]+)\s*\(")
names = sorted(set(pat.findall(text)))
print(f"{len(names)} Vulkan commands")

with open(os.path.join(OUT, "globals.h"), "w") as f:
    f.write("// generated\n")
    for n in names:
        f.write(f'__attribute__((visibility("hidden"))) void *g_{n};\n')

with open(os.path.join(OUT, "init.h"), "w") as f:
    f.write("// generated\n")
    f.write("int missing = 0;\n")
    for n in names:
        f.write(f'g_{n} = dlsym(g_handle, "{n}"); if (!g_{n}) missing++;\n')
    f.write('LOGI("Vulkan entry points: %d missing", missing);\n')

with open(os.path.join(OUT, "stubs.S"), "w") as f:
    f.write("// generated: tail-call stubs, one per Vulkan command\n")
    f.write(".text\n")
    for n in names:
        f.write(f""".globl {n}
.type {n}, %function
{n}:
    adrp x16, g_{n}
    ldr x16, [x16, :lo12:g_{n}]
    cbz x16, 1f
    br x16
1:  brk #0
.size {n}, .-{n}
""")
    f.write('.section .note.GNU-stack,"",%progbits\n')

print("wrote", OUT)
