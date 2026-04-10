# vpinball-nix

Nix shell environment for building [vpinball](https://github.com/vpinball/vpinball) (vpx-standalone) on macOS and Linux without polluting the upstream repo.

## Why this repo exists

The upstream `vpinball` repo doesn't ship a `shell.nix` / `release.nix`, and adding one would mean carrying a local diff or maintaining a fork. Keeping the Nix files in a separate repo and symlinking them into the working copy of `vpinball` lets us:

- Track the Nix environment under its own git history.
- Leave the upstream `vpinball` checkout clean (no untracked files, no local commits to rebase around).
- Share the same shell across multiple `vpinball` checkouts/worktrees.

`shell.nix` provides:

- **macOS**: a minimal `mkShellNoCC` with the build tools needed by `external.sh` (which builds all third-party libs itself). Includes a `libtoolize` shim since GNU libtool installs as `glibtoolize` on Darwin.
- **Linux**: a `buildFHSEnv` with the full set of system dependencies (GL/Vulkan, Wayland, X11, ALSA/PipeWire, udev, HID/USB, etc.).

`release.nix` provides an FHS env for *running* the built `VPinballX_BGFX` binary on Linux.

## Setup

From your `vpinball` checkout (assumed to live at `~/ws/vpinball`):

```sh
cd ~/ws/vpinball

# Symlink the Nix files in
ln -s ~/ws/vpinball-nix/shell.nix shell.nix
ln -s ~/ws/vpinball-nix/release.nix release.nix

# Hide them from git locally without touching .gitignore
printf 'shell.nix\nrelease.nix\n' >> .git/info/exclude
```

Using `.git/info/exclude` keeps the ignore rules local to your clone — nothing is added to the tracked `.gitignore`.

## Usage

```sh
cd ~/ws/vpinball
nix-shell           # drops into the build environment
./external.sh       # build third-party deps (macOS)
cmake -B build ...  # configure & build vpinball as usual
```

To run the built binary inside the runtime FHS env (Linux):

```sh
nix-build release.nix
./result/bin/vpinball
```
