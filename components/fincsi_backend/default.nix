{
pkgs ? import (import ./nix/sources.nix {}).nixpkgs {}
}:
let
 poetry2nix = import (pkgs.fetchFromGitHub {
  owner = "nix-community";
  repo = "poetry2nix";
  rev = "2553decbc032504e968312cf0cb76964ca602035"; # https://github.com/nix-community/poetry2nix/releases/tag/2023.11.3993
  sha256 = "sha256-JkbKFAkvCOFmguxH4B18LSBBvcXfOswFfmh8wz/9S/M=";
  }) { inherit pkgs; };
 env = poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    overrides = poetry2nix.defaultPoetryOverrides.extend
      (self: super: {
#        semaphore-bot = super.semaphore-bot.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
#        # https://github.com/nix-community/poetry2nix/issues/568
#        werkzeug = super.werkzeug.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.flit-core ]; });
#        flask = super.flask.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.flit-core ]; });
        django-unicorn = super.django-unicorn.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ self.poetry ]; });
#        psycopg = super.psycopg.overridePythonAttrs (old: { nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
#          pkgs.postgresql.lib # llibpq screwery
#          ]; });
        });
    };
in env // {
  shell = env.env.overrideAttrs (o: {
      buildInputs = with pkgs; [ niv poetry postgresql postgresql.lib ]; 
      });
  newShell = pkgs.mkShell { buildInputs = with pkgs; [ niv poetry ]; };
  }
