# PC Info Tool
 
A simple Bash script that displays CPU, RAM, storage, OS and network information for your machine.
 
## Features
 
- **OS**: distro, kernel, architecture, hostname, user, shell, uptime
- **CPU**: model, cores/threads, max speed, load average, live usage, temperature (if `lm-sensors` is installed)
- **Memory**: total, used, free, available, swap
- **Storage**: mounted filesystems and physical disks
- **Network**: IP addresses, gateway, MAC address, DNS servers, public IP
## Requirements
 
- Linux (macOS is partly supported)
- Bash 4+
- Optional: `lm-sensors` (CPU temperature), `curl` (public IP)
## Usage
 
```bash
chmod +x pcinfo.sh
./pcinfo.sh            # show everything
./pcinfo.sh --cpu      # one section only
./pcinfo.sh -c -m      # combine sections
./pcinfo.sh --help
```
 
| Option | Description |
| --- | --- |
| `-a`, `--all` | Show everything (default) |
| `-o`, `--os` | Operating system info |
| `-c`, `--cpu` | CPU info |
| `-m`, `--memory` | RAM info |
| `-s`, `--storage` | Storage info |
| `-n`, `--network` | Network info |
| `-h`, `--help` | Show help |
 
