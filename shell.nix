{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "bottle-flutter";

  buildInputs = with pkgs; [
    flutter
    gtk3
    pkg-config
    sqlite
    xdg-user-dirs
    clang
    cmake
    ninja
    pcre2
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="$PWD/build/linux/x64/debug/bundle/lib:$PWD/build/linux/x64/release/bundle/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    echo "bottle dev shell — $(flutter --version 2>/dev/null | head -1)"
    echo "dart $(dart --version 2>/dev/null)"
  '';
}
