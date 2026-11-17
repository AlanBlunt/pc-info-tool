#!/usr/bin/env bash
#pcinfo.sh - PC Information Tool
#Displays CPU, RAM, storage, OS and network information
#Usage: ./pcinfo.sh [-a|--all] [-c|--cpu] [-m|--memory] [-s|--storage] [-o|--os] [-n|--network] [-h|--help]

# ---------- Colours (disabled if not a terminal) ----------
if [ -t 1 ]; then
    BOLD=$'\e[1m'; CYAN=$'\e[36m'; GREEN=$'\e[32m'; RESET=$'\e[0m'
else
    BOLD=""; CYAN=""; GREEN=""; RESET=""
fi

header() { printf '\n%s== %s ==%s\n' "$BOLD$CYAN" "$1" "$RESET"; }
row()    { printf ' %s%-18s%s %s\n' "$GREEN" "$1" "$RESET" "$2"; }
have()   { command -v "$1" >/dev/null 2>&1; }

# ---------- OS ----------
show_os() {
    header "Operating System"
    local name="Unknown"
    if [ -r /etc/os-release ]; then
        name=$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")
    elif have sw_vers; then
        name="$(sw_vers -productName) $(sw_vers -productVersion)"
    fi
    row "OS:"          "$name"
    row "Kernel:"      "$(uname -r)"
    row "Arch:"        "$(uname -m)"
    row "Hostname:"    "$(hostname 2>/dev/null || uname -n)"
    row "User:"        "${USER:-$(id -un)}"
    row "Shell:"       "${SHELL:-unknown}"
    if have uptime; then
        row "Uptime:" "$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\),.*/\1/')"
    fi
    row "Date:"        "$(date '+%Y-%m-%d %H:%M:%S %Z')"
}

# ---------- CPU ----------
show_cpu() {
    header "CPU"
    local model cores threads
    if [ -r /proc/cpuinfo ]; then
        model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')
        [ -z "$model" ] && model=$(grep -m1 -E 'Hardware|Model' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')
        threads=$(grep -c '^processor' /proc/cpuinfo)
        cores=$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket/{c=$2} /^Socket\(s\)/{s=$2} END{if(c&&s) print c*s}' | tr -d ' ')
    elif have sysctl; then
       model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
       cores=$(sysctl -n hw.physicalcpu 2>/dev/null)
       threads=$(sysctl -n hw.logicalcpu 2>/dev/null)
    fi
    row "Model:"    "${model:-Unknown}"
    row "Cores:"    "${cores:-?}"
    row "Threads:"  "${threads:-$(nproc 2>/dev/null || echo '?')}"

    if have lscpu; then
        local mhz
        mhz=$(lscpu | awk -F: '/CPU max MHz/{print $2}' | tr -d ' ' | cut -d. -f1)
        [ -z "$mhz" ] && mhz=$(lscpu | awk -F: '/CPU MHz/{print $2}' | tr -d ' ' | cut -d. -f1)
        [ -n "$mhz" ] && row "Max Speed:" "${mhz} MHz"
    fi

    if [ -r /proc/loadavg ]; then
        row "Load (1/5/15m):" "$(cut -d' ' -f1-3 /proc/loadavg)"
    fi

    #CPU usage sampled over 1 second from /proc/stat
    if [ -r /proc/stat ]; then
        local a b idle1 total1 idle2 total2 usage
        read -r -a a < <(grep '^cpu ' /proc/stat)
        idle1=$((a[4] + a[5])); total1=0
        for v in "${a[@]:1:8}"; do total1=$((total1 + v)); done
        sleep 1
        read -r -a b < <(grep '^cpu ' /proc/stat)
        idle2=$((b[4] + b[5])); total2=0
        for v in "${b[@]:1:8}"; do total2=$((total2 + v)); done
        local dt=$((total2 - total1)) di=$((idle2 - idle1))
        [ "$dt" -gt 0 ] && usage=$(( (100 * (dt - di)) / dt )) || usage=0
        row "Usage:" "${usage}%"
    fi

    #Temperature if available
    if have sensors; then
        local temp 
        temp=$(sensors 2>/dev/null | grep -m1 -E 'Package id 0|Tctl|CPU' | grep -oE '[+-]?[0-9]+\.[0-9]+°C' | head -1)
        [ -n "$temp" ] && row "Temperature:" "$temp"
    fi
}

#---------- Memory ----------
show_memory() {
    header "Memory (RAM)"
    if have free; then
        local total used free_m avail swap_t swap_u
        read -r _ total used free_m _ _ avail < <(free -m | awk '/^Mem:/')
        row "Total:"    "${total} MB"
        row "Used:"     "${used} MB ($(( total > 0 ? used * 100 / total : 0 ))%)"
        row "Free:"     "${free_m} MB"
        row "Available:" "${avail} MB"
        read -r _ swap_t swap_u _ < <(free -m | awk '/^Swap:/')
        row "Swap:"     "${swap_u:-0}  / ${swap_t:-0} MB"
    elif have sysctl; then
        local bytes 
        bytes=$(sysctl -n hw.memsize 2>/dev/null)
        [ -n "$bytes" ] && row "Total:" "$((bytes / 1024 / 1024)) MB"
    else
        row "Info:" "Unavailable"
    fi
}

# ---------- Storage ----------
show_storage() {
    header "Storage"
    printf ' %s%-22s %7s %7s %7s %5s %s%s\n' "$GREEN" "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted on" "$RESET"
    df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | tail -n +2 \
        | awk '{printf " %-22s %7s %7s %7s %5s %s\n", $1, $2, $3, $4, $5, $6}'
    #Fallback if df doesn't support -x (e.g macOS)
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        df -h | tail -n +2 | awk '{printf " %-22s %7s %7s %7s %5s %s\n", $1, $2, $3, $4, $5, $NF}'
    fi

    if have lsblk; then 
        printf '\n %sPhysical disks:%s\n' "$GREEN" "$RESET"
        lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null | grep -v loop | sed 's/^/  /'
    fi
}

# ---------- Network ----------
show_network() {
    header "Network"
    row "Hostname:" "$(hostname 2>/dev/null)"

    if have ip; then
        printf '\n %sInterfaces:%s\n' "$GREEN" "$RESET"
        ip -o -4 addr show 2>/dev/null | awk '{printf "%-12s %s\n", $2, $4}'
        local v6
        v6=$(ip -o -6 addr show scope global 2>/dev/null | awk '{printf "  %-12s %s\n", $2, $4}')
        [ -n "$v6" ] && printf '%s\n' "$v6"

        local gw
        gw=$(ip route 2>/dev/null | awk '/^default/{print $3; exit}')
        [ -n "$gw" ] && { echo; row "Default Gateway:" "$gw"; }

        local mac
                mac=$(ip -o link 2>/dev/null | awk '$2 != "lo:" {gsub(":$","",$2); for(i=1;i<=NF;i++) if($i=="link/ether") {print $2": "$(i+1); exit}}')
        [ -n "$mac" ] && row "MAC:" "$mac"
    elif have ifconfig; then
        ifconfig 2>/dev/null | grep -E '^[a-z]|inet ' | sed 's/^/   /' 
    fi

    #DNS servers
    if [ -r /etc/resolv.conf ]; then
        row "DNS:" "$(awk '/^nameserver/{printf "%s ", $2}' /etc/resolv.conf)"
    fi

    #Public IP (short timeout, optional)
    if have curl; then
        local pub
        pub=$(curl -s --max-time 3 https://ifconfig.me 2>/dev/null)
        row "Public IP:" "${pub:-Unavailable (offline?)}"
    fi
}

# ----------Help ----------
usage() {
    cat <<EOF
PC Information Tool

Usage: $(basename "$0") [options]

Options:
  -a, --all      Show everything (default)
  -o, --os       Operating system info
  -c, --cpu      CPU info
  -m, --memory   RAM info
  -s, --storage  Storage info
  -n, --network  Network info
  -h,  --help    Show this help
EOF
}

# ---------- Main ----------
main() {
    if [ $# -eq 0 ]; then set -- --all; fi
    printf '%s PC INFORMATION TOOL %s\n' "$BOLD" "$RESET"
    for arg in "$@"; do
        case "$arg" in 
            -a|--all) show_os; show_cpu; show_memory; show_storage; show_network ;;
            -o|--os) show_os ;;
            -c|--cpu) show_cpu ;;
            -m|--memory) show_memory ;;
            -s|--storage) show_storage ;;
            -n|--network) show_network ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
        esac
    done
    echo
}

main "$@"
