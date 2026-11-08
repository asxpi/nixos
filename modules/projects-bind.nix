# ~/Code/projects/anotherim lives on /mnt/data (root was full): bound back
# to its old path, so tools that know it by path (Claude Code's per-project
# memory, git worktrees, the .dev flakes, interop's aish) see no change.
# /mnt/data is plain ext4, not LUKS: the move accepted that.
{ ... }:

{
  fileSystems."/home/asxpi/Code/projects/anotherim" = {
    device = "/mnt/data/anotherim";
    fsType = "none";
    options = [ "bind" "nofail" "x-systemd.requires-mounts-for=/mnt/data" ];
  };
}
