{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "jagex-launcher";
  version = "0.1.8";

  src = fetchurl {
    url = "https://rs-launcher-updates.runescape.com/production/linux/x64/releases/${version}/jagex-launcher-beta-linux-x86_64.AppImage";
    hash = "sha512-Ae/w98xt7tHDcANl1k7vqGdt1cVTYhpawN0quydf1WLy6/5JfCCV3zuu58ZT6w7SsqhYfKpKee+a81wZt987AA==";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The launcher downloads RuneLite.AppImage into
  # ~/.local/share/Jagex Launcher/games/runelite/ and execs it. Nested AppImages
  # cannot FUSE-mount inside the bubblewrap FHS env, so make their runtime
  # extract to a temp dir and run from there instead. The variable is inherited
  # by the spawned game client.
  profile = ''
    export APPIMAGE_EXTRACT_AND_RUN=1
  '';

  extraPkgs = pkgs: [
    # shell.openExternal / protocol registration
    pkgs.xdg-utils
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/jagex-launcher.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/jagex-launcher.desktop \
      --replace-fail 'Exec=AppRun %U' 'Exec=${pname} %U'
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/jagex-launcher.png \
      -t $out/share/icons/hicolor/512x512/apps
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Official Jagex Launcher for Old School RuneScape (Linux beta)";
    homepage = "https://oldschool.runescape.com/download";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "jagex-launcher";
  };
}
