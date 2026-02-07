#!/bin/bash
# ASUS Laptop Hardware Support
# Detects ASUS hardware and installs appropriate tools
# NOTE: NVIDIA driver installation is handled by nvidia.sh
#       This script only handles ASUS-specific tools and power management

echo "Checking for ASUS hardware..."

# Detect ASUS hardware using DMI info (works in chroot unlike lspci for some checks)
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")

if ! echo "$SYS_VENDOR" | grep -qi "ASUSTeK"; then
  echo "No ASUS hardware detected, skipping ASUS-specific configuration"
  exit 0
fi

echo "✓ ASUS hardware detected: $PRODUCT_NAME"
echo "Configuring ASUS-specific hardware support..."

# Add G14 repository for ASUS tools
echo "Adding G14 repository for ASUS-specific packages..."

# Add G14 repository GPG key
if ! pacman-key --list-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 &>/dev/null; then
  echo "Adding G14 repository GPG key..."
  sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 2>/dev/null || {
    echo "Warning: Could not receive key from keyserver, trying alternative method..."
    wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8b15a6b0e9a3fa35" -O /tmp/g14.sec
    sudo pacman-key -a /tmp/g14.sec
    rm -f /tmp/g14.sec
  }
  sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 || echo "Warning: Could not verify key fingerprint"
  sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 || echo "Warning: Could not locally sign key"
else
  echo "✓ G14 repository key already present"
fi

# Add G14 repo to pacman.conf if not already present
if ! grep -q "\[g14\]" /etc/pacman.conf; then
  echo "Adding G14 repository to /etc/pacman.conf..."
  sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

# G14 repository for ASUS laptop tools
[g14]
Server = https://arch.asus-linux.org
EOF
  echo "✓ G14 repository added"
  # Refresh after adding new repo
  sudo pacman -Sy --noconfirm
else
  echo "✓ G14 repository already configured"
fi

# Install ASUS control utilities
echo "Installing ASUS control utilities..."
aura-pkg-add asusctl rog-control-center || echo "Warning: Some ASUS packages failed to install"

# Note: asusd is triggered by udev rule, don't enable it manually
echo "Note: asusd service is triggered by udev rules (do not enable manually)"

# Configure ASUS-specific NVIDIA power management (only if NVIDIA drivers are installed)
if pacman -Q nvidia-utils &>/dev/null || pacman -Q nvidia-580xx-utils &>/dev/null; then
  echo "NVIDIA drivers detected on ASUS hardware - configuring power management..."

  # Detect GPU for architecture-specific config
  GPU_INFO=$(lspci | grep -i 'nvidia')

  # Check for Turing architecture (GTX 16xx series needs special config)
  if echo "$GPU_INFO" | grep -qE "GTX 16[0-9]{2}"; then
    echo "Turing GPU detected - configuring S0ix power management..."

    # Create NVIDIA modprobe config with Turing-specific settings
    # This overrides the generic nvidia.conf from nvidia.sh
    sudo tee /etc/modprobe.d/nvidia-asus.conf >/dev/null <<'EOF'
# NVIDIA configuration for ASUS laptops with Turing GPUs
options nvidia_drm modeset=1 fbdev=1

# Disable GSP firmware for Turing GPUs (required for proper power management)
# Enable S0ix power management
options nvidia NVreg_EnableGpuFirmware=0 NVreg_EnableS0ixPowerManagement=1 NVreg_DynamicPowerManagement=0x02
EOF

    # Remove generic nvidia.conf since we have ASUS-specific one
    sudo rm -f /etc/modprobe.d/nvidia.conf

    echo "✓ Turing GPU power management configured"

    # Download NVIDIA udev rules for ASUS laptops
    echo "Installing NVIDIA power management udev rules..."
    sudo curl -fsSL https://gitlab.com/asus-linux/nvidia-laptop-power-cfg/-/raw/main/nvidia.rules \
      -o /usr/lib/udev/rules.d/80-nvidia-pm.rules 2>/dev/null || \
      echo "Warning: Could not download NVIDIA udev rules"

  elif echo "$GPU_INFO" | grep -qE "RTX [2-9][0-9]{3}|RTX [4-9][0-9]"; then
    # Ampere (RTX 30xx) or Ada (RTX 40xx) or newer
    echo "Ampere/Ada GPU detected"
    echo "Note: For optimal power management, consider installing nvidia-laptop-power-cfg from AUR:"
    echo "  yay -S nvidia-laptop-power-cfg"
  fi

  # Enable NVIDIA power management services (these exist after nvidia driver install)
  echo "Enabling NVIDIA power management services..."
  chrootable_systemctl_enable nvidia-suspend.service || true
  chrootable_systemctl_enable nvidia-hibernate.service || true
  chrootable_systemctl_enable nvidia-resume.service || true

  # Enable nvidia-powerd if available (provides dynamic power management)
  if systemctl list-unit-files 2>/dev/null | grep -q "nvidia-powerd"; then
    chrootable_systemctl_enable nvidia-powerd.service || true
  fi
else
  echo "No NVIDIA drivers installed, skipping NVIDIA power management configuration"
fi

# Check if custom kernel might be needed (2024+ models)
PRODUCT_YEAR=$(echo "$PRODUCT_NAME" | grep -oP '20[2-9][0-9]' | head -1)
if [[ -n "$PRODUCT_YEAR" ]] && [[ "$PRODUCT_YEAR" -ge 2024 ]]; then
  echo ""
  echo "⚠ Note: Your ASUS laptop is from $PRODUCT_YEAR"
  echo "   Newer models may benefit from the linux-g14 kernel with ASUS-specific patches"
  echo "   To install: sudo pacman -S linux-g14 linux-g14-headers"
  echo "   Then regenerate boot configuration"
  echo ""
fi

echo "✓ ASUS hardware configuration complete"
