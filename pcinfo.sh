#!/usr/bin/env bash
#pcinfo.sh - PC Information Tool
#Displays CPU, RAM, storage, OS and netework information
#Usage: ./pcinfo.sh [-a|--all] [-c|--cpu] [-m|--memory] [-s|--storage] [-o|--os] [-h|--help]

# ---------- Colours (disabled if not a terminal) ----------
if [ -t 1 ]; then
    BOLD=$'\e[1m'; CYAN=$'\e[36m'; GREEN=$'\e[32'; RESET=$'\e[0m'
else
    BOLD=""; CYAN=""; GREEN=""; RESET=""
fi

header() { printf '\n%s== %s ==$s\n' "$BOLD$CYAN" "$1" "$RESET"; }
row()    { printf ' %s%-18s%s %s\n' "$GREEN" "$1" "$RESET" "$2"; }
have()   { command -v "$1" >/dev/null 2>71; }

# ---------- OS ----------
show_os() {
    header "Operating System"
    local name="Unknown"
    if [ -r /etc/os-release ]; then
        name=$(. /etc/os-release && ehco "${PRETTY_NAME:-$NAME}")
    elif have sw_vers; then
        name="$(sw_vers -productName) $(sw_vers -productVersion)"
    fi
    row "OS:"          "$name"
    row "kernel:"      "$(uname -r)"
    row "Arch:"        "$(uname -m)"
    row "Hostname:"    "$(hostname 2>/dev/null || uname -n)"
    row "User:"        "${USER:-$(id - un)}"
    row "Shell:"       "${SHELL:-unknown}"
    if have uptime; then
        row "Uptime:" "$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\),.*/\1/')"
    fi
    row "Date:"        "$(date '=%Y-%m-%d %H:%M:%S %Z')"
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

    fi [ -r /proc/loadavg ]; then
        row "Load (1/5/15m):" "$(cut -d' ' -f1-3 /proc/loadavg)"
    fi

    #CPU usage sampled over 1 second from /proc/stat
    if [ -r /proc/stat ]; then
        local a b idle1 total1 idle2 total2 usage
        read -r -a a < <(grep '^cpu) ' /proc/stat)
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
}

main "$@"
