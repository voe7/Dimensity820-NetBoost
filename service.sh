#!/system/bin/sh
# =============================================================================
# Dimensity 820 (MT6875) Network Mod v2.0 — service.sh
# EXCLUSIVE: Dimensity 820 · 4x A76 + 4x A55 · 7nm · MT6631
# Runs via Magisk late_start after boot_completed
# 27 sections optimized for MT6875 architecture
# =============================================================================

LOG="/data/local/tmp/mtk_bwmod.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

SOC="MT6875 (Dimensity 820)"
CPUS=8
BIG_MASK="f0"   # CPU 4-7: 4x Cortex-A76
LIT_MASK="0f"   # CPU 0-3: 4x Cortex-A55
HALF=4           # Big cores start at cpu4

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 6

log "================================================"
log " DIMENSITY 820 (MT6875) NETWORK MOD v2.0"
log " SoC: ${SOC}  |  CPUs: 8 (4+4)  |  7nm TSMC"
log " Big: 4x A76@2.6GHz (f0)  Little: 4x A55@2.0GHz (0f)"
log "================================================"

# =============================================================================
# 1. RADIO / RIL PROPS — re-applied after modem init
# =============================================================================
setprop persist.vendor.radio.nr.enabled 1
setprop persist.vendor.radio.force_nr true
setprop persist.vendor.radio.nr_sa_mode 1
setprop persist.vendor.radio.nr_nsa_mode 1
setprop persist.vendor.radio.endc_enabled 1
setprop persist.vendor.radio.lte_ul_ca 1
setprop persist.vendor.radio.lte_dl_ca 1
setprop persist.vendor.radio.lte_mimo_mode 2
setprop persist.vendor.radio.nr_256qam 1
setprop persist.vendor.radio.lte_256qam 1
setprop persist.vendor.radio.force_lte_ca true
setprop persist.vendor.radio.lte.lteca.cap 2
setprop persist.vendor.radio.smart.data.switch 1
setprop persist.vendor.radio.nr_endc_support 1
setprop persist.vendor.radio.mtk_nr_support 1
setprop persist.vendor.radio.psm.disabled 1
setprop persist.vendor.radio.network.always_connected 1
log "[1] Radio + NR (Sub-6 only) props applied"

# =============================================================================
# 2. IMS / VoLTE / VoNR / WFC
# =============================================================================
setprop persist.vendor.ims_support 1
setprop persist.vendor.mtk_ims_support 1
setprop persist.vendor.volte_support 1
setprop persist.vendor.mtk_volte_support 1
setprop persist.vendor.wfc_support 1
setprop persist.vendor.mtk_wfc_support 1
setprop persist.vendor.vilte_support 1
setprop persist.vendor.radio.volte_enabled 1
setprop persist.vendor.radio.vonr_enabled 1
setprop persist.dbg.volte_avail_ovr 1
setprop persist.dbg.ims_volte_enable 1
log "[2] IMS/VoLTE/VoNR/WFC applied"

# =============================================================================
# 3. TCP KERNEL TUNING — BBR + 64MB buffers for NR 4.7Gbps
# =============================================================================
sysctl -w net.ipv4.tcp_window_scaling=1              2>/dev/null
sysctl -w net.core.rmem_max=67108864                 2>/dev/null
sysctl -w net.core.wmem_max=67108864                 2>/dev/null
sysctl -w net.core.rmem_default=4194304              2>/dev/null
sysctl -w net.core.wmem_default=4194304              2>/dev/null
sysctl -w net.ipv4.tcp_rmem="4096 1048576 67108864"  2>/dev/null
sysctl -w net.ipv4.tcp_wmem="4096 1048576 67108864"  2>/dev/null
sysctl -w net.ipv4.tcp_notsent_lowat=131072          2>/dev/null
sysctl -w net.ipv4.tcp_retries2=8                   2>/dev/null
sysctl -w net.ipv4.tcp_syn_retries=3                2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_time=30            2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_intvl=10           2>/dev/null
sysctl -w net.ipv4.tcp_keepalive_probes=3           2>/dev/null
sysctl -w net.ipv4.tcp_fastopen=3                   2>/dev/null
sysctl -w net.ipv4.tcp_no_metrics_save=1            2>/dev/null
sysctl -w net.ipv4.tcp_timestamps=1                 2>/dev/null
sysctl -w net.ipv4.tcp_sack=1                       2>/dev/null
sysctl -w net.ipv4.tcp_fack=1                       2>/dev/null
sysctl -w net.ipv4.tcp_mtu_probing=1                2>/dev/null
sysctl -w net.ipv4.tcp_slow_start_after_idle=0      2>/dev/null
sysctl -w net.ipv4.tcp_fin_timeout=15               2>/dev/null
sysctl -w net.ipv4.ip_local_port_range="1024 65535" 2>/dev/null
sysctl -w net.core.netdev_max_backlog=16384          2>/dev/null
sysctl -w net.core.somaxconn=8192                   2>/dev/null
sysctl -w net.ipv4.tcp_congestion_control=bbr       2>/dev/null \
  || sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
log "[3] TCP tuning applied (cc=${CC}, 64MB buffers)"

# =============================================================================
# 4. UDP / QUIC BUFFERS
# =============================================================================
sysctl -w net.ipv4.udp_rmem_min=65536            2>/dev/null
sysctl -w net.ipv4.udp_wmem_min=65536            2>/dev/null
sysctl -w net.ipv4.udp_mem="65536 131072 262144" 2>/dev/null
log "[4] UDP/QUIC buffers applied"

# =============================================================================
# 5. WIFI RUNTIME PROPS — MT6631, 2x2 MIMO, 80MHz
# =============================================================================
setprop persist.sys.wifi.power_save false
setprop wifi.ps.mode 0
setprop persist.wifi.powersave 0
setprop wifi.5ghz.preferred 1
setprop persist.vendor.wifi.band_steering 1
setprop persist.vendor.wifi.vht80.enable true
setprop persist.vendor.wifi.roaming_trigger -75
setprop persist.vendor.wifi.connac2 1
log "[5] WiFi runtime (MT6631, 2x2, 80MHz) applied"

# =============================================================================
# 6. DNS OVERRIDE — all active interfaces
# =============================================================================
setprop net.dns1 1.1.1.1
setprop net.dns2 1.0.0.1
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy"); do
  setprop "net.${IF}.dns1" 1.1.1.1 2>/dev/null
  setprop "net.${IF}.dns2" 1.0.0.1 2>/dev/null
done
log "[6] DNS 1.1.1.1 applied on all interfaces"

# =============================================================================
# 7. NETWORK IRQ AFFINITY — MT6875-specific interrupt names
#     Pin to big A76 cluster (cpu4-7 mask=f0) for low latency
# =============================================================================
BOUND=0
for irq_dir in /proc/irq/*/; do
  name=$(cat "${irq_dir}actions" 2>/dev/null)
  case "$name" in
    # MT6875 modem interrupts
    *mtk_md1*|*md1_*|*ccci_md*|*ccci*|\
    # MT6875 CCCI data path
    *ccmni*|*rmnet*|*rmnet_data*|\
    # MT6631 WiFi/BT combo chip
    *wlan*|*wifi*|*WIFI*|*WCN*|*mt6631*|\
    # MTK ConnSys
    *connsys*|*mt76*|*mtk_*net*|\
    # Modem wake
    *modem*)
      echo "$BIG_MASK" > "${irq_dir}smp_affinity" 2>/dev/null \
        && BOUND=$((BOUND+1))
      ;;
  esac
done
log "[7] IRQ affinity: ${BOUND} network IRQs → A76 cluster (0x${BIG_MASK})"

# =============================================================================
# 8. DATA STALL RECOVERY PROPS
# =============================================================================
setprop persist.data.stall.recovery.action 2
setprop persist.vendor.radio.keepalive 1
setprop persist.vendor.radio.data_keepalive 1
setprop persist.vendor.radio.psm.disabled 1
log "[8] Data stall recovery applied"

# =============================================================================
# 9. NETWORK INTERFACE TXQUEUELEN + RPS
# =============================================================================
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy"); do
  ip link set "$IF" txqueuelen 3000 2>/dev/null
done
for RMNET in /sys/class/net/rmnet*/; do
  [ -f "${RMNET}queues/rx-0/rps_cpus" ] && \
    echo "$BIG_MASK" > "${RMNET}queues/rx-0/rps_cpus" 2>/dev/null
done
log "[9] txqueuelen=3000 + RPS (A76 cluster) applied"

# =============================================================================
# 10. UNLOCK HIDDEN NETWORK FEATURES IN SETTINGS UI
# =============================================================================
setprop persist.vendor.radio.nr.setting.support 1
setprop persist.vendor.radio.show_nr_switch 1
setprop persist.radio.nr.setting 1
setprop persist.vendor.radio.volte_setting_support 1
setprop persist.vendor.radio.show_volte_setting 1
setprop persist.dbg.volte_avail_ovr 1
setprop persist.dbg.ims_volte_enable 1
setprop persist.vendor.radio.wfc_setting_support 1
setprop persist.vendor.radio.show_wfc_setting 1
setprop persist.dbg.wfc_avail_ovr 1
setprop persist.dbg.vt_avail_ovr 1
setprop persist.vendor.radio.show_vilte_setting 1
setprop persist.vendor.radio.force_network_mode 1
setprop persist.vendor.radio.show_network_mode 1
setprop persist.vendor.radio.apn_unlock 1
setprop persist.vendor.radio.show_apn_setting 1
setprop persist.radio.show_signal_dbm 1
setprop persist.vendor.radio.show_signal_detail 1
setprop persist.sys.miui.volte_available 1
setprop persist.sys.miui.wfc_available 1
setprop persist.sys.miui.nr_available 1
setprop persist.sys.miui.show_volte_icon 1
setprop persist.sys.miui.show_nr_icon 1
setprop persist.sys.miui.show_wfc_icon 1
log "[10] Settings UI: 5G/VoLTE/WFC/ViLTE/APN unlocked"

# =============================================================================
# 11. CCCI + ANTENNA + CA + CONNAC (MT6631)
# =============================================================================
setprop persist.vendor.radio.ccci_ready 1
setprop persist.vendor.radio.ccci_bypass_fsd 1
setprop persist.vendor.radio.ant_switch 1
setprop persist.vendor.radio.ant_diversity 1
setprop persist.vendor.radio.lte_rx_diversity 1
setprop persist.vendor.radio.nr_rx_diversity 1
setprop persist.vendor.radio.lte_dl_4rx 1
setprop persist.vendor.radio.nr_dl_4rx 1
setprop persist.vendor.radio.lte_ca_max_component 5
setprop persist.vendor.radio.nr_ca_max_component 2
setprop persist.vendor.radio.nr_intra_band_ca 1
setprop persist.vendor.radio.nr_inter_band_ca 1
# MT6631 WiFi chip (connac2 only)
setprop persist.vendor.wifi.connac2 1
setprop persist.vendor.mtk.wifi.ampdu_tx 1
setprop persist.vendor.mtk.wifi.ampdu_rx 1
setprop persist.vendor.mtk.wifi.amsdu_tx 1
setprop persist.vendor.mtk.wifi.amsdu_rx 1
setprop persist.vendor.mtk.wifi.tx_power_boost 1
setprop persist.vendor.mtk.wifi.he_dl_ofdma 1
setprop persist.vendor.mtk.wifi.he_ul_ofdma 1
log "[11] CCCI + 4RX Antenna + 5CC LTE + ConnAC2(MT6631) applied"

# =============================================================================
# 12. SIGNAL + NETWORK SEARCH + MODEM POWER (7nm)
# =============================================================================
setprop persist.vendor.radio.afc.enable 1
setprop persist.vendor.radio.ulfd.enable 1
setprop persist.vendor.radio.lte_ul_mcs_boost 1
setprop persist.vendor.radio.nr_ul_mcs_boost 1
setprop persist.vendor.radio.lte_ul_rank 2
setprop persist.vendor.radio.nr_ul_rank 2
setprop persist.vendor.radio.fast_camp_enable 1
setprop persist.vendor.radio.rat_priority nr,lte,wcdma,gsm
setprop persist.vendor.radio.md_fast_wakeup 1
setprop persist.vendor.radio.md_sleep_threshold -100
setprop persist.vendor.radio.data_throttle 0
setprop persist.vendor.radio.slice_support 1
setprop persist.vendor.radio.ursp_enable 1
setprop persist.vendor.radio.srvcc_enable 1
log "[12] Signal + Network search + 7nm modem power applied"

# =============================================================================
# 13. WiFi AP QoS — WMM/BA/ADDTS/BF/802.11k/v/r (MT6631)
# =============================================================================
setprop persist.vendor.mtk.wifi.wmm_ac_vo 1
setprop persist.vendor.mtk.wifi.wmm_ac_vi 1
setprop persist.vendor.mtk.wifi.uapsd_enable 1
setprop persist.vendor.mtk.wifi.wmm_ps 1
setprop persist.vendor.mtk.wifi.ba_tx_size 64
setprop persist.vendor.mtk.wifi.ba_rx_size 64
setprop persist.vendor.mtk.wifi.ba_auto 1
setprop persist.vendor.mtk.wifi.addts_enable 1
setprop persist.vendor.mtk.wifi.ts_reclassify 1
setprop persist.vendor.mtk.wifi.su_bfee 1
setprop persist.vendor.mtk.wifi.mu_bfee 1
setprop persist.vendor.mtk.wifi.vht_bf_cap 1
setprop persist.vendor.mtk.wifi.he_bf_cap 1
setprop persist.vendor.mtk.wifi.bf_report_size 4
setprop persist.vendor.mtk.wifi.dot11k 1
setprop persist.vendor.mtk.wifi.dot11v 1
setprop persist.vendor.mtk.wifi.dot11r 1
setprop persist.vendor.mtk.wifi.rrm_enable 1
setprop persist.vendor.mtk.wifi.bss_transition 1
setprop persist.vendor.mtk.wifi.ft_over_ds 1
# MT6631 2x2 MIMO
setprop persist.vendor.mtk.wifi.nss_tx 2
setprop persist.vendor.mtk.wifi.nss_rx 2
setprop persist.vendor.mtk.wifi.max_ampdu_len 64
setprop persist.vendor.mtk.wifi.rate_control 1
setprop persist.vendor.mtk.wifi.ra_interval 100
log "[13] WiFi AP QoS: WMM/BA/BF/802.11kvr (MT6631 2x2)"

# =============================================================================
# 14. TC QDISC — fq for BBR (skip AP interfaces)
# =============================================================================
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  AP_MODE=$(iw dev "$IF" info 2>/dev/null | grep -c "type AP")
  [ "$AP_MODE" -gt "0" ] && continue
  tc qdisc del dev "$IF" root 2>/dev/null
  tc qdisc add dev "$IF" root fq         2>/dev/null \
    || tc qdisc add dev "$IF" root fq_codel 2>/dev/null \
    || tc qdisc add dev "$IF" root pfifo_fast 2>/dev/null
done
APPLIED=$(tc qdisc show 2>/dev/null | grep -cE "fq |fq_codel")
log "[14] tc qdisc → fq applied on ${APPLIED} interfaces"

# =============================================================================
# 15. HW OFFLOADING — GRO/GSO/TSO
# =============================================================================
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  ethtool -K "$IF" gro on  2>/dev/null
  ethtool -K "$IF" gso on  2>/dev/null
  ethtool -K "$IF" tso on  2>/dev/null
  ethtool -K "$IF" rx  on  2>/dev/null
  ethtool -K "$IF" tx  on  2>/dev/null
  for Q in /sys/class/net/${IF}/queues/rx-*/; do
    [ -f "${Q}rps_flow_cnt" ] && echo 512 > "${Q}rps_flow_cnt" 2>/dev/null
  done
done
sysctl -w net.core.gro_normal_batch=64 2>/dev/null
log "[15] HW offloading (GRO/GSO/TSO) applied"

# =============================================================================
# 16. XPS — TX steering to A76 cluster
# =============================================================================
XPS_BOUND=0
for IF in $(ls /sys/class/net/ 2>/dev/null \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  for TXQ in /sys/class/net/${IF}/queues/tx-*/; do
    [ -f "${TXQ}xps_cpus" ] || continue
    echo "$BIG_MASK" > "${TXQ}xps_cpus" 2>/dev/null \
      && XPS_BOUND=$((XPS_BOUND+1))
  done
done
log "[16] XPS → A76 cluster (0x${BIG_MASK}) on ${XPS_BOUND} TX queues"

# =============================================================================
# 17. NAPI / NETDEV BUDGET — 7nm can handle 600+ without thermal issues
# =============================================================================
sysctl -w net.core.netdev_budget=600          2>/dev/null
sysctl -w net.core.netdev_budget_usecs=4000   2>/dev/null
sysctl -w net.core.netdev_max_backlog=32768   2>/dev/null
log "[17] NAPI budget=600, backlog=32768 (7nm-optimized)"

# =============================================================================
# 18. SCHEDUTIL — A76 big cores instant response (7nm efficiency)
#     up_rate_limit=0 → react immediately to network load spikes
#     down_rate_limit=500 → hold clocks for 500µs before ramping down
# =============================================================================
SCHED_APPLIED=0
for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
  [ -f "${cpu_dir}scaling_governor" ] || continue
  GOV=$(cat "${cpu_dir}scaling_governor" 2>/dev/null)
  [ "$GOV" != "schedutil" ] && continue
  CPU_NUM=$(echo "$cpu_dir" | grep -o 'cpu[0-9]*' | grep -o '[0-9]*')
  [ "$CPU_NUM" -ge "$HALF" ] || continue
  echo 0   > "${cpu_dir}schedutil/up_rate_limit_us"   2>/dev/null
  echo 500 > "${cpu_dir}schedutil/down_rate_limit_us" 2>/dev/null
  SCHED_APPLIED=$((SCHED_APPLIED+1))
done
log "[18] schedutil up_rate_limit=0 on ${SCHED_APPLIED} A76 big cores"

# =============================================================================
# 19. RPS FLOW TABLE — distribute across 8 cores
# =============================================================================
sysctl -w net.core.rps_sock_flow_entries=32768 2>/dev/null
for IF in $(ls /sys/class/net/ 2>/dev/null \
    | grep -vE "^lo$|^dummy"); do
  for RXQ in /sys/class/net/${IF}/queues/rx-*/; do
    [ -f "${RXQ}rps_flow_cnt" ] && echo 512 > "${RXQ}rps_flow_cnt" 2>/dev/null
    [ -f "${RXQ}rps_cpus"     ] && echo "$BIG_MASK" > "${RXQ}rps_cpus" 2>/dev/null
  done
done
log "[19] RPS flow table=32768, per-queue cnt=512"

# =============================================================================
# 20. IRQ COALESCING — 50µs/32f (7nm A76 handles aggressive batching)
# =============================================================================
COAL_APPLIED=0
for IF in $(ip link show up 2>/dev/null \
    | awk -F': ' '/^[0-9]+/{gsub(/@.*/,"",$2); print $2}' \
    | grep -vE "^lo$|^dummy|^ip6tnl|^sit"); do
  ethtool -C "$IF" \
    rx-usecs 50 tx-usecs 50 \
    rx-frames 32 tx-frames 32 2>/dev/null \
    && COAL_APPLIED=$((COAL_APPLIED+1))
done
log "[20] IRQ coalescing rx-usecs=50/frames=32 on ${COAL_APPLIED} interfaces"

# =============================================================================
# 21. TCP OVERHEAD STRIP
# =============================================================================
sysctl -w net.ipv4.tcp_timestamps=0     2>/dev/null
sysctl -w net.ipv4.tcp_mtu_probing=2    2>/dev/null
sysctl -w net.ipv4.tcp_ecn=1           2>/dev/null
sysctl -w net.ipv4.tcp_ecn_fallback=1  2>/dev/null
log "[21] TCP overhead stripped (timestamps=0, mtu_probing=2, ECN)"

# =============================================================================
# 22. CONNTRACK SCALING — 2M entries for 5G multi-stream
# =============================================================================
CT_MAX=2000000
CT_HASH=$((CT_MAX / 8))

sysctl -w net.netfilter.nf_conntrack_max=$CT_MAX                2>/dev/null
sysctl -w net.netfilter.nf_conntrack_buckets=$CT_HASH           2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=600 2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_time_wait=30    2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_close_wait=15   2>/dev/null
sysctl -w net.netfilter.nf_conntrack_udp_timeout=30              2>/dev/null
sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=120      2>/dev/null
sysctl -w net.netfilter.nf_conntrack_tcp_loose=1                 2>/dev/null
ACTUAL=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null)
log "[22] Conntrack max=${ACTUAL}, hash=${CT_HASH}, EST=600s"

# =============================================================================
# 23. ROUTE METRIC — WiFi priority over NR/LTE
# =============================================================================
WIFI_GW=$(ip route show dev wlan0 2>/dev/null | grep default | awk '{print $3}' | head -1)
if [ -n "$WIFI_GW" ]; then
  ip route del default dev wlan0 2>/dev/null
  ip route add default via "$WIFI_GW" dev wlan0 metric 0 2>/dev/null
  for RMNET in rmnet_data0 rmnet_data1 rmnet_data2; do
    RMNET_GW=$(ip route show dev $RMNET 2>/dev/null | grep default | awk '{print $3}' | head -1)
    [ -z "$RMNET_GW" ] && continue
    ip route del default dev $RMNET 2>/dev/null
    ip route add default via "$RMNET_GW" dev $RMNET metric 200 2>/dev/null
  done
  log "[23] Route metric: wlan0=0 (primary), rmnet=200 (fallback)"
else
  for RMNET in rmnet_data0 rmnet_data1 rmnet_data2; do
    RMNET_GW=$(ip route show dev $RMNET 2>/dev/null | grep default | awk '{print $3}' | head -1)
    [ -z "$RMNET_GW" ] && continue
    ip route del default dev $RMNET 2>/dev/null
    ip route add default via "$RMNET_GW" dev $RMNET metric 0 2>/dev/null
  done
  log "[23] Route metric: rmnet=0 (NR/LTE primary, no WiFi)"
fi

# =============================================================================
# 24. DSCP MARKING — Traffic class for AP/router QoS
# =============================================================================
iptables -t mangle -F OUTPUT 2>/dev/null
ip6tables -t mangle -F OUTPUT 2>/dev/null

# EF (DSCP 46) — VoIP, DNS, QUIC
iptables -t mangle -A OUTPUT -p udp --dport 5060 -j DSCP --set-dscp 46 2>/dev/null
iptables -t mangle -A OUTPUT -p udp --dport 5061 -j DSCP --set-dscp 46 2>/dev/null
iptables -t mangle -A OUTPUT -p udp --dport 53   -j DSCP --set-dscp 46 2>/dev/null
iptables -t mangle -A OUTPUT -p tcp --dport 53   -j DSCP --set-dscp 46 2>/dev/null
iptables -t mangle -A OUTPUT -p udp --dport 443  -j DSCP --set-dscp 46 2>/dev/null
iptables -t mangle -A OUTPUT -p udp --dport 16384:32767 -j DSCP --set-dscp 46 2>/dev/null

# AF41 (DSCP 34) — HTTP/HTTPS
iptables -t mangle -A OUTPUT -p tcp --dport 80   -j DSCP --set-dscp 34 2>/dev/null
iptables -t mangle -A OUTPUT -p tcp --dport 443  -j DSCP --set-dscp 34 2>/dev/null
iptables -t mangle -A OUTPUT -p tcp --dport 8080 -j DSCP --set-dscp 34 2>/dev/null
iptables -t mangle -A OUTPUT -p tcp --dport 8443 -j DSCP --set-dscp 34 2>/dev/null

# IPv6
ip6tables -t mangle -A OUTPUT -p udp --dport 53   -j DSCP --set-dscp 46 2>/dev/null
ip6tables -t mangle -A OUTPUT -p udp --dport 443  -j DSCP --set-dscp 46 2>/dev/null
ip6tables -t mangle -A OUTPUT -p tcp --dport 80   -j DSCP --set-dscp 34 2>/dev/null
ip6tables -t mangle -A OUTPUT -p tcp --dport 443  -j DSCP --set-dscp 34 2>/dev/null

log "[24] DSCP marking: VoIP/DNS/QUIC=EF(46), HTTP/S=AF41(34)"

# =============================================================================
# 25. WPA_CLI — Force AP negotiation (MT6631)
# =============================================================================
WPA_OK=0
for WPA_IFACE in wlan0 wlan1; do
  wpa_cli -i "$WPA_IFACE" status 2>/dev/null | grep -q "wpa_state=COMPLETED" || continue
  wpa_cli -i "$WPA_IFACE" rrm_neighbor_rep_request 2>/dev/null
  BSSID=$(wpa_cli -i "$WPA_IFACE" status 2>/dev/null | grep "^bssid=" | cut -d= -f2)
  [ -n "$BSSID" ] && wpa_cli -i "$WPA_IFACE" bssid 0 "$BSSID" 2>/dev/null
  wpa_cli -i "$WPA_IFACE" set prefer_5ghz 1 2>/dev/null
  wpa_cli -i "$WPA_IFACE" set ampdu 1 2>/dev/null
  wpa_cli -i "$WPA_IFACE" set roam_rssi_threshold -75 2>/dev/null
  wpa_cli -i "$WPA_IFACE" set roam_scan_threshold -70 2>/dev/null
  wpa_cli -i "$WPA_IFACE" reassociate 2>/dev/null
  WPA_OK=$((WPA_OK+1))
  log "[25] wpa_cli negotiation on $WPA_IFACE: BSSID=$BSSID"
done
[ "$WPA_OK" -eq 0 ] && log "[25] wpa_cli: no active connection"

# =============================================================================
# 26. iw — Kernel WiFi driver params (MT6631)
# =============================================================================
for WIF in wlan0 wlan1; do
  ip link show "$WIF" up 2>/dev/null | grep -q UP || continue
  iw dev "$WIF" set power_save off 2>/dev/null
  iw dev "$WIF" set channel 0 2>/dev/null
  iw dev "$WIF" set txq limit 65536 2>/dev/null
  iw dev "$WIF" set txq memory_limit 33554432 2>/dev/null
  iw dev "$WIF" set txq quantum 3028 2>/dev/null
  iw dev "$WIF" set retry short 7 long 4 2>/dev/null
  iw dev "$WIF" set rts 2347 2>/dev/null
  log "[26] iw: txq=65536, power_save=off, retry=7/4 on $WIF"
done

# =============================================================================
# 27. NR/LTE DATA PATH — MT6875 PDN + QoS flow negotiation
# =============================================================================
setprop persist.vendor.radio.data_pref 1             2>/dev/null
setprop persist.vendor.radio.data_con_rgs 1          2>/dev/null
setprop persist.vendor.radio.smart.data.switch 1     2>/dev/null
setprop persist.vendor.radio.imsi_from_sim 1         2>/dev/null
setprop persist.vendor.radio.enhanced_4g_lte_mode 1 2>/dev/null

# Trigger MT6875 RIL PDN rebuild with best QoS class
setprop vendor.ril.mtk.pdn.rebuild 1                 2>/dev/null
setprop persist.vendor.radio.pdn.policy 1            2>/dev/null
setprop persist.vendor.radio.throttle.disable 1      2>/dev/null

# D820 NR QoS flow — reflective QoS + foreground QoS
setprop persist.vendor.radio.nr_qos_flow 1           2>/dev/null
setprop persist.vendor.radio.nr_reflective_qos 1     2>/dev/null
setprop persist.vendor.radio.nr_fgqos_enable 1       2>/dev/null

# LTE UL enhancement
setprop persist.vendor.radio.lte_ul_power_headroom 3 2>/dev/null
setprop persist.vendor.radio.afc_enable 1            2>/dev/null
setprop persist.vendor.radio.ulfd_enable 1           2>/dev/null

log "[27] MT6875 PDN rebuild + NR reflective QoS + UL headroom applied"

# =============================================================================
# DONE
# =============================================================================
log "-----------------------------------------------"
log " Dimensity 820 (MT6875) — all 27 sections · MAX PERFORMANCE"
log "==============================================="
