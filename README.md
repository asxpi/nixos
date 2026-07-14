# NixOS

Flake-based NixOS configuration for a ThinkPad P14s Gen 6 (AMD), tracking `nixos-unstable`.

## Highlights

- **Secure Boot** via [lanzaboote](https://github.com/nix-community/lanzaboote)
- **Secrets**: [sops-nix](https://github.com/Mic92/sops-nix) with age — xray config, WireGuard, SSH keys, private routes/hosts; encrypted files stay out of the repo (only `.example` structure files are tracked), decrypted to `/run/secrets` at activation
- **Desktop**: GNOME on Wayland, AMD GPU
- **Local LLMs**: Ollama with ROCm (gfx1151) + Lemonade for XDNA2 NPU serving via [nix-amd-ai](https://github.com/noamsto/nix-amd-ai)
- **Networking**: Xray VLESS+Reality with sing-box TUN, WireGuard, WWAN modem
- **Gaming**: Steam with gamescope, declarative Flatpaks via [nix-flatpak](https://github.com/gmodena/nix-flatpak)
- **Litecoin Core (MWEB)**: vendored package build, revived after removal from nixpkgs
- **Power**: AMD P-State tuning, zram swap ahead of disk swap

## Layout

```
flake.nix              # inputs and host definition
configuration.nix      # entry point, imports modules
modules/               # one module per concern (boot, desktop, ollama, xray, ...)
secrets/               # sops-encrypted (age) secrets, gitignored; .example files document structure
```

## Usage

```sh
sudo nixos-rebuild switch --flake /etc/nixos#meow
```

Fresh install: restore `secrets/` and the age key (`/var/lib/sops-nix/key.txt`) from out-of-band backup first.

## TODO

- [ ] Evaluate Home Manager
