{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSEnv {
  name = "vpinball-env";

  targetPkgs = pkgs: with pkgs; [
    libGL
    libGLU
    libglvnd
    libdrm
    mesa
    vulkan-loader
    wayland
    egl-wayland
    libx11
    libxcb
    libxrandr
    libxcursor
    libxfixes
    libxext
    libxi
    libxscrnsaver
    libxtst
    libXrender
    libxkbcommon
    alsa-lib
    pipewire
    libpulseaudio
    hidapi
    libftdi1
    libusb1
    systemd
    dbus
  ];

  runScript = builtins.getEnv "SHELL";
}).env
