let
#TODO ugh ok so why isnt nix-shell -A workwing here?
  unstable = import (import ./nix/sources.nix).nixpkgs-unstable { overlays = [ unst_overlay ]; }; 
  nixpkgs = import (import ./nix/sources.nix).nixpkgs;
  # fixes https://github.com/hercules-ci/arion/issues/217 "You're using a version of Nixpkgs that doesn't support the includeStorePaths parameter"
  _nixpkgs = nixpkgs {};
  nixpkgs-patched = import (_nixpkgs.applyPatches { src = _nixpkgs.path; patches = [
    ./0001-Revert-dockerTools-use-makeOverridable-for-buildImag.patch
    #(_nixpkgs.fetchpatch {
    #  name = "fix-arion-cache.patch"; #TODO rename / wait for upstream merge
    #  url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/260535.patch";
    #  sha256 = "sha256-Y53NkswYBrdvYw5wwxLCqI4y/dIPV8pzMarg96sK1kc=";
    #  })
    ]; });
  unst_overlay = (self: super: {
    _unstable = unstable;
    docker-compose-compat =
      (self.runCommand "podman-compose-docker-compat" {} ''
        mkdir -p $out/bin
        ln -s ${self.podman-compose}/bin/podman-compose $out/bin/docker-compose
        '');

    #TODO the arion nixpkgs expression embeds a reference to docker-compose_1
    arion = (super.arion.overrideAttrs (o: { #TODO this should be an input to arion not usign pkgs or whatever it did... (why even?)
      postInstall = ''
        mkdir -p $out/libexec
        mv $out/bin/arion $out/libexec
        makeWrapper $out/libexec/arion $out/bin/arion \
          --unset PYTHONPATH \
          --prefix PATH : ${self.lib.makeBinPath [ self.docker-compose-compat ]} \
          ;
        '';
      }));
    });
  overlay = (self: super: {
    docker-compose-compat =
      (self.runCommand "podman-compose-docker-compat" {} ''
        mkdir -p $out/bin
        ln -s ${self.podman-compose}/bin/podman-compose $out/bin/docker-compose
        '');
    _unstable = unstable;
    
    signald = unstable.signald;
    signal-cli = unstable.signal-cli;
    signaldctl = unstable.signaldctl;

    signalBot = import ../signalbot {pkgs= self;}; #TODO fix up pinning and pinning propagation

    gitea = (self.runCommand "gitea" { buildInputs = [ self.makeWrapper ]; } ''
      mkdir -p $out/{bin,data}

      cp -R ${self.gitea-backend.data}/{templates,options} ${self.gitea-frontend}/public $out/data

      makeWrapper ${self.gitea-backend}/bin/gitea $out/bin/gitea \
        --add-flags "--work-path $out/data"
      '') // { data = self.gitea + "/data"; };
    #TODO slightly cannibalized from upstream nixpkgs forjego whatever its called
#    gitea-frontend = self.callPackage ../vendor/gitea/default.nix {};
#TODO upstream: found this, why wasnt it portd to gitea https://github.com/emilylange/nixpkgs/blob/254180d5089523bfe9011b510df13981b263296e/pkgs/applications/version-management/forgejo/default.nix
    gitea-frontend = self.buildNpmPackage {
      pname = "gitea-frontend";
      version = "v1.20.5-patched";

      src = self.lib.cleanSource ../vendor/gitea;

      # via prefetch-npm-deps
      npmDepsHash = "sha256-YZzVw+WWqTmJafqnZ5vrzb7P6V4DTMNQwW1/+wvZEM8=";

      # gitea uses npx webpack to build
      patches = [
        #(self.path + "/pkgs/applications/version-management/forgejo/package-json-npm-build-frontend.patch")
        (self.writeText "patch-build-script" ''
          diff --git a/package.json b/package.json
          index 57dcfc2f7..c9f23dbf7 100644
          --- a/package.json
          +++ b/package.json
          @@ -79,5 +79,8 @@
               "defaults",
               "not ie > 0",
               "not ie_mob > 0"
          -  ]
          +  ],
          +  "scripts": {
          +    "build": "node_modules/.bin/webpack"
          +  }
           }
          '')
        ];

      # override npmInstallHook
      installPhase = ''
        mkdir $out
        cp -R ./public $out/
        '';
      };

    # TODO overriding go packages is insane
    gitea-backend = (unstable.callPackage "${unstable.path}/pkgs/applications/version-management/gitea" {
      buildGoModule = args: unstable.buildGoModule (args // {
        patches = []; # remove the static work path patch so that we can use env var in merger package
        postPatch = ""; #TODO wtf?
        #TODO since we are using a vanilla repo not an upstream tar dist, we dont have a vendor dir so we need to FOD        
        vendorHash = "sha256-wsP0svEYc7+IFjsZJGo8J/LxdqZpc34dsahgN6CgJck=";
        postInstall = ''
          mkdir $data
          cp -R ./{templates,options} $data
          mkdir -p $out
          cp -R ./options/locale $out/locale

          wrapProgram $out/bin/gitea \
            --prefix PATH : ${self.lib.makeBinPath (with self; [ bash git gzip openssh ])}
          '';
        #src = self.lib.cleanSource ../vendor/gitea;
        src = self.lib.cleanSourceWith { filter = (path: _: builtins.match ".*/web_src*/.*" path == null); src = self.lib.cleanSource ../vendor/gitea; };
        });  
      });
#    .overrideAttrs (o: {
#      postPatch = o.postPatch + ''
#        cp -r ${/home/nixos/source/vendored_gitea/gitea/vendor/github.com/tidwall} vendor/github.com/tidwall
#        '';
#      patches = [
#        /home/nixos/source/vendored_gitea/snd/0001-Patch-Gitea-webhook-JSON-to-store-the-webhook-event-.patch 
#        /home/nixos/source/vendored_gitea/snd/0002-force-modules.txt.patch
#        #TODO wrong patch?
#        #/home/nixos/source/vendored_gitea/snd/0003-only-send-webhook-notifications-for-the-last-assigne.patch
#        /home/nixos/source/vendored_gitea/snd/0004-Make-assignee-changes-in-the-issue-sidebar-send-requ.patch
#        /home/nixos/source/vendored_gitea/snd/0005-fix-clear-assignees-button-not-working-because-of-un.patch
#        ];
        #substituteInPlace modules/setting/server.go --subst-var data
        #Dont need this to patch $data, use static_root_path
        #data=/etc/giteafrontend
        #substituteInPlace modules/setting/server.go --subst-var data
        ##TODO compile gitea frontend ourselves
        ##TODO can I somehow rebuild the frontend without causing a whole backend rebuild
        #rm -rf public templates options
        #cp -r ${/home/nixos/source/vendored_gitea/gitea}/{public,templates,options} ./
      #Dont need this to patch $data, use static_root_path
      #outputs = ["out"];
      #postInstall = ''
      #  mkdir -p $out
      #  cp -R ./options/locale $out/locale
      #
      #  wrapProgram $out/bin/gitea \
      #    --prefix PATH : ${lib.makeBinPath (with pkgs; [ bash coreutils git gzip openssh ])}
      # '';
#      });

#TODO not needed on unstable for runtime config, but the hack is still needed because the module doesnt use the config for register...
      #TODO this should be in arion-compose, its misleading
      gitea-actions-runner =
        let runnerConfig = self.writeText "runnerConfig.yaml" ''
          log:
            level: debug
          runner:
            insecure: true
          ''; #todo firewall exception for  aactnetwork interface
        in self.writeShellScriptBin "act_runner" ''
          if [[ "$1" = "register" ]]; then
            shift
            ${unstable.gitea-actions-runner}/bin/act_runner register -c "${runnerConfig}" "$@"
          else
            ${unstable.gitea-actions-runner}/bin/act_runner "$@"
          fi
          '';
# self.runCommand "gar-wrap" { buildInputs = [ self.makeWrapper ]; } ''
#          mkdir -p "$out/bin"
#          makeWrapper ${unstable.gitea-actions-runner}/bin/act_runner "$out"/bin/act_runner \
#          --add-flags "-c ${runnerConfig}" 
#          '';
    });
in
nixpkgs-patched {
  system = "x86_64-linux";
  overlays = [ overlay ];
  }

