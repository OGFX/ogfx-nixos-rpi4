{ lib, config, pkgs, ... }: 

let 
  configClones = [ ./configuration.nix ./kernel.nix ./usb-lowlatency.diff ];
  userClones = [ /home/ogfx/ogfx/ogfx-tools /home/ogfx/ogfx/ogfx-ui /home/ogfx/ogfx/ogfx-nixos-rpi4 /home/ogfx/jack2 ];
in

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
    ./configuration.nix
  ];

  sdImage = {
    firmwareSize = 256;
    populateFirmwareCommands = "${config.system.build.installBootLoader} ${config.system.build.toplevel} -d ./firmware";
    populateRootCommands = "mkdir -p ./files/var/empty";
    compressImage = false;
    imageBaseName = "ogfx-nixos-sd-image";
  };


  boot.postBootCommands =
    ''
      mkdir -p /mnt
      mkdir -p /etc/nixos/

      if ! [ -e /etc/nixos/initial_copy_done ]; then
    '' 
        + (lib.concatMapStrings (s:"cp ${s} /etc/nixos/$(basename ${(builtins.toString s)}); ") configClones) +
    ''
        mkdir -p /home/ogfx/ogfx/
    '' 
        + (lib.concatMapStrings (s:"cp -r ${s} ${builtins.toString s}; ") userClones) +
    ''
      fi
      touch /etc/nixos/initial_copy_done
     '';

  nixpkgs.system = "aarch64-linux";
}

