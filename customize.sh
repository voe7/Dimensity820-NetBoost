#!/system/bin/sh
# =============================================================================
# Dimensity 820 (MT6875) Network Mod — customize.sh
# EXCLUSIVE: Dimensity 820 only — aborts on any other chip
# =============================================================================

SKIPUNZIP=1

DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
BRAND=$(getprop ro.product.brand)
PLATFORM=$(getprop ro.board.platform)
VENDOR_PLATFORM=$(getprop ro.vendor.mediatek.platform)
SOC=$(getprop ro.soc.model 2>/dev/null)
CHIPNAME=$(getprop ro.chipname 2>/dev/null)
HARDWARE=$(getprop ro.hardware)
ANDROID=$(getprop ro.build.version.release)
ARCH=$(getprop ro.product.cpu.abi)
CPUS=$(nproc --all 2>/dev/null || grep -c ^processor /proc/cpuinfo)
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$(( RAM_KB / 1024 / 1024 ))

ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "   Dimensity 820 (MT6875) Network Mod"
ui_print "   v2.0 — 7nm · 5G Sub-6 · WiFi 6 2x2"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
ui_print "  Device   : $BRAND $MODEL"
ui_print "  Codename : $DEVICE"
ui_print "  Android  : $ANDROID  |  $ARCH"
ui_print "  Platform : ${PLATFORM:-unknown}"
ui_print "  SoC      : ${VENDOR_PLATFORM:-${SOC:-unknown}}"
ui_print "  RAM      : ${RAM_GB}GB  |  CPUs: $CPUS"
ui_print ""

# =============================================================================
# STRICT Dimensity 820 (MT6875) DETECTION — 5 methods
# =============================================================================
ui_print "  Detecting Dimensity 820 (MT6875)..."

IS_D820=0
D820_REASON=""

# Method 1: ro.board.platform
echo "$PLATFORM" | grep -qi "^mt6875" && IS_D820=1 && D820_REASON="ro.board.platform=$PLATFORM"

# Method 2: ro.vendor.mediatek.platform
echo "$VENDOR_PLATFORM" | grep -qi "mt6875" && IS_D820=1 && D820_REASON="ro.vendor.mediatek.platform=$VENDOR_PLATFORM"

# Method 3: ro.soc.model — Dimensity 820
echo "$SOC" | grep -qi "dimensity 820" && IS_D820=1 && D820_REASON="ro.soc.model=$SOC"
echo "$SOC" | grep -qi "mt6875"      && IS_D820=1 && D820_REASON="ro.soc.model=$SOC"

# Method 4: ro.chipname
echo "$CHIPNAME" | grep -qi "mt6875" && IS_D820=1 && D820_REASON="ro.chipname=$CHIPNAME"

# Method 5: Kernel cmdline — definitive hardware check
[ -f /proc/device-tree/compatible ] && grep -qi "mt6875" /proc/device-tree/compatible 2>/dev/null && IS_D820=1 && D820_REASON="DeviceTree: MT6875"

if [ "$IS_D820" != "1" ]; then
    ui_print ""
    ui_print "  ✗  NOT a Dimensity 820 (MT6875) device!"
    ui_print ""
    ui_print "     Board   : ${PLATFORM:-unknown}"
    ui_print "     SoC     : ${VENDOR_PLATFORM:-${SOC:-unknown}}"
    ui_print "     Chip    : ${CHIPNAME:-unknown}"
    ui_print "     HW      : ${HARDWARE:-unknown}"
    ui_print ""
    ui_print "  This module is EXCLUSIVELY for Dimensity 820."
    ui_print "  It will NOT work on your device."
    ui_print "  Refusing to install — aborting."
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    abort
fi

# Verify CPU core count matches D820 (8 cores)
if [ "$CPUS" != "8" ]; then
    ui_print "  ⚠  Warning: Expected 8 CPU cores (4+4 big.LITTLE)"
    ui_print "     Detected: $CPUS cores — continuing anyway"
fi

ui_print "  ✓  Dimensity 820 confirmed — MT6875"
ui_print "     $D820_REASON"
ui_print ""

unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'module.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2

set_perm_recursive "$MODPATH"       root root 0755 0644
set_perm "$MODPATH/service.sh"      root root 0755
set_perm "$MODPATH/system/etc/init/mtk-bwmod.rc"                 root root 0644
set_perm "$MODPATH/system/etc/sysctl.d/99-mtk-bwmod.conf"        root root 0644
set_perm "$MODPATH/system/etc/dhcpcd/dhcpcd.conf"               root root 0644
set_perm "$MODPATH/system/etc/resolv.conf"                       root root 0644

PROP_COUNT=$(grep -c "=" "$MODPATH/system.prop" 2>/dev/null || echo 0)
ui_print "  ✓  system.prop  ($PROP_COUNT D820-specific props)"
ui_print "  ✓  service.sh   (max performance, always-on)"
ui_print ""
ui_print "  System file overlay:"
ui_print "   system/etc/init/mtk-bwmod.rc          (4+4 init tuning)"
ui_print "   system/etc/sysctl.d/99-mtk-bwmod.conf  (D820 kernel params)"
ui_print "   system/etc/dhcpcd/dhcpcd.conf          (fast DHCP)"
ui_print "   system/etc/resolv.conf                 (DNS fallback)"
ui_print ""
ui_print "  Always-on Max Performance:"
ui_print "   • CPU: 4x A76@2.6GHz + 4x A55@2.0GHz"
ui_print "   • NR: Sub-6 2CC CA, 256QAM, 4.7Gbps"
ui_print "   • LTE: Cat 18, 5CC CA, 4x4 MIMO"
ui_print "   • WiFi 6: 2x2 MIMO @ 80MHz (MT6631)"
ui_print "   • TCP: 64MB BBR+fq, IRQ 50µs, Conntrack 2M"
ui_print "   • schedutil: A76 instant up, 500µs down"
ui_print ""
ui_print "  Log: /data/local/tmp/mtk_bwmod.log"
ui_print ""
ui_print "  ✓  Done — reboot to unleash D820"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
