{
  description = "Official Jagex Launcher (Linux beta) packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "jagex-launcher";
      };
    in
    {
      packages.${system} = {
        jagex-launcher = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.jagex-launcher;
      };

      overlays.default = final: _prev: {
        jagex-launcher = final.callPackage ./package.nix { };
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
