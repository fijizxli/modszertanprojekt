{
pkgs ? import (import ./nix/sources.nix {}).nixpkgs {}
}:
let
 env = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    overrides = pkgs.poetry2nix.defaultPoetryOverrides.extend
      (self: super: {
        semaphore-bot = super.semaphore-bot.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
        # https://github.com/nix-community/poetry2nix/issues/568
        werkzeug = super.werkzeug.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.flit-core ]; });
        flask = super.flask.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.flit-core ]; });
        });
    };
in env // {
  shell = env.env.overrideAttrs (o: {
      buildInputs = with pkgs; [ niv poetry ]; 
      });
  }
