# Proposal: add-host-pascal-cloud-01

## Why

需要新增一台云服务器主机 `pascal-cloud-01`（x86_64-linux，当前为 Debian 13）。该机器目前不在本 flake 管理范围内，无法纳入统一的 nixosConfigurations / sops 密钥 / EasyTier 组网体系。趁机器刚开通、尚无关键数据，现在以 nixos-anywhere 从 Debian 13 直接接管为 NixOS 成本最低。

## What Changes

- 新增 `hosts/pascal-cloud-01/` 基础模板配置（`configuration.nix` + `disko.nix`），沿用 azure/digital-ocean 的云服务器模式：DHCP、SSH 加固、`luyan` 用户 + root authorized keys、home-manager 集成、`system.stateVersion`。
- 在 `flake.nix` 新增 `nixosConfigurations."pascal-cloud-01"` 输出（disko + home-manager + sops-nix 模块），不引入 colmena / deploy-rs / OpenTofu。
- 在 `.sops.yaml` 为该主机登记 SSH host key（ed25519 → age 转换）的 creation rule，并配合 `sops updatekeys` 让现有 `secrets/common.yaml` 可被新主机解密。
- 提供从 Debian 13 初始化（nixos-anywhere `--build-on remote`）的操作文档 `hosts/pascal-cloud-01/README.md`，含"Debian 侧准备"步骤（安装 openssh、root SSH key 登录）。
- 不改动任何现有主机（macbook / orb / raspi / azure）的行为。

## Capabilities

### New Capabilities

- `host-pascal-cloud-01`: 主机 pascal-cloud-01 的行为约定：flake 输出可构建、disko 磁盘布局（ESP + swap + ext4 root）、SSH 加固与用户基线、sops 密钥可解密、nixos-anywhere 从 Debian 13 初始化流程。

### Modified Capabilities

（无 — 现有 spec 不受影响。）

## Impact

- 新增 `hosts/pascal-cloud-01/`、flake.nix 一处输出、`.sops.yaml` 一条 creation rule。
- **涉及 secrets**：需把新主机 SSH host key 加入 `.sops.yaml` 并 `sops updatekeys secrets/common.yaml`（密钥本身不入库明文）。
- **不涉及 OpenTofu state**（非 Azure 资源）。
- 验证：`nix flake check`、`nixos-rebuild dry-build --flake .#pascal-cloud-01`、`sops updatekeys` 成功。
