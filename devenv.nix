{ pkgs, lib, config, ... }: {
  # Disable automatic cachix cache management (not a trusted user)
  cachix.enable = false;

  android = {
    enable = true;
    flutter.enable = true;

    # Physical device only, no need for emulator or system images
    emulator.enable = false;
    systemImages.enable = false;
  };

  # Additional packages for development
  packages = [
    pkgs.curl
  ];

  env.FLUTTER_SDK = "${pkgs.flutter}";

  enterShell = ''
    echo "Flutter Android development environment"
    echo "  Flutter: $(flutter --version 2>/dev/null | head -1)"
    echo "  Dart:    $(dart --version 2>/dev/null)"
    echo "  Java:    $(java --version 2>/dev/null | head -1)"
    echo "  ANDROID_HOME: $ANDROID_HOME"
  '';
}
