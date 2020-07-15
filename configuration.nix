{ config, lib, pkgs, ... }:

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

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = false;
  };

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi.enable = true;
      raspberryPi.version = 4;
    };

    kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./kernel.nix {
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
          name = "usb-lowlatency";
          patch = ./usb-lowlatency.diff;
          sha256 = "5vm7dpdaspwyccx2lh6sycfcaaiw1439fpnhypm5cya0ymsnz0fj";
        }
      ];
      extraConfig = ''
        PREEMPT_RT_FULL y
      '';
    });
  
    extraModprobeConfig = ''
      options snd-usb-audio max_packs=1 max_packs_hs=1 max_urbs=12 sync_urbs=4 max_queue=1
    '';

    consoleLogLevel = lib.mkDefault 7;
    enableContainers = false;
  };
 
  powerManagement.cpuFreqGovernor = "performance";

  fonts.fontconfig.enable = false;

  programs.command-not-found.enable = false;

  security.polkit.enable = false;

  networking = {
    interfaces.wlan0.ipv4.addresses = [ { address = "192.168.150.1"; prefixLength = 24; } ];
    interfaces.eth0.useDHCP = true;

    hostName = "ogfx";
    useDHCP = false;
    networkmanager.enable = true;

    # Disable firewall to make dnsmasq and hostapd work.
    # This needs fixing :)
    firewall.enable = false;

    localCommands = ''
      echo 1 > /proc/sys/net/ipv4/ip_forward
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 
      ${pkgs.iptables}/bin/iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT 
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
    '';

    networkmanager.extraConfig = ''
      [keyfile]
      unmanaged-devices=interface-name:wlan0
    '';
  };

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  sound.enable = true;

  services = {
    dnsmasq = {
      enable = true;
      extraConfig = ''
        # Bind to only one interface
        bind-interfaces

        # Choose interface for binding
        interface=wlan0

        # Specify range of IP addresses for DHCP leasses
        dhcp-range=192.168.150.100,192.168.150.200
      ''; 
    };

    hostapd = {
      enable = true;
      interface = "wlan0";
      ssid = "ogfx";
      wpaPassphrase = "omg it's fx";
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
    };

    xserver.enable = false;

    jack = {
      jackd = {
        enable = true;
        extraOptions = [ "-R" "-P 80" "-d" "alsa" "-p" "128" "-n" "2" "-d" "hw:iXR" ];
      };
    };

    cron = {
      enable = true;
      systemCronJobs = [
        "02 6 * * *  root . /etc/profile; bash /etc/nixos/borg-backup.sh >> /tmp/borg-backup.log 2>&1"
      ];
    };
  };

  systemd.services.ogfx-frontend = {
    enable = true;
    description = "The OGFX web frontend";
    wantedBy = [ "jack" ];
    serviceConfig = {
      Type = "exec";
      User="ogfx";
      ExecStart = "${pkgs.bash}/bin/bash -l -c \". /etc/profile; ${pkgs.jack2}/bin/jack_wait -w; ${pkgs.ogfx-ui}/bin/ogfx_frontend_server.py\"";
      # PAMName="ogfx";
      LimitRTPRIO = 99;
      LimitMEMLOCK = "infinity";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    nano
    htop
    tmux
    wirelesstools
    usbutils
    iptables
    gdb
    raspberrypi-tools

    borgbackup 

    jalv
    lv2
    lilv
    
    guitarix
    gxplugins-lv2
    swh_lv2
    calf
    mda_lv2
    rkrlv2
    mod-distortion
    gxmatcheq-lv2
    zam-plugins
    fomp
    infamousPlugins

    ogfx-tools
    ogfx-ui
  ];
  #  eq10q bshapr 

  environment.variables = { 
    LV2_PATH = "/nix/var/nix/profiles/system/sw/lib/lv2/"; 
  };

  users.users.ogfx = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "jackaudio" "audio" ];
    initialHashedPassword = "$6$ebhWmP8YjP5H$s/buwRq3YWf1QCSe/jMhybOGfnp1u0S4wysSt5dLuvIKIg966kszvMTC7CCuZ/GxiMkzpxGBwqg66H145nX5D/";
  };

  system.stateVersion = "20.03";
}
