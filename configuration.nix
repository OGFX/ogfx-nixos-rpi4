{ fetchurl, config, lib, pkgs, stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, rpiVersion, ... }:

{
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

  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;

  hardware.enableRedistributableFirmware = true;

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

  boot.consoleLogLevel = lib.mkDefault 7;

  fonts.fontconfig.enable = false;

  hardware.bluetooth.enable = false;

  powerManagement.cpuFreqGovernor = "performance";

  programs.command-not-found.enable = false;

  security.polkit.enable = false;

  environment.variables = {
    LV2_PATH = "/nix/var/nix/profiles/system/sw/lib/lv2/";
  };


  services.dnsmasq.enable = true;
  services.dnsmasq.extraConfig = ''
    # Bind to only one interface
    bind-interfaces

    # Choose interface for binding
    interface=wlan0

    # Specify range of IP addresses for DHCP leasses
    dhcp-range=192.168.150.100,192.168.150.200
  '';

  services.hostapd.enable = true;
  services.hostapd.interface = "wlan0";
  services.hostapd.ssid = "ogfx";
  services.hostapd.wpaPassphrase = "omg ogfx";

  networking.interfaces.wlan0.ipv4.addresses = [ { address = "192.168.150.1"; prefixLength = 24; } ];

  networking.hostName = "ogfx";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.networkmanager.enable = true;

  # Disable firewall to make dnsmasq and hostapd work.
  # This needs fixing :)
  networking.firewall.enable = false;

  networking.localCommands = ''
    echo 1 > /proc/sys/net/ipv4/ip_forward
    ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ${pkgs.iptables}/bin/iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    ${pkgs.iptables}/bin/iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
  '';

  networking.networkmanager.extraConfig = ''
    [keyfile]
    unmanaged-devices=interface-name:wlan0
  '';

  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    iptables
    raspberrypi-tools
    vim nano stress
    htop tmux git

    jack2 jalv lilv lv2
    guitarix gxplugins-lv2 
    swh_lv2 calf
    mda_lv2 
    mod-distortion  

    ogfx-tools
    ogfx-ui
  ];

  # These packages would be nice to have, but they
  # don't build on aarch64-linux yet:
  # 
  # mod-distortion mda_lv2 infamousPlugins
  # gxmatcheq-lv2 eq10q bshapr fomp rkrlv2
  # zam-plugins 

  services.xserver.enable = false;

  sound.enable = true;

  # Change "hw:USB" to the name of the ALSA pcm device of your
  # soundcard (see e.g. /proc/asound/cards)
  services.jack = {
    jackd = {
      enable = true;
      extraOptions = [ "-R" "-P 80" "-d" "alsa" "-d" "hw:USB" ];
    };
  };

  users.users.ogfx = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "jackaudio"];
    initialHashedPassword = "$6$ebhWmP8YjP5H$s/buwRq3YWf1QCSe/jMhybOGfnp1u0S4wysSt5dLuvIKIg966kszvMTC7CCuZ/GxiMkzpxGBwqg66H145nX5D/";
  };

  system.stateVersion = "20.03";
}
