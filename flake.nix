{
  description = "Flutter Android Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      
      # We must allow unfree packages for the Android SDK
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
      };

      # Compose our exact Android SDK requirements
      androidEnv = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "33" "34" "35" "36" ];
        buildToolsVersions = [ "28.0.3" "34.0.0" "35.0.0" ];
        
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ]; 
        
        # Add the CMake version Gradle is asking for:
        cmakeVersions = [ "3.22.1" ];
        
        includeEmulator = true;
        useGoogleAPIs = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "flutter-env";
        
        buildInputs = [
          pkgs.flutter
          androidEnv.androidsdk
          pkgs.jdk17 # Matches the sourceCompatibility = JavaVersion.VERSION_17 in your gradle
        ];

        # Tell flutter and gradle where to find the SDK
        ANDROID_HOME = "${androidEnv.androidsdk}/libexec/android-sdk";
        ANDROID_SDK_ROOT = "${androidEnv.androidsdk}/libexec/android-sdk";
        JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
        
        # Prevent Gradle from trying to download SDK updates into the immutable Nix store
        GRADLE_OPTS = "-Dandroid.builder.sdkDownload=false";

        shellHook = ''
          echo "📱 Flutter/Android Dev Environment Loaded!"
          echo "NDK Version Provided: 28.2.13676358"
        '';
      };
    };
}
