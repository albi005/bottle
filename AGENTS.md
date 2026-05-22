- We are on NixOS, you can use the already installed tools or you can use `nix-shell` to install things temporarily.
- When creating git commits, append `Assisted-by: OpenCode:deepseek-v4-pro` to every commit message.

## Known Issue: `pkill -f larq_bridge` hangs
Sometimes `pkill -f` matching `larq_bridge` appears to hang. Likely cause:
- The process is in D state (uninterruptible sleep in BLE ioctl)
- Solution: `timeout 5 pkill -9 -f` or kill individual PIDs
