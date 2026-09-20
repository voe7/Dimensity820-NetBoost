#!/system/bin/sh
# =============================================================================
# Dimensity 820 (MT6875) Network Mod v2.0 — post-fs-data.sh
# EXCLUSIVE: Dimensity 820 · System file patcher
# Runs before Android fully boots — patches WiFi, IMS, DHCP, DNS configs
# =============================================================================

LOG="/data/local/tmp/mtk_bwmod_postfs.log"
STAMP=$(date '+%H:%M:%S')
log() { echo "[$STAMP] [POST-FS] $*" >> "$LOG"; }
found() { log "  FOUND : $1"; }
skip()  { log "  SKIP  : $1 (not found)"; }
patch() { log "  PATCH : $1"; }

log "========================================"
log " D820 BWMOD v2.0 — post-fs-data patcher"
log "========================================"

# ── HELPER: append if line not already present ────────────────────────────────
append_if_missing() {
    FILE="$1"; LINE="$2"
    grep -qF "$LINE" "$FILE" 2>/dev/null || echo "$LINE" >> "$FILE"
}

# ── HELPER: sed replace or append ────────────────────────────────────────────
set_or_append() {
    FILE="$1"; KEY="$2"; VAL="$3"
    if grep -qE "^${KEY}[[:space:]]*=" "$FILE" 2>/dev/null; then
        sed -i "s|^${KEY}[[:space:]]*=.*|${KEY}=${VAL}|" "$FILE"
    else
        echo "${KEY}=${VAL}" >> "$FILE"
    fi
}

# =============================================================================
# 1. WPA_SUPPLICANT.CONF — WiFi scan, roaming, fast re-auth (MT6631)
# =============================================================================
log "[1] wpa_supplicant.conf"
WPA_PATCHED=0
for WPA in \
    /vendor/etc/wifi/wpa_supplicant.conf \
    /system/etc/wifi/wpa_supplicant.conf \
    /data/vendor/wifi/wpa_supplicant.conf; do
    [ -f "$WPA" ] || continue
    found "$WPA"
    cp "$WPA" "${WPA}.bwmod_bak" 2>/dev/null
    append_if_missing "$WPA" "fast_reauth=1"
    append_if_missing "$WPA" "scan_interval=15"
    append_if_missing "$WPA" "bgscan="
    append_if_missing "$WPA" "disable_scan_offload=1"
    append_if_missing "$WPA" "max_num_sta=10"
    append_if_missing "$WPA" "rrm=1"
    append_if_missing "$WPA" "pmf=1"
    patch "$WPA"
    WPA_PATCHED=$((WPA_PATCHED+1))
done
[ "$WPA_PATCHED" = "0" ] && skip "wpa_supplicant.conf"

# =============================================================================
# 2. P2P_SUPPLICANT.CONF — WiFi Direct
# =============================================================================
log "[2] p2p_supplicant.conf"
for P2P in \
    /vendor/etc/wifi/p2p_supplicant.conf \
    /system/etc/wifi/p2p_supplicant.conf; do
    [ -f "$P2P" ] || continue
    found "$P2P"
    append_if_missing "$P2P" "fast_reauth=1"
    append_if_missing "$P2P" "p2p_search_delay=0"
    patch "$P2P"
done

# =============================================================================
# 3. MTK WIFI.CFG — MT6631 ConnAC chip settings
# =============================================================================
log "[3] MTK wifi.cfg (MT6631)"
WIFI_CFG_PATCHED=0
for WCFG in \
    /vendor/etc/wifi/wifi.cfg \
    /vendor/etc/wifi/mt_wifi.cfg \
    /vendor/etc/wifi/mt6631.cfg \
    /system/etc/wifi/wifi.cfg \
    /system/etc/firmware/wifi.cfg; do
    [ -f "$WCFG" ] || continue
    found "$WCFG"
    cp "$WCFG" "${WCFG}.bwmod_bak" 2>/dev/null
    # Power save off
    set_or_append "$WCFG" "STA_POWER_SAVE"         "0"
    set_or_append "$WCFG" "STR_POWER_MODE"          "0"
    # Dual band
    set_or_append "$WCFG" "BAND"                    "3"
    set_or_append "$WCFG" "BANDWIDTH_5G"            "1"
    set_or_append "$WCFG" "BANDWIDTH_2G"            "1"
    # 802.11k/v/r
    set_or_append "$WCFG" "WIFI_80211K_SUPPORT"     "1"
    set_or_append "$WCFG" "WIFI_80211V_SUPPORT"     "1"
    set_or_append "$WCFG" "WIFI_80211R_SUPPORT"     "1"
    # AMPDU/AMSDU aggregation
    set_or_append "$WCFG" "AMPDU_TX"                "1"
    set_or_append "$WCFG" "AMPDU_RX"                "1"
    set_or_append "$WCFG" "AMSDU_TX"                "1"
    set_or_append "$WCFG" "AMSDU_RX"                "1"
    # Beamforming (MT6631 supports SU/MU BFEE)
    set_or_append "$WCFG" "SU_BFEE"                 "1"
    set_or_append "$WCFG" "MU_BFEE"                 "1"
    # OFDMA (WiFi 6 — MT6631 HE capable)
    set_or_append "$WCFG" "HE_DL_OFDMA"             "1"
    set_or_append "$WCFG" "HE_UL_OFDMA"             "1"
    # 2x2 MIMO
    set_or_append "$WCFG" "TX_STBC_2X2"             "1"
    set_or_append "$WCFG" "RX_STBC_2X2"             "1"
    # BT Coex
    set_or_append "$WCFG" "COEX_PRIORITY"           "coexist"
    set_or_append "$WCFG" "BT_COEX_MODE"            "1"
    patch "$WCFG"
    WIFI_CFG_PATCHED=$((WIFI_CFG_PATCHED+1))
done
[ "$WIFI_CFG_PATCHED" = "0" ] && skip "wifi.cfg (MT6631 config not found)"

# =============================================================================
# 4. MTK CONNSYS RC — Log presence only (no modification)
# =============================================================================
log "[4] ConnSys init scripts"
for CCONN in \
    /vendor/etc/init/android.hardware.wifi@1.0-service-mediatek.rc \
    /vendor/etc/init/connsys.rc \
    /vendor/etc/init/connectivity.rc \
    /system/etc/init/connsys.rc; do
    [ -f "$CCONN" ] || continue
    found "$CCONN"
    log "  NOTE: ConnSys RC at $CCONN — logged only (structure-sensitive)"
done

# =============================================================================
# 5. MTK TELEPHONY / IMS XML CONFIG — MT6875
# =============================================================================
log "[5] Telephony / IMS XML configs"
IMS_PATCHED=0
for IMSXML in \
    /vendor/etc/mddb/mims_config.xml \
    /vendor/etc/telephony/MtkImsConfiguration.xml \
    /vendor/etc/telephony/mims_cfg.xml \
    /system/etc/telephony/carrier_config.xml \
    /vendor/etc/mddb/ImsConfig.xml; do
    [ -f "$IMSXML" ] || continue
    found "$IMSXML"
    cp "$IMSXML" "${IMSXML}.bwmod_bak" 2>/dev/null
    # Enable VoLTE / VoNR / WFC
    sed -i 's/volte_enabled.*false/volte_enabled">true/g' "$IMSXML" 2>/dev/null
    sed -i 's/vonr_enabled.*false/vonr_enabled">true/g'   "$IMSXML" 2>/dev/null
    sed -i 's/wfc_enabled.*false/wfc_enabled">true/g'     "$IMSXML" 2>/dev/null
    patch "$IMSXML"
    IMS_PATCHED=$((IMS_PATCHED+1))
done
[ "$IMS_PATCHED" = "0" ] && skip "IMS XML (ROM-specific)"

# =============================================================================
# 6. DHCPCD CONFIG — patch runtime dhcpcd configs
# =============================================================================
log "[6] dhcpcd config"
for DHCP in \
    /system/etc/dhcpcd/dhcpcd.conf \
    /vendor/etc/dhcpcd.conf \
    /system/etc/dhcpcd.conf; do
    [ -f "$DHCP" ] || continue
    found "$DHCP"
    cp "$DHCP" "${DHCP}.bwmod_bak" 2>/dev/null
    append_if_missing "$DHCP" "timeout 10"
    append_if_missing "$DHCP" "reboot 5"
    append_if_missing "$DHCP" "static domain_name_servers=1.1.1.1 1.0.0.1"
    append_if_missing "$DHCP" "nohook lookup-hostname"
    patch "$DHCP"
done

# =============================================================================
# 7. RESOLV.CONF — DNS resolver fallback
# =============================================================================
log "[7] resolv.conf"
for RCONF in \
    /system/etc/resolv.conf \
    /vendor/etc/resolv.conf; do
    [ -f "$RCONF" ] || continue
    found "$RCONF"
    cat > "${RCONF}" << 'RESOLV'
nameserver 1.1.1.1
nameserver 1.0.0.1
options attempts:1
options timeout:2
options rotate
RESOLV
    patch "$RCONF"
done

# =============================================================================
# 8. SYSCTL EARLY APPLY
# =============================================================================
log "[8] Early sysctl apply (pre-boot)"
sysctl -p /system/etc/sysctl.d/99-mtk-bwmod.conf 2>/dev/null \
  && log "  sysctl.d applied early via post-fs-data" \
  || log "  sysctl.d apply failed (normal — kernel may not be ready)"

# =============================================================================
# DONE
# =============================================================================
log "----------------------------------------"
log " D820 post-fs-data patcher complete"
log "========================================"
