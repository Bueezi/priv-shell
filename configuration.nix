{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # ./hyprland.nix
  ];

  # ────────────────────────────────────────────────
  # Boot & Kernel
  # ────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.loader.systemd-boot.configurationLimit = 3;
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
  # Desktop Environment
  # ────────────────────────────────────────────────
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # ────────────────────────────────────────────────
  # Power Management & Battery Saving
  # ────────────────────────────────────────────────
  powerManagement.enable = true;

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    thermald.enable = true;

    logind.settings = {
      Login = {
        HandleLidSwitch = "suspend-then-hibernate";
        HandlePowerKey = "hibernate";
        HandlePowerKeyLongPress = "poweroff";
        IdleAction = "suspend-then-hibernate";
        IdleActionSec = "5min";
      };
    };
  };

  boot.kernelParams = [ "mem_sleep_default=deep" ];

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=10m
    SuspendState=mem
  '';

  # ────────────────────────────────────────────────
  # User
  # ────────────────────────────────────────────────
  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ────────────────────────────────────────────────
  # Nix Garbage Collection & Optimization
  # ────────────────────────────────────────────────
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  # ────────────────────────────────────────────────
  # Packages
  # ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    alacritty
    htop
    btop
    fastfetch
    cowsay
    less
    wl-clipboard
    powertop

    # Editors & dev
    neovim
    vscode
    nodejs_24
    dotnet-sdk_10

    # Browsers
    librewolf
    ungoogled-chromium

    # Media & entertainment
    spotify
    vesktop
    ffmpeg
    ani-cli
    stremio

    # Office & tools
    libreoffice
    filezilla
    mysql-workbench
    github-desktop
    teams-for-linux

    # DE extras
    cosmic-ext-tweaks
    cosmic-ext-calculator
    baobab
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    gamescopeSession.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";
}
