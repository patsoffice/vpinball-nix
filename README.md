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

`release.nix` provides a generic FHS runtime env for Linux — a `buildFHSEnv` with all the shared libraries vpinball (and related tools like `vpxtool`) need at runtime. It's built as a `nix-build` target that produces a bash wrapper; you run your binary inside it by passing `-c "..."`. Use this when running dynamically linked binaries on NixOS / Nix-managed systems where `/usr/lib` isn't populated.

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
nix-shell                        # drops into the build environment
platforms/linux-x64/external.sh  # Rebuild 3rd party deps if changed
cp make/CMakeLists_bgfx-linux-x64.txt CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build -- -j$(nproc)
```

To run a binary inside the runtime FHS env (Linux), build the wrapper once and invoke it with `-c 'exec "$@"' _ <cmd> "$@"` so arguments pass through cleanly:

```sh
ENV="$(nix-build /home/pjl/ws/vpinball-nix/release.nix --no-out-link)/bin/vpinball-env"
"$ENV" -c 'exec "$@"' _ ./build/VPinballX_BGFX
```

The same wrapper can run any other binary that needs the same runtime libraries. Example `~/bin/vpinball` launcher with timestamped logs:

```bash
#!/usr/bin/env bash
LOGDIR="$HOME/.cache/vpinball"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(date +%Y%m%dT%H%M%S).log"
ENV="$(nix-build /home/pjl/ws/vpinball-nix/release.nix --no-out-link)/bin/vpinball-env"

# Tee output to both terminal and log
exec > >(tee -a "$LOG") 2>&1

echo "=== vpinball $(date -Iseconds) ==="
echo "=== args ==="
for a in "$@"; do echo "  $a"; done
echo "=== launching ==="

exec "$ENV" -c 'exec "$@"' _ /home/pjl/ws/vpinball/build/VPinballX_BGFX "$@"
```

And a simpler `~/bin/vpxtool`:

```bash
#!/usr/bin/env bash
ENV="$(nix-build /home/pjl/ws/vpinball-nix/release.nix --no-out-link)/bin/vpinball-env"
exec "$ENV" -c 'exec "$@"' _ /home/pjl/ws/vpxtool/target/debug/vpxtool "$@"
```

The `-c 'exec "$@"' _ <cmd> "$@"` trick passes each argument as a discrete positional parameter to the inner bash, avoiding the word-splitting / quoting bugs you hit with `-c "$cmd $*"`. The `_` is `$0` inside the inner bash (a throwaway name) and `exec` replaces the bash process with the target binary so there's no extra shell layer in the process tree.

> **Note:** `nix-shell --run` does **not** work with `buildFHSEnv` — the FHS env is a wrapper binary, not a regular shell derivation. Always go through `nix-build` and invoke the resulting `bin/vpinball-env` wrapper directly.
