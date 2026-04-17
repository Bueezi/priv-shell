# load installer to ram
# root:voidlinux
# gdisk partitions: 1gb fat32 at /boot, swap(1.5* ram if wanna hibernate), ext4
# void-installer
# 

echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm
echo -n "Are u using intel, amd or nvidia ? (i/a/n): " && read hardware

echo "max-transactions=10" | sudo tee /etc/xbps.d/xbps.conf
sudo xbps-install -Su void-repo-nonfree #void-repo-multilib void-repo-multilib-nonfree
echo "repository=https://github.com/index-0/librewolf-void/releases/latest/download/" | sudo tee /etc/xbps.d/20-librewolf.conf

if lscpu | grep -q "GenuineIntel"; then
    ucode="intel-ucode" # intel-ucode needs initramfs regeneration!!!
else
    ucode="linux-firmware-amd" # both cpu & gpu
fi

if [ "$hardware" == "i" ]; then
    hardware=""
elif [ "$hardware" == "a" ]; then
    hardware="$ucode mesa-dri vulkan-loader mesa-vulkan-radeon amdvlk mesa-vaapi libvdpau-va-gl"
fi

# need to set LIBVA_DRIVER_NAME to radeonsi and VDPAU_DRIVER to va_gl
wifi="wifi-firmware"

if [ "$wm" == "sway" ]; then
  wm_packages="sway swaybg foot fuzzel mako polkit-gnome brightnessctl network-manager-applet networkmanager-dmenu \
   blueman wl-clipboard cliphist swaylock swayidle xorg-xwayland xdg-desktop-portal-wlr seatd polkit nwg-look \
   i3status-rust grim slurp thunar"
elif [ "$wm" == "gnome" ]; then
  wm_packages="dbus gnome-core alacritty baobab gnome-calculator gnome-tweaks loupe showtime papers \
  power-profiles-daemon extension-manager gnome-system-monitor gnome-backgrounds gsound"
fi

audio="pipewire wireplumber pipewire-pulse alsa-pipewire libjack-pipewire bluez libspa-bluetooth"
apps="helix librewolf chromium baobab libreoffice-still"
fonts="font-iosevka noto-fonts-ttf"
bash_tools="git bc vim htop btop openssh wireguard-tools curl wget bash-completion man-db \
man-pages zip unzip 7zip ntfs-3g dosfstools less \
fastfetch cowsay cmatrix ffmpeg mpv stress gamemode fd nnn"
dev="github-cli nodejs npm rust gdb python python3-pip python-virtualenv docker docker-compose"
base="qt5-wayland qt6-wayland gnome-keyring"

packages="$hardware $wm_packages $wifi $apps $fonts $bash_tools $audio $dev $base"

# install
sudo xbps-install -Su $packages

"""
sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/gdm /var/service/
sudo sv stop dhcpcd
sudo sv disable dhcpcd
sudo rm /var/service/dhcpcd
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd /var/service/
"""
