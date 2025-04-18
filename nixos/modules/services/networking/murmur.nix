{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.murmur;
  forking = cfg.logFile != null;
  configFile = pkgs.writeText "murmurd.ini" ''
    database=${cfg.stateDir}/murmur.sqlite
    dbDriver=QSQLITE

    autobanAttempts=${toString cfg.autobanAttempts}
    autobanTimeframe=${toString cfg.autobanTimeframe}
    autobanTime=${toString cfg.autobanTime}

    logfile=${optionalString (cfg.logFile != null) cfg.logFile}
    ${optionalString forking "pidfile=/run/murmur/murmurd.pid"}

    welcometext="${cfg.welcometext}"
    port=${toString cfg.port}

    ${optionalString (cfg.hostName != "") "host=${cfg.hostName}"}
    ${optionalString (cfg.password != "") "serverpassword=${cfg.password}"}

    bandwidth=${toString cfg.bandwidth}
    users=${toString cfg.users}

    textmessagelength=${toString cfg.textMsgLength}
    imagemessagelength=${toString cfg.imgMsgLength}
    allowhtml=${boolToString cfg.allowHtml}
    logdays=${toString cfg.logDays}
    bonjour=${boolToString cfg.bonjour}
    sendversion=${boolToString cfg.sendVersion}

    ${optionalString (cfg.registerName != "") "registerName=${cfg.registerName}"}
    ${optionalString (cfg.registerPassword != "") "registerPassword=${cfg.registerPassword}"}
    ${optionalString (cfg.registerUrl != "") "registerUrl=${cfg.registerUrl}"}
    ${optionalString (cfg.registerHostname != "") "registerHostname=${cfg.registerHostname}"}

    certrequired=${boolToString cfg.clientCertRequired}
    ${optionalString (cfg.sslCert != "") "sslCert=${cfg.sslCert}"}
    ${optionalString (cfg.sslKey != "") "sslKey=${cfg.sslKey}"}
    ${optionalString (cfg.sslCa != "") "sslCA=${cfg.sslCa}"}

    ${optionalString (cfg.dbus != null) "dbus=${cfg.dbus}"}

    ${cfg.extraConfig}
  '';
in
{
  imports = [
    (mkRenamedOptionModule [ "services" "murmur" "welcome" ] [ "services" "murmur" "welcometext" ])
    (mkRemovedOptionModule [ "services" "murmur" "pidfile" ] "Hardcoded to /run/murmur/murmurd.pid now")
  ];

  options = {
    services.murmur = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "If enabled, start the Murmur Mumble server.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open ports in the firewall for the Murmur Mumble server.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "murmur";
        description = ''
          The name of an existing user to use to run the service.
          If not specified, the default user will be created.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "murmur";
        description = ''
          The name of an existing group to use to run the service.
          If not specified, the default group will be created.
        '';
      };

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/murmur";
        description = ''
          Directory to store data for the server.
        '';
      };

      autobanAttempts = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Number of attempts a client is allowed to make in
          `autobanTimeframe` seconds, before being
          banned for `autobanTime`.
        '';
      };

      autobanTimeframe = mkOption {
        type = types.int;
        default = 120;
        description = ''
          Timeframe in which a client can connect without being banned
          for repeated attempts (in seconds).
        '';
      };

      autobanTime = mkOption {
        type = types.int;
        default = 300;
        description = "The amount of time an IP ban lasts (in seconds).";
      };

      logFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/log/murmur/murmurd.log";
        description = "Path to the log file for Murmur daemon. Empty means log to journald.";
      };

      welcometext = mkOption {
        type = types.str;
        default = "";
        description = "Welcome message for connected clients.";
      };

      port = mkOption {
        type = types.port;
        default = 64738;
        description = "Ports to bind to (UDP and TCP).";
      };

      hostName = mkOption {
        type = types.str;
        default = "";
        description = "Host to bind to. Defaults binding on all addresses.";
      };

      package = mkPackageOption pkgs "murmur" { };

      password = mkOption {
        type = types.str;
        default = "";
        description = "Required password to join server, if specified.";
      };

      bandwidth = mkOption {
        type = types.int;
        default = 72000;
        description = ''
          Maximum bandwidth (in bits per second) that clients may send
          speech at.
        '';
      };

      users = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum number of concurrent clients allowed.";
      };

      textMsgLength = mkOption {
        type = types.int;
        default = 5000;
        description = "Max length of text messages. Set 0 for no limit.";
      };

      imgMsgLength = mkOption {
        type = types.int;
        default = 131072;
        description = "Max length of image messages. Set 0 for no limit.";
      };

      allowHtml = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Allow HTML in client messages, comments, and channel
          descriptions.
        '';
      };

      logDays = mkOption {
        type = types.int;
        default = 31;
        description = ''
          How long to store RPC logs for in the database. Set 0 to
          keep logs forever, or -1 to disable DB logging.
        '';
      };

      bonjour = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Bonjour auto-discovery, which allows clients over
          your LAN to automatically discover Murmur servers.
        '';
      };

      sendVersion = mkOption {
        type = types.bool;
        default = true;
        description = "Send Murmur version in UDP response.";
      };

      registerName = mkOption {
        type = types.str;
        default = "";
        description = ''
          Public server registration name, and also the name of the
          Root channel. Even if you don't publicly register your
          server, you probably still want to set this.
        '';
      };

      registerPassword = mkOption {
        type = types.str;
        default = "";
        description = ''
          Public server registry password, used authenticate your
          server to the registry to prevent impersonation; required for
          subsequent registry updates.
        '';
      };

      registerUrl = mkOption {
        type = types.str;
        default = "";
        description = "URL website for your server.";
      };

      registerHostname = mkOption {
        type = types.str;
        default = "";
        description = ''
          DNS hostname where your server can be reached. This is only
          needed if you want your server to be accessed by its
          hostname and not IP - but the name *must* resolve on the
          internet properly.
        '';
      };

      clientCertRequired = mkOption {
        type = types.bool;
        default = false;
        description = "Require clients to authenticate via certificates.";
      };

      sslCert = mkOption {
        type = types.str;
        default = "";
        description = "Path to your SSL certificate.";
      };

      sslKey = mkOption {
        type = types.str;
        default = "";
        description = "Path to your SSL key.";
      };

      sslCa = mkOption {
        type = types.str;
        default = "";
        description = "Path to your SSL CA certificate.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration to put into murmur.ini.";
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression ''"''${config.services.murmur.stateDir}/murmurd.env"'';
        description = ''
          Environment file as defined in {manpage}`systemd.exec(5)`.

          Secrets may be passed to the service without adding them to the world-readable
          Nix store, by specifying placeholder variables as the option value in Nix and
          setting these variables accordingly in the environment file.

          ```
            # snippet of murmur-related config
            services.murmur.password = "$MURMURD_PASSWORD";
          ```

          ```
            # content of the environment file
            MURMURD_PASSWORD=verysecretpassword
          ```

          Note that this file needs to be available on the host on which
          `murmur` is running.
        '';
      };

      dbus = mkOption {
        type = types.enum [
          null
          "session"
          "system"
        ];
        default = null;
        description = "Enable D-Bus remote control. Set to the bus you want Murmur to connect to.";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.murmur = mkIf (cfg.user == "murmur") {
      description = "Murmur Service user";
      home = cfg.stateDir;
      createHome = true;
      uid = config.ids.uids.murmur;
      group = cfg.group;
    };
    users.groups.murmur = mkIf (cfg.group == "murmur") {
      gid = config.ids.gids.murmur;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };

    systemd.services.murmur = {
      description = "Murmur Chat Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        ${pkgs.envsubst}/bin/envsubst \
          -o /run/murmur/murmurd.ini \
          -i ${configFile}
      '';

      serviceConfig = {
        # murmurd doesn't fork when logging to the console.
        Type = if forking then "forking" else "simple";
        PIDFile = mkIf forking "/run/murmur/murmurd.pid";
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = "${cfg.package}/bin/mumble-server -ini /run/murmur/murmurd.ini";
        Restart = "always";
        RuntimeDirectory = "murmur";
        RuntimeDirectoryMode = "0700";
        User = cfg.user;
        Group = cfg.group;

        # service hardening
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        RestrictAddressFamilies = "~AF_PACKET AF_NETLINK";
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
        UMask = 27;
      };
    };

    # currently not included in upstream package, addition requested at
    # https://github.com/mumble-voip/mumble/issues/6078
    services.dbus.packages = mkIf (cfg.dbus == "system") [
      (pkgs.writeTextFile {
        name = "murmur-dbus-policy";
        text = ''
          <!DOCTYPE busconfig PUBLIC
            "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
            "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
          <busconfig>
            <policy user="${cfg.user}">
              <allow own="net.sourceforge.mumble.murmur"/>
            </policy>

            <policy context="default">
              <allow send_destination="net.sourceforge.mumble.murmur"/>
              <allow receive_sender="net.sourceforge.mumble.murmur"/>
            </policy>
          </busconfig>
        '';
        destination = "/share/dbus-1/system.d/murmur.conf";
      })
    ];

    security.apparmor.policies."bin.mumble-server".profile =
      ''
        include <tunables/global>

        ${cfg.package}/bin/{mumble-server,.mumble-server-wrapped} {
          include <abstractions/base>
          include <abstractions/nameservice>
          include <abstractions/ssl_certs>
          include "${pkgs.apparmorRulesFromClosure { name = "mumble-server"; } cfg.package}"
          pix ${cfg.package}/bin/.mumble-server-wrapped,

          r ${config.environment.etc."os-release".source},
          r ${config.environment.etc."lsb-release".source},
          owner rwk ${cfg.stateDir}/murmur.sqlite,
          owner rw ${cfg.stateDir}/murmur.sqlite-journal,
          owner r ${cfg.stateDir}/,
          r /run/murmur/murmurd.pid,
          r /run/murmur/murmurd.ini,
          r ${configFile},
      ''
      + optionalString (cfg.logFile != null) ''
        rw ${cfg.logFile},
      ''
      + optionalString (cfg.sslCert != "") ''
        r ${cfg.sslCert},
      ''
      + optionalString (cfg.sslKey != "") ''
        r ${cfg.sslKey},
      ''
      + optionalString (cfg.sslCa != "") ''
        r ${cfg.sslCa},
      ''
      + optionalString (cfg.dbus != null) ''
        dbus bus=${cfg.dbus}
      ''
      + ''
        }
      '';
  };

  meta.maintainers = with lib.maintainers; [ felixsinger ];
}
