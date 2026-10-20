{
  lib,
  appimageTools,
  asar,
  fetchurl,
  runelite,
}:

let
  pname = "jagex-launcher";
  version = "0.1.8";

  src = fetchurl {
    url = "https://rs-launcher-updates.runescape.com/production/linux/x64/releases/${version}/jagex-launcher-beta-linux-x86_64.AppImage";
    hash = "sha512-Ae/w98xt7tHDcANl1k7vqGdt1cVTYhpawN0quydf1WLy6/5JfCCV3zuu58ZT6w7SsqhYfKpKee+a81wZt987AA==";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;

    # The launcher provisions RuneLite by downloading RuneLite.AppImage into
    # ~/.local/share/Jagex Launcher/games/runelite/ and exec'ing it with
    # JX_SESSION_ID/JX_CHARACTER_ID/JX_DISPLAY_NAME in the environment. Point
    # the install path at the nixpkgs runelite instead and drop the one-time
    # "refresh" migration, which would otherwise try to overwrite the store
    # path. The binary has the onlyLoadAppFromAsar fuse set, so the bundle
    # must be repacked; jszip stays unpacked as upstream ships it.
    postExtract = ''
      cd $out/resources
      ${lib.getExe asar} extract app.asar app
      rm -r app.asar app.asar.unpacked
      substituteInPlace app/node_modules/@app/main/dist/index.js \
        --replace-fail \
          'if (j()) return p(G(), t.linux.clientFolderName, t.linux.fileName);' \
          'if (j()) return e === "runelite" ? "${lib.getExe runelite}" : p(G(), t.linux.clientFolderName, t.linux.fileName);' \
        --replace-fail \
          'if (e !== "runelite") return !1;' \
          'return !1;'
      ${lib.getExe asar} pack app app.asar --unpack-dir node_modules/jszip
      rm -r app
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version src;
  contents = appimageContents;

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
