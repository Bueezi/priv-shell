#!/bin/bash
# loadkeys be-latin1
# iwctl
#	station <device> connect "SSID"
# ping 8.8.8.8
# timedatectl

# gdisk, luks, mkfs

echo -n "Root Pass : " && read root_pass
echo -n "Username : " && read usr_name
echo -n "Are u using intel or amd or nvidia ? (i/a/n) : " && read hardware

lsblk && echo -e "-------------------------------------\nDisks :" && lsblk | grep disk && echo -e "\n\n\n"

echo -n "Proceed ? (y/n) : " && read proceed

if [ "$proceed" != "y" ]; then
    echo "Aborting."
    exit 1
fi

# Enable multilib in live environment & increase parallel downloads
sed -i '/#\[multilib\]/,/#Include/ s/^#//' /etc/pacman.conf
sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

if [ "$hardware" == "i" ]; then
    hardware="linux intel-ucode mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva libvpl vpl-gpu-rt"
elif [ "$hardware" == "a" ]; then
    hardware="linux sof-firmware amd-ucode mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver opencl-mesa radeontop vulkan-tools"
elif [ "$hardware" == "n" ]; then
    hardware="linux-zen amd-ucode nvidia-open nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver"
fi
sway="sway foot dmenu ttf-firacode-nerd brightnessctl network-manager-applet blueman wl-clipboard swaybg swaylock swayidle xorg-xwayland xdg-desktop-portal-wlr seatd polkit"
sway_aur="arc-gtk-theme i3blocks"
gnome="gdm gnome-shell gnome-control-center gnome-settings-daemon gnome-session gnome-keyring gnome-tweaks gnome-system-monitor xdg-utils xdg-desktop-portal-gnome gnome-backgrounds gnome-disk-utility power-profiles-daemon nautilus gnome-calculator gnome-text-editor loupe showtime alacritty"

audio="pipewire lib32-pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack"
bash_tools="nvim htop btop openssh curl wget bash-completion man-db zip unzip ntfs-3g dosfstools less fastfetch cowsay reflector python python-pip python-virtualenv ffmpeg stress "
fonts="cantarell-fonts ttf-dejavu noto-fonts-emoji"
apps="chromium spotify-launcher steam"
aur="librewolf-bin visual-studio-code-bin"
school="teams-for-linux-bin github-desktop-bin"
aur_slow="protonup-qt-bin extension-manager ani-cli ${sway_aur}"
package_list="$hardware $sway $audio $bash_tools $fonts $apps"

base="linux-firmware base base-devel git efibootmgr networkmanager sudo vim bluez ufw cryptsetup"

pacstrap -K /mnt $base  $package_list
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt <<EOF

ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
timedatectl set-local-rtc 1
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=be-latin1" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "root:$root_pass" | chpasswd
useradd -m -G wheel "$usr_name"
useradd -m -G seat "$usr_name"
echo "$usr_name:$root_pass" | chpasswd
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers
#localectl set-keymap be-latin1


systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable ufw
systemctl enable seatd.service
ufw default deny incoming
ufw default allow outgoing

LUKS_UUID=$(blkid -s UUID -o value $(cryptsetup status cryptroot | grep device | awk '{print $2}'))
touch /boot/loader/entries/arch.conf
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions rd.luks.name=\${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw" > /boot/loader/entries/arch.conf
sed -i -E \
    -e 's/\budev\b/systemd/g' \
    -e 's/\bkeymap\b/sd-vconsole/g' \
    -e 's/\bconsolefont\b//g' \
    -e 's/\bfilesystems\b/sd-encrypt filesystems/' \
    /etc/mkinitcpio.conf
mkinitcpio -P

# Enable multilib, parallel downloads, colors, and ILoveCandy
cp /etc/pacman.conf /etc/pacman.conf.bak
sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sed -i '/^\[multilib\]/,/^$/ s/^#Include/Include/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/; s/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/# Misc options/a ILoveCandy' /etc/pacman.conf

sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j'"$(nproc)"'"/g' /etc/makepkg.conf

echo "$usr_name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # Allow user to use sudo without password
# Yay
su - $usr_name -c "git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si --noconfirm && cd .. && rm -rf yay"
su - $usr_name -c "yay -S --noconfirm $aur $aur_slow"

sed -i "/^$usr_name ALL=(ALL) NOPASSWD: ALL$/d" /etc/sudoers # Remove NOPASSWD line

#systemctl enable gdm

# Local Pacman mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --country 'Belgium,France,Netherlands,Germany' --age 12 --protocol https --sort rate --latest 10 --save /etc/pacman.d/mirrorlist

EOF
bootctl --path=/mnt/boot install

echo "Install finished !"
