{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # ────────────────────────────────────────────────
  # Boot & Kernel
  # ────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;

    configurationLimit = 3;   # Display max 3 generations
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ────────────────────────────────────────────────
  # Networking & Basics
  # ────────────────────────────────────────────────
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Brussels";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_GB.UTF-8";
    };
  };

  # ────────────────────────────────────────────────
  # Keyboard / XServer (still needed for some settings even on Wayland)
  # ────────────────────────────────────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ────────────────────────────────────────────────
  # Desktop Environment (COSMIC)
  # ────────────────────────────────────────────────
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # ────────────────────────────────────────────────
  # Power Management & Battery Saving
  # ────────────────────────────────────────────────
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  services = {
    upower.enable = true;           # power management abstraction (useful for DE)
    auto-cpufreq.enable = true;
    thermald.enable = true;
    logind.lidSwitch = "hibernate";
  };

  # ────────────────────────────────────────────────
  # User
  # ────────────────────────────────────────────────
  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };

  # ────────────────────────────────────────────────
  # Nixpkgs & Unfree
  # ────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ────────────────────────────────────────────────
  # Nix Garbage Collection & Optimization
  # ────────────────────────────────────────────────
  nix = {
    # Automatic garbage collection to delete old generations and unused packages
    gc = {
      automatic = true;             # ← Enable auto GC
      dates = "daily";             # Run weekly (or set to "daily" if preferred)
      options = "--delete-older-than 5d";  # Delete generations older than 30 days
    };

    # Optional: Automatic store optimization (deduplication to save space)
    optimise.automatic = true;
  };

  # ────────────────────────────────────────────────
  # Steam + Proton-GE
  # ────────────────────────────────────────────────
  programs.steam = {
    enable = true;

    # Recommended extra packages for better Proton/Wine/Steam integration
    extraCompatPackages = with pkgs; [
      proton-ge-bin          # Proton-GE (use this in Steam → per-game compatibility tool)
    ];

    # Optional: enable gamemode, gamescope, etc. if you want them
    # gamescopeSession.enable = true;
    # remotePlay.openFirewall = true;
  };

  # ────────────────────────────────────────────────
  # System packages
  # ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Terminal & monitoring
    alacritty
    htop
    btop
    fastfetch
    cowsay
    less

    # Editors & dev
    neovim
    vimPlugins.LazyVim
    vscode
    nodejs_24

    # Browsers & web
    librewolf
    ungoogled-chromium

    # Media & entertainment
    spotify
    stremio
    discord
    ffmpeg
    nomacs               # image viewer
    ani-cli

    # Office & tools
    libreoffice
    baobab               # disk usage analyzer
    filezilla
    mysql-workbench
    github-desktop
    teams-for-linux

    # COSMIC extras
    cosmic-ext-tweaks
    cosmic-ext-calculator

    # Steam related
    steam                # already enabled above, but kept here for visibility
  ];

  # ────────────────────────────────────────────────
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11";
}
