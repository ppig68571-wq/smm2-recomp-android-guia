// libvulkanshim.so: a tiny Vulkan loader that routes the app's Vulkan calls
// through AdrenoTools (custom Turnip driver) instead of the stock Adreno driver.
//
// Build: see README.md in this folder. The package name below must match
// RECOMP_ANDROID_PACKAGE (default: org.smcraft.smm2recomp).
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <android/log.h>
#include <adrenotools/driver.h>

#define LOG_TAG "SMM2Shim"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#include "globals.h"

static void *g_handle;

static void mkdir_p(const char *path) {
    char tmp[PATH_MAX];
    size_t len = strlen(path);
    if (len >= sizeof(tmp)) return;
    memcpy(tmp, path, len + 1);
    for (char *p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0700);
            *p = '/';
        }
    }
    mkdir(tmp, 0700);
}

static int copy_file(const char *src, const char *dst) {
    FILE *in = fopen(src, "rb");
    if (!in) return -1;
    FILE *out = fopen(dst, "wb");
    if (!out) { fclose(in); return -1; }
    char buf[65536];
    size_t n;
    int ok = 0;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
        if (fwrite(buf, 1, n, out) != n) { ok = -1; break; }
    }
    fclose(in);
    if (fclose(out) != 0) ok = -1;
    return ok;
}

__attribute__((constructor)) static void shim_init(void) {
    Dl_info info;
    char libdir[PATH_MAX] = {0};
    if (dladdr((void *)&shim_init, &info) && info.dli_fname) {
        strncpy(libdir, info.dli_fname, sizeof(libdir) - 1);
        char *slash = strrchr(libdir, '/');
        if (slash) *slash = 0;
    }
    LOGI("native lib dir: %s", libdir);

    const char *internal = "/data/user/0/org.smcraft.smm2recomp/files";
    const char *external = "/storage/emulated/0/Android/data/org.smcraft.smm2recomp/files";
    char drvdir[PATH_MAX], tmpdir[PATH_MAX];
    snprintf(drvdir, sizeof(drvdir), "%s/driver/", internal);
    snprintf(tmpdir, sizeof(tmpdir), "%s/temp/", internal);
    mkdir_p(internal);
    mkdir_p(drvdir);
    mkdir_p(tmpdir);

    const char *drivers[] = {"vulkan.ad07xx.so", "libvulkan_freedreno.so", NULL};
    const char *chosen = NULL;
    for (int i = 0; drivers[i]; i++) {
        char src[PATH_MAX], dst[PATH_MAX];
        snprintf(src, sizeof(src), "%s/driver/%s", external, drivers[i]);
        snprintf(dst, sizeof(dst), "%s/%s", drvdir, drivers[i]);
        if (copy_file(src, dst) == 0) {
            LOGI("copied driver %s -> %s", src, dst);
            if (!chosen) chosen = drivers[i];
        } else {
            LOGI("driver not found at %s (%s)", src, strerror(errno));
        }
    }
    if (!chosen) {
        LOGE("no custom driver found in %s/driver", external);
    }

    if (chosen) {
        g_handle = adrenotools_open_libvulkan(RTLD_NOW | RTLD_LOCAL, ADRENOTOOLS_DRIVER_CUSTOM,
                                              tmpdir, libdir, drvdir, chosen, NULL, NULL);
        if (g_handle) LOGI("AdrenoTools loaded driver %s", chosen);
        else LOGE("adrenotools_open_libvulkan failed: %s", dlerror());
    }
    if (!g_handle) {
        g_handle = dlopen("/system/lib64/libvulkan.so", RTLD_NOW | RTLD_LOCAL);
        if (!g_handle) g_handle = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
        if (g_handle) LOGE("falling back to the system Vulkan loader");
    }
    if (!g_handle) {
        LOGE("no Vulkan library at all");
        return;
    }

#include "init.h"
}
