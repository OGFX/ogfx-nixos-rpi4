{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
  ];

  sdImage = {
    firmwareSize = 128;
    populateRootCommands = "mkdir -p ./files/var/empty";
    imageBaseName = "ogfx-nixos-sd-image";
  };

  fileSystems = lib.mkForce {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  nixpkgs.system = "aarch64-linux";
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;
  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.consoleLogLevel = lib.mkDefault 7;

  networking.hostName = "ogfx";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    vim nano jack2 jalv gxplugins-lv2 swh_lv2
    htop emacs tmux
  ];
  #  mod-distortion mda_lv2 infamousPlugins
  #  gxmatcheq-lv2 eq10q bshapr fomp rkrlv2
  #  zam-plugins 

  services.xserver.enable = false;

  users.users.ogfx = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "$6$ebhWmP8YjP5H$s/buwRq3YWf1QCSe/jMhybOGfnp1u0S4wysSt5dLuvIKIg966kszvMTC7CCuZ/GxiMkzpxGBwqg66H145nX5D/";
  };

  system.stateVersion = "20.03";
}
