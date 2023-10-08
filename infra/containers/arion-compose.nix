#TODO arion doesnt seem to add gc roots so I need to deal with that or export the containers to a registry?
#TODO NOTE in order to run the nested container CI containers, the outer container host needs enough namespace maping to fit what the inner container wants (TODO probably need some kind of impure solution to this to make it more automatic? mostbuilds dontneed many users so ivide the space
# no podman tools will even start if this isnt configured proeprly...maybe this chould/could be relaxed? e.g. podman search should have no requirement for this,..
# The unnested container ends up something like this:
#[podman@8586cb283910:~]$ cat /proc/$$/uid_map 
#         0       1000          1
#         1     100000     655360


#TODO I always forget that docker and podman always make forwarded ports publicly visible because of the way they bypass the firewall, need a more secure solution for this.
#TODO figure out how dns name resolution is set up https://stackoverflow.com/questions/31149501/how-to-reach-docker-containers-by-name-instead-of-ip-address
{ pkgs, config, ... }:
{
  project.name = "infra";
  services = {
    #TODO needs retry because it takes time for other services like postgres to (possibly) come back up

    #TODO ...probably switch to forgejo
    #  https://forgejo.org/faq/ "In October 2022 the domains and trademark of Gitea were transferred to a for-profit company without knowledge or approval of the community. Despite writing an open letter,
    # the takeover was later confirmed. Forgejo was created as an alternative providing a software forge whose governance further the interest of the general public."

    gitea = {lib, ...}: {
      #image.enableRecommendedContents = true; # TODO what does this do?
      nixos.useSystemd = true; # Check wrt the podman book about systemd
      nixos.configuration = {config, ...}: {
#        boot.tmpOnTmpfs = true; #TODO ?
        boot.tmp.useTmpfs = true;
        system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
        system.stateVersion = "23.05";

        systemd.services.gitea.path = [ pkgs.bashInteractive ]; # needed otherwise for some reason editing commits in the ui results in an error using /usr/bin/env not being able to find bash    #TODO
        services.gitea = {
          enable = true;
          database = {
            createDatabase = false;
            host = "postgres";
            type = "postgres";
            };
          settings = {
            log.LEVEL = "Debug";
            DEFAULT.WORK_PATH = "${config.services.gitea.stateDir}"; # https://github.com/NixOS/nixpkgs/commit/ed02e79bbe031a7ce9cf863660f10d3ef70b8636
            server = {
              ROOT_URL = "https://p.p2.kolmogorov.space:64743/"; #TODO oh geez ok how do I make this work here, case on dev/prod? :/ proxy in front?
              HTTP_PORT = 64743;
              PROTOCOL = "https";
              CERT_FILE = "cert.pem";
              KEY_FILE = "key.pem";
              SSH_PORT = 64744;
              #TODO dev mode, dunno if anything other than public is atually needed
#              STATIC_ROOT_PATH = "${
#                pkgs.linkFarm "gitea-static-files" {
#                  "public" = "/home/nixos/source/vendored_gitea/gitea/public";
#                  "options" = "/home/nixos/source/vendored_gitea/gitea/options";
#                  "templates" = "/home/nixos/source/vendored_gitea/gitea/templates";
#                  }
#                }";
              };
            service = {
              REQUIRE_SIGNIN_VIEW = true;
              DISABLE_REGISTRATION = true;
              SHOW_REGISTRATION_BUTTON = false;
              DISABLE_HTTP_GIT = false; #TODO does this meen http protocol or only allow https?
              };
            webhook = {
              ALLOWED_HOST_LIST = "loopback";
              };
            actions.ENABLED = true;
            };
          };
        systemd.services.gitea.serviceConfig.RestartSec = 5; #TODO

        # #TODO infrec   #TODO uhh timing this
        #  systemd.services.gitea-self-signed = let
        #      domain = "p.p2.kolmogorov.space";
        #    in lib.mkMerge [
        #      (lib.traceValSeq config.systemd.services.gitea)
        #      (lib.mkForce { 
        #         after = [ "gitea.service" ]; #TODO wrong?
        #         wantedBy = [ "gitea.service" ];
        #         serviceConfig = { ExecStart = "${lib.getExe pkgs.gitea} cert --host ${domain}"; };
        #         })
        #      ];   

        systemd.services.gitea-self-signed = let
            domain = "p.p2.kolmogorov.space";
          in {
            after = [ "gitea.service" ]; #TODO wrong?
            wantedBy = [ "gitea.service" ];
            unitConfig = {
              ConditionPathExists = [ "|!${config.services.gitea.customDir}/cert.pem" "|!${config.services.gitea.customDir}/key.pem" ];
              };
            serviceConfig = {
              WorkingDirectory = config.services.gitea.customDir;
              User = config.services.gitea.user;
              Group = config.services.gitea.group;      
              ExecStart = "${config.services.gitea.package}/bin/gitea cert --host ${domain}";
              };
            environment = lib.mkForce config.systemd.services.gitea.environment; #TODO why is there a conflict here??
            };
        };
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = "4000:3000";
        };
      };

    postgres = {lib, ...}: {
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        };
      nixos.useSystemd = true;
      nixos.configuration.boot.tmp.useTmpfs = true;
#      nixos.configuration.boot.tmpOnTmpfs = true; #TODO ?
      nixos.configuration.system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
      nixos.configuration.system.stateVersion = "23.05";
      nixos.configuration.services.postgresql = 
        let
          gitea_conf = config.services.gitea.nixos.evaluatedConfig.services.gitea;
        in { # copied from nixos/modules/services/misc/gitea.nix
          enable = true;
          enableTCPIP = true;
          ensureDatabases = [ gitea_conf.database.name ];
          ensureUsers = [ { #TODO is this going to work across machines? I assume originally this uses the socket remote local user labeling mechanism thing, so it needs to be done some other way
            name = gitea_conf.database.user;
            ensurePermissions = { "DATABASE ${gitea_conf.database.name}" = "ALL PRIVILEGES"; };
            } ];
          # https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
          #TODO doesnt currently work because reverse dns returns stuff in the "wrong" order
          # host 10.89.1.14
          #. domain name pointer infra_gitea_1.
          #. domain name pointer gitea.
          #. domain name pointer bcc66fe1f5f8.
          authentication = ''
            #host gitea gitea gitea trust
            host gitea gitea samenet trust
            '';
          };
      };

#TODO NOTE QUESTION this may reak compatibility with docker, especially messing with the userns stuff? i.e. ends up depending on podman-compose
#TODO this was a bit of a mess, see ModszProj/project/issues/28#issuecomment-405
    act_runner = {lib, ...}: let userns_size = 6553600-65536; in {
      image.enableRecommendedContents = true; # TODO what does this do #TODO still havent looked  into what this does but without it lazydocker is missing tols to drop into a shell with "/bin/sh: line 1: `{cut,id,grep}`: command not found"
      out.service.userns_mode = "auto:size=${toString userns_size}"; #TODO correct? #TODO the podman run documentatio n does not explain this clearly #TODO this entire bit is kinda confusing, per the code the username is ignored but per the docs its left implicit / somewhat misleading. also the size?- is the same size used for both uid and gid?
      service = {
        privileged = true; #TODO neede dto work around the oci permissioon denied issue for /proc, wonder if this would have influenced anything else I was debugging
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        capabilities = {
          NET_ADMIN = true;
          NET_RAW = true;
          SYS_PTRACE = true;
          }; # Needed here?
        devices = [ "/dev/net/tun" "/dev/fuse" ];
        #TODO do I need a full mkforce here or can I somehow filter the previous entry;alt: since its ordered maybe it can b ordered so the newer podman flag overrides the previous one?
        tmpfs = lib.mkForce [ "/run/wrappers:suid" "/tmp:exec,mode=777,dev" ]; #TODO why does docker mount tmpfs with nodev and everything, is this docuemnted somewhere?
#        volumes = lib.mkForce [ "/sys/fs/cgroup:/sys/fs/cgroup" ]; #TODO need to mount this rw to fix ??
        };
      nixos.useSystemd = true;
      nixos.configuration = {config, lib, ...}: {
        #systemd.services.systemd-logind.enable = lib.mkForce true; # Why does arion disablethis? #TODO dont need with the privileged workaround
        # We need to use the patched wrapper on unstable because of https://github.com/NixOS/nixpkgs/issues/42117#issuecomment-974194691 -> https://github.com/NixOS/nixpkgs/pull/231673
        #  which manifests as the following in containerized podman:
        #   WARN[0000] "/" is not a shared mount, this could cause issues or missing mounts with rootless containers 
        #   ERRO[0000] running `/run/wrappers/bin/newuidmap 475 0 1000 1 1 100000 65536`: Assertion `!(st.st_mode & S_ISUID) || (st.st_uid == geteuid())` in NixOS's wrapper.c failed. 
        #   Error: cannot set up namespace using "/run/wrappers/bin/newuidmap": signal: aborted (core dumped)
        # https://nixos.org/manual/nixos/stable/#sec-replace-modules
        disabledModules = [ (pkgs.path + "/nixos/modules/security/wrappers/default.nix") ]; 
        imports = [ (pkgs._unstable.path + "/nixos/modules/security/wrappers/default.nix") ]; #TODO is there a better way to do this?
#        boot.specialFileSystems = lib.mkVMOverride {
#          "${dirOf config.security.wrapperDir}" = { # TODO Working around arion override
#            fsType = "tmpfs";
#            options = [ "nodev" "mode=755" "size=${config.security.wrapperDirSize}" ];
#            };
#          };

#        boot.tmpOnTmpfs = true; #TODO ?
        system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
        virtualisation.podman.enable = true;
        virtualisation.podman.dockerCompat = true;
        environment.variables = { DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock"; }; #TODO should I forward the outside socket instead, instead of nesting?
        #users.extraUsers.podman.autoSubUidGidRange = true; #TODO what does this do exactly
        users.extraUsers.podman.subUidRanges = [
          { count = 999; startUid = 1; } # need to leave a hole for the default user map? (change podman config to simplify this?
          { count = userns_size - 65536 - 1001; startUid = 1001; } ];  #TODO these are too fragile right now, I need to figure out a better way to do this #TODO no idea why I need to subtract 4
        users.extraUsers.podman.subGidRanges = [
          { count = 99; startGid = 1; }
          { count = userns_size - 65536 - 101; startGid = 101; } ];  #TODO i have no idea why any of this works
        users.extraUsers.podman.isNormalUser = true; #TODO does this need the podman --user option or such?
        #TODO only way I managed to get newuidmap and newgidmap to not break in podman, IDK if this is a  security issue
        security.wrappers.newuidmap.setuid = lib.mkForce false;
        security.wrappers.newgidmap.setuid = lib.mkForce false;
        security.wrappers.newuidmap.capabilities = "cap_setuid+eip";
        security.wrappers.newgidmap.capabilities = "cap_setgid+eip";
        system.stateVersion = "23.05";
        boot.tmp.useTmpfs = true;


        #TODO I need to temporarily patch permissions out on this or something because having to readdi it every time is not going to go well
        services.gitea-actions-runner.instances.small = {
          enable = true;
          name = "small";
          token = "fvVAjp8zz1EdaFSOYJAE0EMbEP2NmroGJ4LKbXna"; # TODO single use?
          url = "https://p.p2.kolmogorov.space:64743";
          labels = [ "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04" ]; #TODO
          };    
        systemd.services.gitea-runner-small.serviceConfig.AllowedCPUs=1; #TODO test
        #  systemd.services.gitea-runner-small.environment.CONTAINERS_REGISTRIES_CONF = pkgs.writeText "registries.conf" ''
        #      unqualified-search-registries = ["localhost:5001"]
        #      [[registry]]
        #      prefix = "docker.io/library"
        #      location = "localhost:5001"
        #      insecure = true
        #      '';

        #  systemd.services.gitea-runner-small.serviceConfig.ExecStart = 
        #    let
        #    in lib.mkForce "${config.services.gitea-actions-runner.package}/bin/act_runner daemon -c ${runnerConfig}";
        };
      };

    #TODO dunno how to use this on a testnet, TODO?
    signalbot = {lib, ...}: {
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        };
      nixos.useSystemd = true;
#      nixos.configuration.boot.tmpOnTmpfs = true; #TODO ?
      nixos.configuration.system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
      nixos.configuration.boot.tmp.useTmpfs = true;
      nixos.configuration.system.stateVersion = "23.05";
      
      };
  };
}


