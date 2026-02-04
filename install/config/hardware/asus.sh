#!/bin/bash
# ASUS Laptop Hardware Support
# Detects ASUS hardware and installs appropriate tools and drivers

echo "Checking for ASUS hardware..."

# Detect ASUS hardware
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")

IS_ASUS=false
if echo "$SYS_VENDOR" | grep -qi "ASUSTeK"; then
  IS_ASUS=true
  echo "✓ ASUS hardware detected: $PRODUCT_NAME"
fi

if [[ "$IS_ASUS" == "true" ]]; then
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
  else
    echo "✓ G14 repository already configured"
  fi

  # Refresh package databases
  echo "Refreshing package databases..."
  sudo pacman -Sy --noconfirm

  # Install asusctl and rog-control-center
  echo "Installing ASUS control utilities..."
  ASUS_PACKAGES=(
    "asusctl"
    "rog-control-center"
  )

  for pkg in "${ASUS_PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
      echo "Installing $pkg..."
      sudo pacman -S --noconfirm --needed "$pkg" || echo "Warning: Failed to install $pkg"
    else
      echo "✓ $pkg already installed"
    fi
  done

  # Note: asusd is triggered by udev rule, don't enable it manually
  echo "Note: asusd service is triggered by udev rules (do not enable manually)"

  # Check if NVIDIA GPU is present for ASUS-specific power management
  if lspci | grep -qi 'nvidia'; then
    echo "NVIDIA GPU detected on ASUS hardware..."

    # Detect GPU architecture
    GPU_INFO=$(lspci | grep -i 'nvidia')

    # Check for Turing architecture (GTX 1000 series, needs special config)
    if echo "$GPU_INFO" | grep -qE "GTX 1[0-9]{2}0|GTX 16[0-9]{2}"; then
      echo "Turing GPU detected - configuring S0ix power management..."

      # Create NVIDIA modprobe config with Turing-specific settings
      sudo tee /etc/modprobe.d/nvidia-asus.conf >/dev/null <<'EOF'
# NVIDIA configuration for ASUS laptops with Turing GPUs
options nvidia_drm modeset=1

# Disable GSP firmware for Turing GPUs (required for proper power management)
# Enable S0ix power management
options nvidia NVreg_EnableGpuFirmware=0 NVreg_EnableS0ixPowerManagement=1 NVreg_DynamicPowerManagement=0x02
EOF

      echo "✓ Turing GPU power management configured"

      # Download and install nvidia udev rules for ASUS laptops
      echo "Installing NVIDIA power management udev rules..."
      sudo curl -fsSL https://gitlab.com/asus-linux/nvidia-laptop-power-cfg/-/raw/main/nvidia.rules \
        -o /usr/lib/udev/rules.d/80-nvidia-pm.rules 2>/dev/null || \
        echo "Warning: Could not download NVIDIA udev rules"

    # Ampere (RTX 2000+) or newer - suggest nvidia-laptop-power-cfg from AUR
    elif echo "$GPU_INFO" | grep -qE "RTX [2-9][0-9]{3}|RTX [4-9][0-9]"; then
      echo "Ampere/Ada GPU detected"
      echo "Note: For optimal power management, consider installing nvidia-laptop-power-cfg from AUR:"
      echo "  yay -S nvidia-laptop-power-cfg"
    fi

    # Enable NVIDIA power management services
    echo "Enabling NVIDIA power management services..."
    chrootable_systemctl_enable nvidia-suspend.service || true
    chrootable_systemctl_enable nvidia-hibernate.service || true
    chrootable_systemctl_enable nvidia-resume.service || true

    # Enable nvidia-powerd if available
    if systemctl list-unit-files | grep -q "nvidia-powerd"; then
      chrootable_systemctl_enable nvidia-powerd.service || true
    fi
  fi

  # Check if custom kernel might be needed (2024+ models)
  PRODUCT_YEAR=$(echo "$PRODUCT_NAME" | grep -oP '20[2-9][0-9]' | head -1)
  if [[ -n "$PRODUCT_YEAR" ]] && [[ "$PRODUCT_YEAR" -ge 2024 ]]; then
    echo ""
    echo "⚠ Note: Your ASUS laptop is from $PRODUCT_YEAR"
    echo "   Newer models may benefit from the linux-g14 kernel with ASUS-specific patches"
    echo "   To install: sudo pacman -S linux-g14 linux-g14-headers"
    echo "   Then regenerate boot configuration: sudo limine-update"
    echo ""
  fi

  echo "✓ ASUS hardware configuration complete"
else
  echo "No ASUS hardware detected, skipping ASUS-specific configuration"
fi
