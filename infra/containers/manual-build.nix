let
  pkgs = import ./arion-pkgs.nix;
  module = import ./arion-compose.nix;
in
  pkgs.arion.build { modules = [ module ]; inherit pkgs; }
