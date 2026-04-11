{ pkgs ? import <nixpkgs> {} }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # macOS only needs build tools; external.sh builds all third-party libs
  darwinShell = pkgs.mkShellNoCC {
    buildInputs = with pkgs; [
      cmake
      pkg-config
      autoconf
      automake
      libtool
      bison
      curl
      nasm
      zlib

      # Rust
      rustc
      cargo
      rustfmt
      clippy
    ];

    shellHook = ''
      export PATH="${pkgs.bison}/bin:$PATH"
      # GNU libtool installs as glibtoolize on macOS; autoreconf expects libtoolize
      if command -v glibtoolize &>/dev/null && ! command -v libtoolize &>/dev/null; then
        mkdir -p "$TMPDIR/nix-libtool-shim"
        ln -sf "$(command -v glibtoolize)" "$TMPDIR/nix-libtool-shim/libtoolize"
        export PATH="$TMPDIR/nix-libtool-shim:$PATH"
      fi
    '';
  };

  # Linux uses FHS environment with full system dependencies
  linuxShell = (pkgs.buildFHSEnv {
    name = "vpinball-env";

    targetPkgs = pkgs: with pkgs; [
      # Build tools
      zsh
      gcc
      cmake
      pkg-config
      autoconf
      automake
      libtool
      m4
      nasm
      bison
      curl
      gnumake

      # Rust
      rustc
      cargo
      rustfmt
      clippy

      # Compression
      zlib
      zlib.dev

      # Graphics / GPU
      libdrm
      libdrm.dev
      mesa
      libGL
      libGL.dev
      libGLU
      libglvnd
      libglvnd.dev
      egl-wayland
      vulkan-headers
      vulkan-loader
      vulkan-loader.dev

      # Wayland
      wayland
      wayland.dev
      wayland-scanner
      wayland-protocols
      libdecor

      # X11 and extensions
      xorgproto
      libx11
      libx11.dev
      libxcb
      libxcb.dev
      libxcursor
      libxcursor.dev
      libxext
      libxext.dev
      libxfixes
      libxfixes.dev
      libxi
      libxi.dev
      libxrandr
      libxrandr.dev
      libXrender
      libXrender.dev
      libxscrnsaver
      libxtst
      libxkbcommon
      libxkbcommon.dev

      # Audio
      alsa-lib
      alsa-lib.dev
      libpulseaudio
      pipewire
      pipewire.dev

      # System
      udev
      systemd.dev
      dbus
      dbus.dev
      libgbm
      ibus

      # HID / USB
      hidapi
      libftdi1
      libusb1
    ];

    profile = ''
      export PATH="/usr/bin:$PATH"
      export CMAKE_PREFIX_PATH="/usr"
      export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
    '';

    runScript = builtins.getEnv "SHELL";
  }).env;

in
  if isDarwin then darwinShell else linuxShell
