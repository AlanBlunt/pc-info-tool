## PC Info Tool v1.0.0
 
First release. A Bash script for Linux and macOS that displays CPU, RAM, storage, OS and network information from the command line.
 
### Highlights
 
- Show everything, or pick sections: `--cpu`, `--memory`, `--storage`, `--os`, `--network`
- Single file, no dependencies beyond Bash 4+
- Colour output only when printing to a terminal
### Install
 
```bash
curl -fsSL -o pcinfo https://github.com/AlanBlunt/pc-info-tool/releases/download/v1.0.0/pcinfo.sh
chmod +x pcinfo
sudo mv pcinfo /usr/local/bin/pcinfo
pcinfo
```
 
Prefer not to use sudo, want to clone the repo, or need uninstall steps and troubleshooting? See [INSTALL.md](https://github.com/AlanBlunt/pc-info-tool/blob/v1.0.0/INSTALL.md).
 
### Assets
 
| File | Use |
| --- | --- |
| `pcinfo.sh` | The script (Linux / macOS) |
| `SHA256SUMS` | Checksum to verify the download |
 