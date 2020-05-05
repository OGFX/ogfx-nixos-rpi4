{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
  ];

  sdImage = {
    firmwareSize = 128;
    # This is a hack to avoid replicating config.txt from boot.loader.raspberryPi
    populateFirmwareCommands =
      "${config.system.build.installBootLoader} ${config.system.build.toplevel} -d ./firmware";
    # As the boot process is done entirely in the firmware partition.
    populateRootCommands = "";
    imageBaseName = "ogfx-nixos-sd-image";
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

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    vim nano jack2 jalv
  ];

  services.xserver.enable = false;

  users.users.ogfx = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "$6$ebhWmP8YjP5H$s/buwRq3YWf1QCSe/jMhybOGfnp1u0S4wysSt5dLuvIKIg966kszvMTC7CCuZ/GxiMkzpxGBwqg66H145nX5D/";
  };

  system.stateVersion = "20.03";
}
