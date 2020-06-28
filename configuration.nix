{ fetchurl, config, lib, pkgs, stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, rpiVersion, ... }:

{
  nixpkgs.overlays = [ ];

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

  boot.consoleLogLevel = lib.mkDefault 7;
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;

  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./kernel.nix { 
    rpiVersion = 4;  
    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
      { 
        name = "4.19.94rt39";
        patch = builtins.fetchurl "https://www.kernel.org/pub/linux/kernel/projects/rt/4.19/older/patch-4.19.94-rt39.patch.xz";
        sha256 = "5vm7dpdaspwyccx2lh6sycfcaaiw1439fpnhypm5cya0ymsnz0fj";
      }
      {
        name = "enable-rt-preempt";
        patch = null;
        extraConfig = ''
          PREEMPT_RT y
	'';
      }
    ];
  });

  networking.hostName = "ogfx";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    vim nano stress
    htop tmux git
    jack2 jalv
    raspberrypi-tools
    guitarix gxplugins-lv2 
    swh_lv2 calf
    mda_lv2 
    mod-distortion  
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
