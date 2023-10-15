#! /usr/bin/env -S nix-shell -v 
#The above is my usual nix-shell for nix hack, which I forgot why, breaks nix-shell devShell.nix type invocation
let
  pkgs = import ./arion-pkgs.nix;
in pkgs.mkShell {
  buildInputs = with pkgs._unstable; [ skopeo arion ];
  }
