# jagex-launcher-nix

Nix flake for the official [Jagex Launcher for Linux](https://oldschool.runescape.com/download)
(beta). Log in with a Jagex Account and play Old School RuneScape through
RuneLite, no Bolt needed.

The launcher is unfree. This repo contains only the Nix expression; the
AppImage is downloaded from Jagex's update server at build time and is not
redistributed.

## Try it

```sh
nix run github:Kahnix/jagex-launcher-nix
```

## NixOS

```nix
# flake.nix
inputs.jagex-launcher = {
  url = "github:Kahnix/jagex-launcher-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# a NixOS module, with `inputs` passed via specialArgs
{ inputs, lib, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.jagex-launcher.overlays.default ];
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "jagex-launcher";
  environment.systemPackages = [ pkgs.jagex-launcher ];
}
```

For Home Manager, use `home.packages` instead. To pick up a new launcher
release: `nix flake update jagex-launcher`.

## Notes

- Runs in an FHS environment via `appimageTools.wrapAppImage`.
- Upstream, "Play Now" downloads `RuneLite.AppImage` and executes it. This
  package patches the launcher's bundle to run nixpkgs `runelite` instead, so
  nothing is downloaded and no nested AppImage is involved. Override with
  `jagex-launcher.override { runelite = …; }` to use a different build.
- The patch is two string substitutions on minified code, guarded with
  `--replace-fail`: a launcher update that moves them fails the build rather
  than silently falling back to the download path.
- The launcher's self-updater does nothing outside an AppImage. Versions are
  bumped here instead: `update.sh` reads Jagex's `latest-linux.yml` feed, and
  a daily workflow opens a PR when it changes.
- x86_64-linux only, since that is the only build Jagex publishes.

RuneScape support in the launcher hasn't shipped on Linux yet; only OSRS via
RuneLite is tested.

## Troubleshooting

**Web login finishes in the browser but the launcher never logs in.** The
browser hands the result back through an `rshub://` link. The first time,
Firefox asks whether to open it with Jagex Launcher; if that prompt is missed
or dismissed, nothing happens. Retry and allow it (tick "always"), or use the
in-app login. Check the handler is registered with
`xdg-mime query default x-scheme-handler/rshub`, which should print
`jagex-launcher.desktop`.

**RuneLite paints at its initial size and the rest of the window is black**
(Hyprland, Sway, other non-reparenting compositors). nixpkgs `runelite` runs
on OpenJDK 21 under XWayland, and AWT does not pick up resizes there without
`_JAVA_AWT_WM_NONREPARENTING=1`. Set it in your session environment, e.g.
`environment.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";`, and log
back in. The upstream AppImage hides this because it bundles its own JDK 17.
