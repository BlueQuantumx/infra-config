# Proposal: add-host-529-2

## Why

需要把一台新的 x86_64 物理桌面机 `529-2` 纳入本 flake。当前它不在 `nixosConfigurations` 内，无法用统一的 `nixos-rebuild` / sops / 共享模块管理。本次只搭建最小主机骨架（模板），具体业务内容（磁盘设备名、authorized keys、sops age key、附加服务）由后续填写。

## What Changes

- 在 `defaults.nix` 的 `hosts` 注册表新增 `"529-2"` 条目（`hostname` / `role` / `isRemote` / `adminKeys` 全部用占位值，等待填写）。
- 新增 `hosts/529-2/` 最小模板：
  - `configuration.nix`：只导入 `./disko.nix`、`./sops.nix`、`./hardware-configuration.nix` 占位文件，以及共享模块 `base` / `server` / `overlays`（必要时 `prelude-linux`）。
  - `disko.nix`：GPT 布局（ESP `/boot` + swap + ext4 `/`），磁盘设备名留占位，待 `lsblk` 核对后填写。
  - `sops.nix`：`sops.defaultSopsFile` 占位指向共享 secrets 文件。
  - `hardware-configuration.nix`：占位文件，注明需在目标机 `nixos-generate-config` 重新生成。
- 在 `flake.nix` 新增 `nixosConfigurations."529-2"` 输出（`x86_64-linux`，disko + sops-nix），并加入 `hostChecks`。
- 在 `.sops.yaml` 增加覆盖 `529-2` age key 的注释占位 creation rule，`sops updatekeys` 留待 key 填入后执行。
- 不改动任何现有主机（macbook / orb / raspi / azure / pascal-cloud-01 / digitalocean）的行为。

## Capabilities

### New Capabilities

- `host-529-2`: 主机 `529-2` 的最小行为契约：flake 提供可求值输出、disko 磁盘布局、SSH/用户基线沿用共享模块、sops 接收者占位、per-host 文件仅承载占位内容。

### Modified Capabilities

（无 — 现有 spec 不受影响。）

## Impact

- 新增 `hosts/529-2/` 目录与 `flake.nix` / `defaults.nix` 各一段增量；`home-manager/` 不做改动。
- **涉及 secrets**：仅在 `.sops.yaml` 留占位注释，不写入任何明文；实际 `sops updatekeys` 在 key 填入后执行。
- **不涉及 OpenTofu state**（非 Azure 资源）。
- 验证：`nix flake check`（含新 `hostChecks` 条目）与 `nixos-rebuild dry-build --flake .#529-2`。
