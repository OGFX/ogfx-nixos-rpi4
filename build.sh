nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./ogfx-nixos-sd-card.nix $@
