# jagex-launcher-nix

Nix package for the **official** Jagex Launcher for Linux (beta), the Electron
AppImage Jagex ships at <https://oldschool.runescape.com/download>. It installs
RuneLite for you and starts it, so you don't need Bolt.

The launcher is proprietary (`unfree`). This repo only holds the packaging; the
binary is fetched from Jagex's own update server at build time.

## Try it

```sh
nix run github:Kahnix/jagex-launcher-nix
```

The flake's `packages` output allows this one unfree package, so no
`NIXPKGS_ALLOW_UNFREE` is needed.

## NixOS

```nix
{
  inputs.jagex-launcher.url = "github:Kahnix/jagex-launcher-nix";

  outputs = { nixpkgs, jagex-launcher, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ jagex-launcher.overlays.default ];
          nixpkgs.config.allowUnfreePredicate =
            pkg: nixpkgs.lib.getName pkg == "jagex-launcher";
          environment.systemPackages = [ pkgs.jagex-launcher ];
        })
      ];
    };
  };
}
```

Or skip the overlay and use `jagex-launcher.packages.x86_64-linux.default`.

## How it works

- `appimageTools.wrapType2` runs the AppImage in a bubblewrap FHS environment.
- The launcher downloads `RuneLite.AppImage` into
  `~/.local/share/Jagex Launcher/games/runelite/` and executes it. A nested
  AppImage cannot FUSE-mount inside bubblewrap, so the wrapper exports
  `APPIMAGE_EXTRACT_AND_RUN=1`; RuneLite extracts itself to `/tmp` and runs.
- The launcher's built-in self-updater is inert (`APPIMAGE` is unset). Updates
  come through this repo instead: `update.sh` reads Jagex's electron-updater
  feed (`production/latest-linux.yml`), which carries the version and sha512,
  and rewrites `package.nix`. The `update` workflow runs it daily and opens a PR.
- The desktop entry registers the `rshub://` URL scheme the launcher uses.

## Updating manually

```sh
./update.sh
nix build .#default
```
