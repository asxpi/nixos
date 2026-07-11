{ config, pkgs, lib, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "11.5.1";  # gfx1151, Krackan Point RDNA 3.5
    host = "127.0.0.1";
    port = 11434;
    # Model store on plain-ext4 /mnt/data: model blobs are public data, so
    # they don't need to occupy the 512G LUKS root or pay dm-crypt on reads.
    # Static user instead of the default DynamicUser — a random dynamic UID
    # can't own a persistent store outside /var/lib.
    user = "ollama";
    group = "ollama";
    home = "/mnt/data/ollama";
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      # gfx1151 (RDNA 3.5) lacks tuned hipBLASLt kernels in current ROCm; force
      # the stable rocBLAS GEMM path to avoid crashes/garbage output on this iGPU.
      ROCBLAS_USE_HIPBLASLT = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      # Keep the loaded model resident: every eviction re-pays a multi-minute
      # 20+ GiB disk read (client keep_alive can still override per-request).
      OLLAMA_KEEP_ALIVE = "-1";
      # Default 5m load timeout kills large-model loads under memory pressure.
      OLLAMA_LOAD_TIMEOUT = "15m";
    };
    loadModels = [ "qwen3:14b" ];
  };
}
