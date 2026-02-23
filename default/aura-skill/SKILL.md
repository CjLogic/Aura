---
name: aura
description: >
  REQUIRED for ANY changes to Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/hypr/hyprland/, ~/.config/walker/,
  ~/.config/alacritty/, ~/.config/kitty/, ~/.config/ghostty/, ~/.config/mako/,
  or ~/.config/aura/. Triggers: Hyprland, window rules, animations, keybindings,
  monitors, gaps, borders, blur, opacity, walker, terminal config, night light, idle, lock screen, screenshots, layer rules, workspace
  settings, display config, or any aura-* commands.
---

# aura Skill

Manage [aura](https://github.com/cjlogic/aura-ambxst) Linux systems - a beautiful, modern, opinionated Arch Linux distribution with Hyprland.

## When This Skill MUST Be Used

**ALWAYS invoke this skill when the user's request involves ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing terminal configs (alacritty, kitty, ghostty)
- Editing ANY file in `~/.config/aura/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Any `aura-*` command
- Screenshots, screen recording, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

## Critical Safety Rules

**NEVER modify anything in `~/.local/share/aura/`** - but READING is safe and encouraged.
**UNLESS told explicitly by user**

This directory contains aura's source files managed by git. Any changes will be:

- Lost on next `aura-update`
- Cause conflicts with upstream
- Break the system's update mechanism

```
~/.local/share/aura/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Source scripts (symlinked to PATH)
├── config/                 # Default config templates
├── default/                # System defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `~/.local/share/aura/` is SAFE and useful** - do it freely to:

- Understand how aura commands work: `cat $(which aura-tui-install)`
- See default configs before customizing: `cat ~/.local/share/aura/kitty/kitty.conf`
- Reference default hyprland settings: `cat ~/.local/share/aura/default/hypr/*`

**Always use these safe locations instead:**

- `~/.config/` - User configuration (safe to edit)
- `~/.config/aura/hooks/` - Custom automation hooks

## System Architecture

aura is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **Alacritty/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **Mako** | Notifications | `~/.config/mako/` |
| **SwayOSD** | On-screen display | `~/.config/swayosd/` |

## Command Discovery

aura provides ~145 commands following `aura-<category>-<action>` pattern.

```bash
# List all aura commands
compgen -c | grep -E '^aura-' | sort -u

# Find commands by category
compgen -c | grep -E '^aura-hook'
compgen -c | grep -E '^aura-restart'

# Read a command's source to understand it
cat $(which aura-hook)
```

### Command Categories

| Prefix | Purpose | Example |
|--------|---------|---------|
| `aura-refresh-*` | Reset config to defaults (backs up first) | `aura-restart-pipewire` |
| `aura-restart-*` | Restart a service/app | `aura-restart-pipewire` |
| `aura-toggle-*` | Toggle feature on/off | `aura-toggle-nightlight` |
| `aura-install-*` | Install optional software | `aura-install-docker-dbs` |
| `aura-launch-*` | Launch apps | `aura-launch-browser` |
| `aura-cmd-*` | System commands | `aura-cmd-screenshot` |
| `aura-pkg-*` | Package management | `aura-pkg-install <pkg>` |
| `aura-setup-*` | Initial setup tasks | `aura-setup-fingerprint` |
| `aura-update-*` | System updates | `aura-update` |

## Configuration Locations

### Hyprland (Window Manager)

```
~/.config/hypr/
├── hyprland.conf      # Main config (sources others)
├── hyprland/animations.conf    # Appearance (gaps, borders, animations)
├── hyprland/apps/*.conf        # independent App rules
├── hyprland/bindings.conf      # Keybindings
├── hyprland/monitors.conf      # Display configuration
├── hyprland/input.conf         # Keyboard/mouse settings
├── hyprland/envs.conf          # Environment variables
├── hyprland/autostart.conf     # Startup applications
├── hyprland/hypridle.conf      # Idle behavior (screen off, lock, suspend)
├── hyprland/hyprlock.conf      # Lock screen appearance
├── hyprland/rules.conf         # Window rules
├── plugin.conf      # hyprland plugins
└── hyprland/hyprsunset.conf    # Night light / blue light filter
```

**Key behaviors:**

- Hyprland auto-reloads on config save (no restart needed for most changes)
- Use `hyprctl reload` to force reload
- Use `aura-refresh-hyprland` to reset to defaults

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `aura-restart-terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |
| walker | `~/.config/walker/config.toml` |

## Safe Customization Patterns

### Pattern 1: Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.conf

# 2. Backup before changes
cp ~/.config/hypr/bindings.conf ~/.config/hypr/bindings.conf.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save (no restart needed)
# - Terminals: MUST restart with aura-restart-terminal
```

### Keybindings

Edit `~/.config/hypr/bindings.conf`. Format:

```
bind = SUPER, Return, exec, xdg-terminal-exec
bind = SUPER, Q, killactive
bind = SUPER SHIFT, E, exit
```

View current bindings: `aura-menu-keybindings --print`

**IMPORTANT: When re-binding an existing key:**

1. First check existing bindings: `aura-menu-keybindings --print`
2. If the key is already bound, you MUST add an `unbind` directive BEFORE your new `bind`
3. Inform the user what the key was previously bound to

Example - rebinding SUPER+F (which is bound to fullscreen by default):

```
# Unbind existing SUPER+F (was: fullscreen)
unbind = SUPER, F
# New binding for file manager
bind = SUPER, F, exec, nautilus
```

Always tell the user: "Note: SUPER+F was previously bound to fullscreen. I've added an unbind directive to override it."

### Display/Monitors

Edit `~/.config/hypr/monitors.conf`. Format:

```
monitor = eDP-1, 1920x1080@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1
```

List monitors: `hyprctl monitors`

### Window Rules

**CRITICAL: Hyprland window rules syntax changes frequently between versions.**

Before writing ANY window rules, you MUST fetch the current documentation from the official Hyprland wiki:

- <https://github.com/hyprwm/hyprland-wiki/blob/main/content/Configuring/Window-Rules.md>

DO NOT rely on cached or memorized window rule syntax. The format has changed multiple times and using outdated syntax will cause errors or unexpected behavior.

Window rules go in `~/.config/hypr/hyprland.conf` or a sourced file. Always verify the current syntax from the wiki first.

### Fonts

```bash
aura-font-list               # Available fonts
aura-font-current            # Current font
aura-font-set <name>         # Change font
```

### System

```bash
aura-update                  # Full system update
aura-version                 # Show aura version
aura-debug --no-sudo --print # Debug info (ALWAYS use these flags)
aura-lock-screen             # Lock screen
aura-cmd-shutdown            # Shutdown
aura-cmd-reboot              # Reboot
```

**IMPORTANT:** Always run `aura-debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
aura-debug --no-sudo --print

# Upload logs for support
aura-upload-log

# Reset specific config to defaults
aura-refresh-<app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. aura-refresh-config hypr/hyprlock.conf will refresh ~/.config/hypr/hyprlock.conf
aura-refresh-config <config-file>

# Full reinstall of configs (nuclear option)
aura-reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock aura command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `~/.local/share/aura/`
3. **Is it automation?** Use hooks in `~/.config/aura/hooks/`
4. **Is it a package install?** Use `yay`
5. **Unsure if command exists?** Search with `compgen -c | grep aura`

## Development (AI Agents)

When contributing to aura itself (e.g., fixing bugs, adding features), migrations are used to apply changes to existing installations.

### Creating Migrations

```bash
# ALWAYS use --no-edit flag or you will get stuck
aura-dev-add-migration --no-edit
```

This creates a new migration file and outputs its path without opening an editor. The migration filename is based on the git commit timestamp.

**Migration files** are shell scripts in `~/.local/share/aura/migrations/` that run once per system during `aura-update`. Use them for:

- Updating user configs with new defaults
- Installing new dependencies
- Running one-time setup tasks

## Example Requests

- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, add `unbind` if needed, then add `bind` in `~/.config/hypr/bindings.conf`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.conf`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.conf`
- "Set up night light to turn on at sunset" -> `aura-toggle-nightlight` or edit `~/.config/hypr/hyprsunset.conf`
