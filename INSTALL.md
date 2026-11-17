# Installation
 
PC Info Tool is a single Bash script for Linux and macOS. There's nothing to build: download it, make it executable, and run it.
 
## Requirements
 
- Linux or macOS
- Bash 4+ (on macOS, the default Bash is 3.2, so install a newer one with `brew install bash`)
- Optional: `curl` (public IP lookup), `lm-sensors` (CPU temperature)
## Option 1: Quick install (system-wide)
 
```bash
curl -fsSL -o pcinfo https://github.com/AlanBlunt/pc-info-tool/releases/download/v1.0.0/pcinfo.sh
chmod +x pcinfo
sudo mv pcinfo /usr/local/bin/pcinfo
pcinfo
```
 
## Option 2: Install for your user only (no sudo)
 
```bash
mkdir -p ~/.local/bin
curl -fsSL -o ~/.local/bin/pcinfo https://github.com/AlanBlunt/pc-info-tool/releases/download/v1.0.0/pcinfo.sh
chmod +x ~/.local/bin/pcinfo
pcinfo
```
 
If `pcinfo` isn't found, add `~/.local/bin` to your PATH: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc`
 
## Option 3: Clone the repository
 
```bash
git clone https://github.com/AlanBlunt/pc-info-tool.git
cd pc-info-tool
chmod +x pcinfo.sh
./pcinfo.sh
```
 
## Usage
 
```bash
pcinfo              # show everything
pcinfo --cpu        # one section only
pcinfo -c -m        # combine sections
pcinfo --help
```
 
## Optional extras
 
- CPU temperature: `sudo apt install lm-sensors` (Debian/Ubuntu), `sudo dnf install lm_sensors` (Fedora), or `sudo pacman -S lm_sensors` (Arch)
## Verify the download (optional)
 
Download `SHA256SUMS` from the release into the same folder as `pcinfo.sh`, then:
 
```bash
sha256sum -c SHA256SUMS      # Linux
shasum -a 256 -c SHA256SUMS  # macOS
```
 
## Uninstall
 
```bash
sudo rm /usr/local/bin/pcinfo     # if installed system-wide
rm ~/.local/bin/pcinfo            # if installed for your user
```
 
## Troubleshooting
 
| Problem | Fix |
| --- | --- |
| `Permission denied` | Run `chmod +x pcinfo.sh` |
| `bad interpreter` or `\r` errors | The file has Windows line endings. Run `sed -i 's/\r$//' pcinfo.sh` |
| `pcinfo: command not found` | The install folder isn't on your PATH (see Option 2) |
| Errors on macOS about syntax | You're on the old built-in Bash 3.2. Install a newer Bash with Homebrew |
| Public IP shows "Unavailable" | You're offline, or `curl` isn't installed |
 