#TODO persistent logging
#TODO vpn host?
#TODO pinning
#TODO ...probably switch to forgejo, but it seems to be behind upstream
#  https://forgejo.org/faq/ "In October 2022 the domains and trademark of Gitea were transferred to a for-profit company without knowledge or approval of the community.
# Despite writing an open letter,
# the takeover was later confirmed. Forgejo was created as an alternative providing a software forge whose governance further the interest of the general public."

#TODO init container and zfs recv datasets + assert noupstream?

#TODO gitea dev mode
  #systemd.services.gitea.serviceConfig.ExecStart = lib.mkForce "${/home/nixos/gitea/gitea} web --pid /run/gitea/gitea.pid";
  #TODO for frontend dev mode
#systemd.services.gitea.serviceConfig.ProtectSystem = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectHome = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.PrivateTmp = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.PrivateDevices = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.PrivateUsers = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectHostname = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectClock = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectKernelTunables = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectKernelModules = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectKernelLogs = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.ProtectControlGroups = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.RestrictAddressFamilies = lib.mkForce  [ "AF_UNIX AF_INET AF_INET6" ];
#systemd.services.gitea.serviceConfig.LockPersonality = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.MemoryDenyWriteExecute = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.RestrictRealtime = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.RestrictSUIDSGID = lib.mkForce  false;
#systemd.services.gitea.serviceConfig.PrivateMounts = lib.mkForce  false;


#TODO arion doesnt seem to add gc roots so I need to deal with that or export the containers to a registry?
#TODO NOTE in order to run the nested container CI containers, the outer container host needs enough namespace maping to fit what the inner container wants (TODO probably need some kind of impure solution to this to make it more automatic? mostbuilds dontneed many users so ivide the space
# no podman tools will even start if this isnt configured proeprly...maybe this chould/could be relaxed? e.g. podman search should have no requirement for this,..
# The unnested container ends up something like this:
#[podman@8586cb283910:~]$ cat /proc/$$/uid_map 
#         0       1000          1
#         1     100000     655360

#TODO split prod and test volumes or zfs checkpoint them or something

#TODO dunno why this pr wasnt merged or fixed, dhcp shouldnt be running in container; https://github.com/hercules-ci/arion/pull/199


#TODO I always forget that docker and podman always make forwarded ports publicly visible because of the way they bypass the firewall, need a more secure solution for this.
#TODO figure out how dns name resolution is set up https://stackoverflow.com/questions/31149501/how-to-reach-docker-containers-by-name-instead-of-ip-address
{ pkgs, config, ... }:
{
  project.name = "infra";
  enableDefaultNetwork = true;
  docker-compose.volumes = {
    #TODO can make ephemeral? used for requesting and passing actions runner token
    runner-token-share = {};
    testing-postgres = {};
    testing-gitea = {};
    testing-signalbot = {};

    }; #TODO?
#  docker-compose.network = {
#    "${config.project.name}" = {
#        internal = true;
#      };
#    };
  services = {
    #TODO needs retry because it takes time for other services like postgres to (possibly) come back up

    #TODO ...probably switch to forgejo
    #  https://forgejo.org/faq/ "In October 2022 the domains and trademark of Gitea were transferred to a for-profit company without knowledge or approval of the community. Despite writing an open letter,
    # the takeover was later confirmed. Forgejo was created as an alternative providing a software forge whose governance further the interest of the general public."

    gitea = {lib, ...}: {
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        ports = [ "127.0.0.1:4000:64743" ];
        volumes = [
          "runner-token-share:/run/gitea-token-share"
           "testing-gitea:/var/lib/gitea"
          ]; #TODO is there no simpler way to do this? We pass a fifo over a volume to notify the gitea container to generate us a urnner token and send it back over
        };
      #image.enableRecommendedContents = true; # TODO what does this do?
      nixos.useSystemd = true; # Check wrt the podman book about systemd
      nixos.configuration = {config, pkgs, ...}: {
#        boot.tmpOnTmpfs = true; #TODO ?
        boot.tmp.useTmpfs = true;
        system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
        system.stateVersion = "23.05";

        networking.useDHCP = false; #see comment about dhcp above

        #systemd.services.gitea-register-first-admin.serviceConfig = {}; # TODO
        #Add an admin user, set up the signal notification webhook
        # TODO what does this mean? it seems to be wrong "Note: please keep in mind that this should be added after the initial deploy unless services.gitea.useWizard is true as the first registered user will be the administrator if no install wizard is used."
        systemd.services.gitea-init-instance = { #TODO how to cause degraded if service fails?
          after = [ "gitea.service" ];
          wantedBy = [ "gitea.service" ];
          unitConfig = {
            ConditionPathExists = [ "!/var/lib/gitea/gitea-inited-flag" ];
            };
          environment = lib.mkForce config.systemd.services.gitea.environment; #TODO why is there a conflict here??
          serviceConfig = {
            User = config.services.gitea.user;
            Group = config.services.gitea.group;      
            #TODO use some kind of convergent configuration management for this?
            ExecStart = pkgs.writeShellScript "gitea-init" ''
              set -x
              #TODO race condition here probably, db not created yet?
              # Command error: CreateUser: pq: relation "user" does not exist
              sleep 15
              if [[ ! -f /var/lib/gitea/gitea-has-admin ]]; then
                # Add admin user since we have registration off #TODO
                #TODO --access-token flag kinda useless? cant pass scope?
                token=$(
                  ${config.services.gitea.package}/bin/gitea admin user create --username testadmin --password testadmin --email fake@fake.fake --admin --access-token --must-change-password=false |
                    ${pkgs.gawk}/bin/awk 'match($0, /Access token was successfully created... (.*)/, a) { print a[1] } END { if(!a[1]) { exit(1) } };'
                  )
                [ "x$token" == x ] && exit 1
                #TODO technically storing this should be fine since we are already the gitea user?
                # a token we can actually do something with
                token=$(${config.services.gitea.package}/bin/gitea admin user generate-access-token --token-name all n--username testadmin --scopes all --raw)
                echo "$token" > /var/lib/gitea/gitea-has-admin
              else
                token=$(cat /var/lib/gitea/gitea-has-admin)
              fi
              if [[ ! -f /var/lib/gitea/gitea-has-bot-webhook ]]; then
              echo "TODO webhook api is currently broken see https://github.com/go-gitea/gitea/issues/23139"
              #  # dd webhook to the signal bot (though this should probably be separated into a separate module somehow; how do you compose systemd services? - well I guess this can be handled as an orthogonal service
              #  read responseCode < <(${pkgs.curl}/bin/curl -s -X POST -k https://gitea:64743/api/v1/admin/hooks \
              #    -H "Content-Type: application/json" \
              #    -H "Authorization: token $token" \
              #    -d '{"active":true, "branch_filter":"*", "events":["send_everything"], "type":"gitea", "config":{"content_type":"json", "url":"http://signalbot:5000/v1/handle_webhook?payload=", "http_method":"get"}}' |
              #      tail -n 1)
              #  [[ $responseCode =~ 2[0-9]{2} ]] || exit 1 
              #  touch /var/lib/gitea/gitea-has-bot-webhook
              fi
              if [[ ! -f /var/lib/gitea/gitea-has-shell2-webhook ]]; then
              echo "TODO webhook api is currently broken see https://github.com/go-gitea/gitea/issues/23139"
              #  # dd webhook to the signal bot (though this should probably be separated into a separate module somehow; how do you compose systemd services? - well I guess this can be handled as an orthogonal service
              #  read responseCode < <(${pkgs.curl}/bin/curl -s -X POST -k https://gitea:64743/api/v1/admin/hooks \
              #    -H "Content-Type: application/json" \
              #    -H "Authorization: token $token" \
              #    -d '{"active":true, "branch_filter":"*", "events":["send_everything"], "type":"gitea", "config":{"content_type":"json", "url":"http://signalbot:55555/v1/msg?payload=", "http_method":"get"}}' |
              #      tail -n 1)
              #  [[ $responseCode =~ 2[0-9]{2} ]] || exit 1 
              #  touch /var/lib/gitea/gitea-has-shell2-webhook
              fi
              touch /var/lib/gitea/gitea-inited-flag
              '';
            }; # TODO
          };
        #TODO runner test repo

        systemd.services.gitea.path = [ pkgs.bashInteractive ]; # needed otherwise for some reason editing commits in the ui results in an error using /usr/bin/env not being able to find bash    #TODO
        #TODO GITEA_WORK_DIR=/var/lib/gitea /nix/store/2qjl3pba6hnd58z9c57kx2j4icmyrpdw-gitea-1.20.5/bin/gitea admin user create --username testadmin --password testadmin  --email fake@fake.fake
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
              ALLOWED_HOST_LIST = "signalbot";
              };
            actions.ENABLED = true;
            };
          };
        systemd.services.gitea.serviceConfig = {
          RestartSec = 5; #TODO

          #systemd.services.gitea.serviceConfig.ExecStart = lib.mkForce "${/home/nixos/gitea/gitea} web --pid /run/gitea/gitea.pid";
          #TODO for frontend dev mode, i dont remember ever figuring out what here was causing the failure to access home?
          #ProtectSystem = lib.mkForce  false;
          #ProtectHome = lib.mkForce  false;
          #PrivateTmp = lib.mkForce  false;
          #PrivateDevices = lib.mkForce  false;
          #PrivateUsers = lib.mkForce  false;
          #ProtectHostname = lib.mkForce  false;
          #ProtectClock = lib.mkForce  false;
          #ProtectKernelTunables = lib.mkForce  false;
          #ProtectKernelModules = lib.mkForce  false;
          #ProtectKernelLogs = lib.mkForce  false;
          #ProtectControlGroups = lib.mkForce  false;
          #RestrictAddressFamilies = lib.mkForce  [ "AF_UNIX AF_INET AF_INET6" ];
          #LockPersonality = lib.mkForce  false;
          #MemoryDenyWriteExecute = lib.mkForce  false;
          #RestrictRealtime = lib.mkForce  false;
          #RestrictSUIDSGID = lib.mkForce  false;
          #PrivateMounts = lib.mkForce  false;
          };



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
            ext_domain = "p.p2.kolmogorov.space";
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
              ExecStart = "${config.services.gitea.package}/bin/gitea cert --host ${ext_domain},gitea";
              };
            environment = lib.mkForce config.systemd.services.gitea.environment; #TODO why is there a conflict here??
            };

        systemd.services.gitea-runner-token-server = {
          after = [ "gitea.service" ];
          wantedBy = [ "gitea.service" ];
          environment = { inherit (config.systemd.services.gitea.environment) GITEA_WORK_DIR GITEA_CUSTOM; };
          serviceConfig = {
            WorkingDirectory = "/run/gitea-token-share";
            User = config.services.gitea.user;
            Group = config.services.gitea.group;
            ExecStartPre =
              let 
                prescript = pkgs.writeShellScript "prescript" ''
                  #TODO shared filesystem between namespaces so this could be funky?
                  chown "${config.services.gitea.user}":"${config.services.gitea.group}" .
                  '';
              in "!${prescript}";
            ExecStart = pkgs.writeShellScript "token-request-watcher" ''
               set -x #TODO
               [[ ! -p request-flag ]] && { rm request-flag || true ; mkfifo request-flag; }
#               [[ ! -p token ]] && { rm token || true ; mkfifo token; }
               while { sleep 1; true; }; do
                 read -t 2 < request-flag && { printf "TOKEN="; ${config.services.gitea.package}/bin/gitea actions generate-runner-token; } > token
               done
               '';
            };
          };
        };
      };

    postgres = {lib, ...}: {
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        volumes = [ "testing-postgres:/var/lib/postgresql" ];
        };
      nixos.useSystemd = true;
      nixos.configuration.networking.useDHCP = false; #see comment about dhcp above
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
        volumes = [ "runner-token-share:/run/gitea-token-share" ]; #TODO is there no simpler way to do this? We pass a unix socket over a volume to notify the gitea container to generate us a urnner token and send it back over
#        privileged = true; #TODO neede dto work around the oci permissioon denied issue for /proc, wonder if this would have influenced anything else I was debugging
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        capabilities = {
          NET_ADMIN = true;
          NET_RAW = true;
          SYS_PTRACE = true;
          SYS_ADMIN = true; #TODO meh
          }; # Needed here?
        devices = [ "/dev/net/tun" "/dev/fuse" ];
        #TODO do I need a full mkforce here or can I somehow filter the previous entry;alt: since its ordered maybe it can b ordered so the newer podman flag overrides the previous one?
        tmpfs = lib.mkForce [ "/run/wrappers:suid" "/tmp:exec,mode=777,dev" ]; #TODO why does docker mount tmpfs with nodev and everything, is this docuemnted somewhere?
#        volumes = lib.mkForce [ "/sys/fs/cgroup:/sys/fs/cgroup" ]; #TODO need to mount this rw to fix ??
        };
      nixos.useSystemd = true;
      nixos.configuration = {config, lib, ...}: {
        #TODO why did i disable this earlier?
        systemd.services.systemd-logind.enable = lib.mkForce true; # Why does arion disablethis? #TODO dont need with the privileged workaround
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
        networking.useDHCP = false; #see comment about dhcp above

        virtualisation.podman.enable = true;
        virtualisation.podman.dockerCompat = true;
        environment.variables = { DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock"; }; #TODO should I forward the outside socket instead, instead of nesting?
        #users.extraUsers.podman.autoSubUidGidRange = true; #TODO what does this do exactly
        #tODO this is unused because the runner service defaults to gitea-runner?#TODO currently the (nested) rootful podman socket is used
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
          tokenFile = "/run/gitea-token";
#          url = "https://p.p2.kolmogorov.space:64743";
          url = "https://gitea:64743";
          labels = [ "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04" ]; #TODO
          settings = {
            log = { level = "debug"; };
            runner = { insecure = true; };
            container = {
              network = "actnetwork";
              options = "--cap-add=NET_RAW --cap-add=NET_ADMIN";
              };
            };
          }; #todo firewall exception for  aactnetwork interface
  
        systemd.services.gitea-runner-small.serviceConfig.AllowedCPUs=1; #TODO test
        #systemd.services.gitea-runner-small.environment.DOCKER_HOST =  lib.mkForce "unix:///run/user/1000/podman/podman.sock"; #TODO can systemd subst uid?
        #systemd.services.gitea-runner-small.serviceConfig.DynamicUser = lib.mkForce false; #TODO
        #systemd.services.gitea-runner-small.serviceConfig.Group = lib.mkForce "podman"; #TODO
        #systemd.services.gitea-runner-small.serviceConfig.User = lib.mkForce "podman"; #TODO
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

        #TODO instead, do I just need to add this to execstartpre for the runner service?
        systemd.services.gitea-runner-token-client = let runner_service = "gitea-runner-small.service"; in {
          before = [ runner_service ];
          wantedBy = [ runner_service ];
          serviceConfig = {
            WorkingDirectory = "/run/gitea-token-share";
            #TODO figure out user
            #User = "podman";
            #Group = "podman";
            ExecStart = pkgs.writeShellScript "token-request" ''
               ${pkgs.podman}/bin/podman network create actnetwork #TODO put this somewhere else, i just threw it in here
               set -x #TODO
               # hardlink token file
               #[[ ! -f /run/gitea-token ]] && touch /run/gitea-token # neither symlink nor hardlink, need to move
               #TODO cant hardlink  across filesystems
               #ln /var/run/gitea-token token
               #TODO lol symlinking doesnt work because its relative ofc!
               #ln -s /run/gitea-token token
               echo up > request-flag
               #TODO inotify-wait ?
               sleep 1
               [[ $(wc -c token | cut -f 1 -d " ") -eq 0 ]] && exit 1
               ## unlink hardlink
               #rm token
               mv token /run/gitea-token
               '';
            };
          };

        };
      };

    #TODO disable
    #TODO this isnt really necessary
    wormhole = {lib, ...}: {
      service = {
        useHostStore = true;
        };
      nixos = {
        useSystemd = true;
        configuration = {pkgs, ...}: {
          system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
         networking.useDHCP = false; #see comment about dhcp above
          boot.tmp.useTmpfs = true;
          system.stateVersion = "23.05";

          ### TODO at this point i should probably just be using scp...
          # bleh (cannibalized)
          # usage: wormhole --transit-helper=tcp:p.p2.kolmogorov.space:64740 --relay-url=ws://p.p2.kolmogorov.space:64739/v1 send
          #services.magic-wormhole-mailbox-server.enable = true;  
          #systemd.services.magic-wormhole-mailbox-server.serviceConfig.ExecStart =
          #  let
          #    python = pkgs.python3.withPackages (py: [ py.magic-wormhole-mailbox-server py.twisted ]);
          #  in lib.mkForce "${python}/bin/twistd --nodaemon wormhole-mailbox --port=tcp:64738"; 

          # https://github.com/NixOS/nixpkgs/issues/164775 https://github.com/Nebulaworks/nix-garage/pull/74/files
          systemd.services.magic-wormhole-mailbox-server =
            let
              dontCheckPython = drv: drv.overridePythonAttrs (old: { doCheck = false; });
              dataDir = "/var/lib/magic-wormhole-mailbox-server;";
              python = pkgs.python3.withPackages (py: [ (dontCheckPython (py.magic-wormhole-mailbox-server.overridePythonAttrs (o: { patches = []; src = pkgs.fetchFromGitHub { owner = "magic-wormhole"; repo = "magic-wormhole-mailbox-server"; rev = "39672ae95a2635ba9daaba62f483aa75bfd80a22"; sha256 = "pmLZ+ORqq1uF66+MZIOnq3AqPuVSa6HlYGUVJTg89w0="; }; }))) ]);
            in {
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
              DynamicUser = true;
                 ExecStart = "${python}/bin/twistd --nodaemon wormhole-mailbox --port=tcp:64739";
                 WorkingDirectory = dataDir;
                 StateDirectory = baseNameOf dataDir; #TODO probably wrong?
              };
            };

          systemd.services.magic-wormhole-transit-relay =
            let
              dontCheckPython = drv: drv.overridePythonAttrs (old: { doCheck = false; });
              dataDir = "/var/lib/magic-wormhole-transit-relay;";
              python = pkgs.python3.withPackages (py: [ (dontCheckPython (py.magic-wormhole-transit-relay.overridePythonAttrs (o: { src = pkgs.fetchFromGitHub { owner = "magic-wormhole"; repo = "magic-wormhole-transit-relay"; rev = "13ee053411f4532ed0ac23d828c93022b1a0cd4c"; sha256 = "jUHPT/GCLxyqOgQ2Jd2AajCYXRX+c9G/gQF05/vOwAQ="; }; }))) ]); #TODO apparently the server repos havent had releases in ages
            in {
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
               DynamicUser = true;
                 #TODO I dont understand the difference between the port and the websocket port
                 ExecStart = "${python}/bin/twistd --nodaemon transitrelay --port=tcp:64740 --websocket=tcp:64741 --websocket-url=ws://p.p2.kolmogorov.space:64740/"; #TODO
        #         ExecStart = "${python}/bin/twistd --nodaemon transitrelay --port=tcp:64740"; #TODO
                 WorkingDirectory = dataDir;
                StateDirectory = baseNameOf dataDir;
              };
            };

          };
        };
      };

    #TODO if I run this in here doesnt that become chicken and egg?
    # i have to somehow configure this so that the registry gets upgraded at an offset step compared to the other images?
    #TODO alternatively, "which" registry is this? is it for all infra or just production deployment?
    #registry = {};

    #TODO dunno how to use this on a testnet, TODO?
    signalbot = {lib, ...}: {
      service = {
        useHostStore = true; # TODO requires a different variant of deployment?
        #ports = [ "3306:3306" ];
        capabilities = {
          SYS_ADMIN = true; #TODO ; for dynamicuser
          };
        volumes = [ "testing-signalbot:/var/lib/signald" ];
        };
      nixos.useSystemd = true;
#      nixos.configuration.boot.tmpOnTmpfs = true; #TODO ?
      nixos.configuration = {pkgs, config, ...}: {
        system.nssModules = lib.mkForce []; # From the arion docs example, is this needed?
        networking.useDHCP = false; #see comment about dhcp above
        boot.tmp.useTmpfs = true;
        system.stateVersion = "23.05";

        #environ.systemPacages = [ signaldctl signal-cli signal-desktop, & x forwarding out of container or somethign ];

        services.signald.enable = true;
        # TODO services.signald.user = "nixos";
        # fix(ish?) logging for debug
        systemd.services.signald.serviceConfig.BindReadOnlyPaths = ["/run/systemd/journal/socket"];
        systemd.services.signald.serviceConfig.ProtectProc = lib.mkForce "default"; #TODO this is a workaround for when systemd inside the container is starting the service, hidepid somehow breaks things; probably because when run outside a container systemd is running as real root, but inside its not(?) and isnt able to bypass hidpide as fake-root? (so the "(sd-userns)" code doesnt work - search the source)
        systemd.services.signal-message-hook = let
          prochook = pkgs.writeShellScript "prochook.sh" ''
            echo "$@"
            '';
          dataDir = "/var/lib/signal-message-hook";
          #actual gid = "3Ho2kTe4WlVFcjWSAJ7+Mu9rqZbNrj8YBf09YESsVzs=";
          #test
          gid = "l4BGXE5AOs0S9UZOCcMTw3e2b3z8o/Nqy0aEvCM2vII=";
          acct = "+37258976290";
          port = 55555; # dont allow through firewall, internal only.
          in {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.signaldctl pkgs.bashInteractive ];
            serviceConfig = {
              User = config.services.signald.user;
              ExecStart = ''
                ${pkgs.shell2http}/bin/shell2http -include-stderr -show-errors -port ${toString port} -form /v1/msg 'signaldctl -a ${acct} message send ${gid} "$(${prochook} $v_payload)"'
                '';
              WorkingDirectory = dataDir;
              StateDirectory = baseNameOf dataDir;
            };
          };

        systemd.services.signal-message-bot = {
            after = [ "signald.service" ];
            wantedBy = [ "signald.service" ];
            path = [ pkgs.signalBot ]; # TODO is there a point to this if exec needs an abspath anyway?
            environment = {
              SIGNAL_NOTIF_GROUP= "l4BGXE5AOs0S9UZOCcMTw3e2b3z8o/Nqy0aEvCM2vII=";
              SIGNAL_ACCT = "+37258976290";
              XDG_RUNTIME_DIR="/run"; # for the bot to find the socket in tmp/signald
              };
            serviceConfig = {
              RestartSec = 5; #TODO proper retry logic
              #User = config.services.signald.user;
              #TODO proper
              ExecStart = pkgs.writeShellScript "signalbot" ''
                ${pkgs.coreutils}/bin/sleep 10 #TODO race condition with signald socket for some reason
                ${pkgs.signalBot}/bin/python ${../signalbot/bot.py}
                '';
              User = config.services.signald.user;
              WorkingDirectory = "/var/lib/signalBot";
              StateDirectory = "signalBot";
            };
          };

        };
      };
  };
}



