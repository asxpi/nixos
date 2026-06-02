{ config, pkgs, lib, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "11.5.1";  # gfx1151, Krackan Point RDNA 3.5
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
    loadModels = [ "qwen3:14b" ];
  };
}
