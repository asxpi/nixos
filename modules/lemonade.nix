{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-amd-ai.nixosModules.default ];

  # Prebuilt XRT/FLM/lemonade from the flake's Cachix; without it the whole
  # NPU stack builds from source. Must live in nix.settings, not flake
  # nixConfig (non-trusted users silently ignore the latter).
  nix.settings = {
    substituters = [ "https://nix-amd-ai.cachix.org" ];
    trusted-public-keys = [ "nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ=" ];
  };

  # XDNA2 NPU LLM serving (FLM runtime via lemonade, OpenAI-compatible API on
  # 127.0.0.1:13305). iGPU/GGUF inference stays with ollama-rocm.
  hardware.amd-npu = {
    enable = true;
    enableImageGen = false;
    lemonade = {
      user = "lemonade";
      host = "127.0.0.1";
      desktopApp.enable = false; # headless server only; skips the Tauri build path
    };
  };

  # Same rationale as ollama: model store on plain-ext4 /mnt/data — model
  # blobs are public data, no need to occupy LUKS root or pay dm-crypt.
  # FLM/lemonade derive their model dirs from $HOME.
  users.users.lemonade = {
    isSystemUser = true;
    group = "lemonade";
    home = "/mnt/data/lemonade";
    createHome = true;
    extraGroups = [ "video" "render" ]; # /dev/accel0 is group video per module udev rule
  };
  users.groups.lemonade = { };

  systemd.services.lemond.unitConfig.RequiresMountsFor = [ "/mnt/data/lemonade" ];

  # lemonade only looks for flm on PATH when flm.prefer_system=true; default is
  # false and nix-amd-ai's defaults seed doesn't cover it, so the FLM/NPU backend
  # shows "not installed" and all -FLM models vanish from the registry. Patch the
  # runtime config.json (cached copy overrides defaults) until fixed upstream.
  systemd.services.lemond.preStart = ''
    cfg="$HOME/.cache/lemonade/config.json"
    if [ -f "$cfg" ]; then
      ${pkgs.jq}/bin/jq '.flm.prefer_system = true' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
    fi
  '';
}
