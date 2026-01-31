# Aura - Powerful Dev Tools meets Beautiful Aesthetics

Aura is a custom Arch Linux-based distribution designed to integrate seamlessly with the [Ambxst](https://github.com/Axenide/Ambxst) Quickshell environment. It combines a pre-configured Hyprland desktop with a comprehensive suite of development tools inherited from Omarchy.

Originally forked from Omarchy, Aura has been completely revamped to balance high-performance workflow capabilities with the striking aesthetics of the Ambxst setup. This distribution provides a resilient, out-of-the-box system that pairs deep utility with refined visual design.

## What is Ambxst?

[Ambxst](https://github.com/Axenide/Ambxst) is a Quickshell-based desktop environment that provides a modern, customizable interface with launcher, status bar, and notification components. Aura ships with a base Hyprland configuration and includes an automated first-boot script to install Ambxst (which requires AUR dependencies).

## System Requirements

- **RAM**: 2GB minimum (4GB recommended)
- **Disk Space**: 20GB minimum
- **CPU**: x86_64 processor
- **Graphics**: GPU with Wayland support recommended
- **Boot**: UEFI or BIOS

## Features

- **Pre-configured Hyprland Environment**: Boot directly into a fully customized Hyprland desktop with base configuration
- **Automated Ambxst Setup**: First-boot script guides installation of Ambxst environment
- **Comprehensive Package Set**: Includes 150+ packages covering development tools, desktop environment, and utilities
- **Developer-Focused**: Pre-installed with Docker, Git tools, language runtimes, and dev utilities

## Desktop Environment

- **Window Manager**: Hyprland (Wayland compositor)
- **Terminal**: kitty
- **Shell**: Fish with Starship prompt
- **Application Launcher**: Ambxst (installed via first-boot script)
- **Status Bar**: Ambxst (installed via first-boot script)
- **Notifications**: Ambxst (installed via first-boot script)
- **File Manager**: Nautilus
- **Login Manager**: SDDM

## Included Packages

### Development Tools

- **Languages**: TypeScript, Ruby, Python, Lua, Dart
- **Containers**: Docker, Docker Compose
- **Git Tools**: LazyGit, GitHub CLI
- **Editors**: Micro, VS Code (via Flatpak)

### System Utilities

- **Modern replacements**: bat, eza, ripgrep, fd, dust, zoxide
- **Monitoring**: btop, htop, inxi
- **Network**: iwd, NetworkManager, avahi

## Installation

1. Boot from the ISO
2. The Aura installer will launch automatically
3. Follow the installation wizard:
   - Select language and timezone
   - Partition your disk
   - Create user account
   - Choose hostname
4. Reboot after installation completes
5. Login and you'll be greeted with the Aura Hyprland desktop

For build instructions, see the [aura-iso repository](https://github.com/CjLogic/aura-iso).

## First Boot

On first login, the Ambxst installation script will automatically appear, providing:

- Guided installation of Ambxst Quickshell environment
- Complete Hyprland configuration integration
- Aura configs in `~/.config/`
- All utility scripts in `~/.local/share/aura/bin/`
- Fish shell with Starship prompt
- Fastfetch, btop, and other utilities pre-configured

## Keybindings

Essential Hyprland keybindings:

- `SUPER + RETURN` - Open terminal
- `SUPER + W` - Close window
- `SUPER + 1-9` - Switch workspaces
- `SUPER + Shift + 1-9` - Move window to workspace
- `SUPER + F` - Toggle fullscreen
- `SUPER + V` - Toggle floating

## Manual Ambxst Installation

If needed, Ambxst can be installed manually:

```bash
curl -L get.axeni.de/ambxst | sh
```

If the installation fails, update the system first:

```bash
sudo pacman -Syyu --noconfirm
curl -L get.axeni.de/ambxst | sh
```

## Customization

### Adding Packages

Edit `aura-base.packages` and add package names (one per line). Ensure they are official Pacman packages.

### Modifying Configs

To customize Ambxst configurations, refer to the [Ambxst documentation](https://axeni.de/ambxst/).

### Branding

Customize boot and ISO branding:

- Boot menus: `grub/grub.cfg`, `syslinux/syslinux.cfg`
- ISO metadata: `profiledef.sh`

## Contributing

Contributions are welcome:

1. Fork the Aura repository
2. Make your changes
3. Test with the Aura build process
4. Submit a pull request

## License

Aura is released under the [MIT License](https://opensource.org/licenses/MIT).

This project incorporates components from:
- Arch Linux (GPL)
- Ambxst (see [Ambxst repository](https://github.com/Axenide/Ambxst) for license details)

## Links

- **Aura**: <https://github.com/CjLogic/Aura>
- **Aura ISO Builder**: <https://github.com/CjLogic/aura-iso>
- **Ambxst**: <https://github.com/Axenide/Ambxst>
- **Arch Linux**: <https://archlinux.org>

## Support

For issues specific to:

- **Aura build process or ISO**: Create an issue in the [aura-iso repository](https://github.com/CjLogic/aura-iso)
- **Ambxst configuration**: Create an issue in the [Ambxst repository](https://github.com/Axenide/Ambxst)
- **Arch packages**: Consult the [Arch Linux wiki](https://wiki.archlinux.org)

## Credits

- **Omarchy**: <https://github.com/basecamp/omarchy>
- **Ambxst**: <https://github.com/Axenide/Ambxst>

---
