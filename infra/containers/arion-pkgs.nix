let unstable = import <nixos-unstable> {}; in
import <nixpkgs> {
  system = "x86_64-linux";
  overlays = [ (self: super: {
    _unstable = unstable;
    docker-compose-compat =
      (self.runCommand "podman-compose-docker-compat" {} ''
        mkdir -p $out/bin
        ln -s ${self.podman-compose}/bin/podman-compose $out/bin/docker-compose
        '');
    signald = unstable.signald;
    signal-cli = unstable.signal-cli;
    signaldctl = unstable.signaldctl;

    gitea = unstable.gitea.overrideAttrs (o: {
      #src = lib.cleanSource /home/nixos/gitea;
      postPatch = o.postPatch + ''
        cp -r ${/home/nixos/source/vendored_gitea/gitea/vendor/github.com/tidwall} vendor/github.com/tidwall
        '';
      patches = [
        /home/nixos/source/vendored_gitea/snd/0001-Patch-Gitea-webhook-JSON-to-store-the-webhook-event-.patch 
        /home/nixos/source/vendored_gitea/snd/0002-force-modules.txt.patch
        #TODO wrong patch?
        #/home/nixos/source/vendored_gitea/snd/0003-only-send-webhook-notifications-for-the-last-assigne.patch
        /home/nixos/source/vendored_gitea/snd/0004-Make-assignee-changes-in-the-issue-sidebar-send-requ.patch
        /home/nixos/source/vendored_gitea/snd/0005-fix-clear-assignees-button-not-working-because-of-un.patch
        ];
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
      });

      gitea-actions-runner =
        let runnerConfig = self.writeText "runnerConfig.yaml" ''
          log:
            level: debug
          runner:
            insecure: true
          container:
            network: actnetwork
            options: --cap-add=NET_RAW --cap-add=NET_ADMIN
          ''; #todo firewall exception for  aactnetwork interface
        in self.runCommand "gar-wrap" { buildInputs = [ self.makeWrapper ]; } ''
          mkdir -p "$out/bin"
          makeWrapper ${unstable.gitea-actions-runner}/bin/act_runner "$out"/bin/act_runner \
          --add-flags "-c ${runnerConfig}" 
          '';
    }) ];
  }
