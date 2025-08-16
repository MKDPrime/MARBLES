#!/bin/bash
# MARBLES (MKD's Arch Based Linux System)
# Author: MKDPrime

set -e

echo "=== MARBLES Installation Script Started ==="

# 1. Root check
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root!"
    exit 1
fi

# 2. System update
echo "Updating system..."
pacman -Syu --noconfirm

# 3. Base packages
echo "Installing base packages..."
pacman -S --noconfirm base base-devel linux linux-firmware git vim zsh st htop xorg xorg-xinit

# 4. NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

# 5. Create user
read -p "Enter a new username: " username
useradd -m -G wheel "$username"
passwd "$username"
echo "wheel ALL=(ALL) ALL" >> /etc/sudoers

# 6. Window Manager selection
echo "Select Window Manager: 1) dwm 2) Openbox"
read -p "Your choice (1/2): " wm_choice

if [ "$wm_choice" == "1" ]; then
    echo "Installing dwm..."
    pacman -S --noconfirm xorg-xprop xorg-xrdb dmenu rofi
    git clone https://git.suckless.org/dwm /tmp/dwm
    cd /tmp/dwm
    make
    sudo make install

    # Optional Dock
    read -p "Do you want a dock? [y/N]: " dock_choice
    if [[ "$dock_choice" == "y" || "$dock_choice" == "Y" ]]; then
        echo "Installing dock..."
        pacman -S --noconfirm tint2
        echo "tint2 &" >> /home/$username/.xinitrc
    fi

elif [ "$wm_choice" == "2" ]; then
    echo "Installing Openbox..."
    pacman -S --noconfirm openbox obconf
fi

# 7. Install programs
echo "Installing programs..."
pacman -S --noconfirm pcmanfm thunderbird cmus mpv nsxiv okular zathura liferea

# LibreWolf (AUR)
echo "Installing LibreWolf (AUR)..."
git clone https://aur.archlinux.org/librewolf.git /tmp/librewolf
cd /tmp/librewolf
makepkg -si --noconfirm

# 8. Shell configuration
chsh -s /bin/zsh "$username"

# Oh-my-zsh installation
sudo -u "$username" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 9. Xinitrc setup
cat <<EOL > /home/$username/.xinitrc
#!/bin/sh
# Autostart apps
nm-applet &
volumeicon &

# Window Manager
if [ "$wm_choice" == "1" ]; then
    exec dwm
else
    exec openbox-session
fi
EOL
chown $username:$username /home/$username/.xinitrc
chmod +x /home/$username/.xinitrc

# 10. Snap and Flatpak (optional)
pacman -S --noconfirm flatpak snapd
systemctl enable --now snapd.socket

echo "=== MARBLES Installation Completed! ==="
echo "Please reboot and login with your new user."