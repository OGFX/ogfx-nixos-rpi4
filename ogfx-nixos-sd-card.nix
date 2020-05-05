{ pkgs, ... }: 

# Umm, figure out if
# configClone = ./configuration.nix);
# is enough ;)
let configClone = pkgs.writeText "configuration.nix" (builtins.readFile ./configuration.nix);

in

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./configuration.nix
  ];

  boot.postBootCommands =
    ''
      mkdir -p /mnt
      mkdir -p /etc/nixos/

      if ! [ -e /etc/nixos/configuration.nix ]; then
        cp ${configClone} /etc/nixos/configuration.nix
      fi
    '';

  nixpkgs.system = "aarch64-linux";
}

