# ogfx-nixos-rpi4

A set of nix expressions and a shell script to build a nixos sd card image 
containing an ogfx system

# How to use

This has been tested with NixOS 20.03.

Prerequisites:

* If you're building on an x86 system add this to your <code>/etc/nixos/configuration.nix</code>:
  
  <code>
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  </code>

After meeting the prerequisites go ahead an execute:

  <code>
  nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./ogfx-nixos-sd-card.nix
  </code>

