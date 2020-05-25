{ config, pkgs, ... }: 

# Umm, figure out if
# configClone = ./configuration.nix);
# is enough ;)
let 
  configClone = pkgs.writeText "configuration.nix" (builtins.readFile ./configuration.nix);
  kernelClone = pkgs.writeText "kernel.nix" (builtins.readFile ./kernel.nix);

in

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
    ./configuration.nix
  ];

  sdImage = {
    firmwareSize = 128;
    populateFirmwareCommands = "${config.system.build.installBootLoader} ${config.system.build.toplevel} -d ./firmware";
    populateRootCommands = "mkdir -p ./files/var/empty";
    compressImage = false;
    imageBaseName = "ogfx-nixos-sd-image";
  };


  boot.postBootCommands =
    ''
      mkdir -p /mnt
      mkdir -p /etc/nixos/

      if ! [ -e /etc/nixos/configuration.nix ]; then
        cp ${configClone} /etc/nixos/configuration.nix
      fi

      if ! [ -e /etc/nixos/kernel.nix ]; then
        cp ${kernelClone} /etc/nixos/kernel.nix
      fi
    '';

  nixpkgs.system = "aarch64-linux";
}

