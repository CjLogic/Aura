#!/bin/bash
# NVIDIA Driver Setup for Hyprland
# Detects NVIDIA GPU and installs appropriate drivers

NVIDIA="$(lspci | grep -i 'nvidia')"

if [ -z "$NVIDIA" ]; then
  echo "No NVIDIA GPU detected, skipping NVIDIA configuration"
  exit 0
fi

echo "NVIDIA GPU detected: $NVIDIA"

# Determine kernel headers package
KERNEL_HEADERS="$(pacman -Qqs '^linux(-zen|-lts|-hardened)?$' | head -1)-headers"

# Select driver based on GPU architecture
if echo "$NVIDIA" | grep -qE "RTX [2-9][0-9]|GTX 16"; then
  # Turing (16xx, 20xx), Ampere (30xx), Ada (40xx) - use open kernel modules
  echo "Turing/Ampere/Ada GPU detected - using nvidia-open-dkms"
  PACKAGES=(nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils egl-wayland libva-nvidia-driver qt5-wayland qt6-wayland)
elif echo "$NVIDIA" | grep -qE "GTX 9|GTX 10|Quadro P|MX1|MX2|MX3"; then
  # Pascal (10xx, Quadro Pxxx, MX150-350) and Maxwell (9xx, MX110-130) - legacy branch
  echo "Pascal/Maxwell GPU detected - using nvidia-580xx-dkms (legacy)"
  PACKAGES=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils egl-wayland qt5-wayland qt6-wayland)
else
  echo "No compatible driver found for your NVIDIA GPU."
  echo "See: https://wiki.archlinux.org/title/NVIDIA"
  exit 0
fi

# Install driver packages
echo "Installing NVIDIA packages: ${PACKAGES[*]}"
aura-pkg-add "$KERNEL_HEADERS" "${PACKAGES[@]}" || {
  echo "Error: Failed to install NVIDIA packages"
  exit 1
}

# Configure modprobe for early KMS (generic config)
# Note: ASUS-specific config in nvidia-asus.conf takes precedence if present
if [[ ! -f /etc/modprobe.d/nvidia-asus.conf ]]; then
  echo "Configuring modprobe..."
  sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF
else
  echo "Skipping nvidia.conf (nvidia-asus.conf exists for ASUS hardware)"
fi

# Configure mkinitcpio for early module loading (drop-in config)
echo "Configuring initramfs modules..."
sudo mkdir -p /etc/mkinitcpio.conf.d
sudo tee /etc/mkinitcpio.conf.d/nvidia.conf >/dev/null <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF

# Regenerate initramfs
echo "Regenerating initramfs..."
sudo mkinitcpio -P

# Add NVIDIA environment variables to Hyprland
HYPRLAND_ENV_CONF="$HOME/.config/hypr/envs.conf"
if [ -f "$HYPRLAND_ENV_CONF" ]; then
  # Only add if not already present
  if ! grep -q "LIBVA_DRIVER_NAME,nvidia" "$HYPRLAND_ENV_CONF"; then
    echo "Adding NVIDIA environment variables to Hyprland..."
    cat >>"$HYPRLAND_ENV_CONF" <<'EOF'

# NVIDIA environment variables
env = NVD_BACKEND,direct
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
  else
    echo "NVIDIA environment variables already configured in Hyprland"
  fi
else
  echo "Warning: $HYPRLAND_ENV_CONF not found, skipping env vars"
fi

echo "✓ NVIDIA driver setup complete"
