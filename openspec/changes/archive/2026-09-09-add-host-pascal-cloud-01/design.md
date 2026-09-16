# Design: add-host-pascal-cloud-01

## Context

pascal-cloud-01 是一台 x86_64-linux 云服务器，当前运行 Debian 13（全新、无数据）。仓库已有多台 Linux 云主机（`hosts/azure/`、`hosts/digital-ocean/`）与边缘主机（`hosts/raspi/`、`hosts/orb/`），部署模式统一为：flake `nixosConfigurations` + nixos-anywhere 初始化 + `nixos-rebuild` 日常迭代（见 `hosts/azure/README.md`）。没有 colmena / deploy-rs，Azure 之外的机器也没有 OpenTofu 资源。动机见 proposal.md，行为契约见 `specs/host-pascal-cloud-01/spec.md`。

## Goals / Non-Goals

**Goals:**

- `.#pascal-cloud-01` 可求值、可 dry-build，配置结构与现有云主机一致，方便日后直接引用共享模块。
- 一份 README 覆盖"Debian 13 → NixOS"的完整接管路径，可重复执行。
- 接入 sops：新主机能解密 `secrets/common.yaml` 中现有共享密钥（如后续启用 EasyTier / sing-box 无需迁移密钥）。

**Non-Goals:**

- 不部署业务服务（caddy、sing-box、sub-store、EasyTier 等后续按需再加）。
- 不写 OpenTofu 资源、不引入 colmena / deploy-rs。
- 不改动任何现有主机与共享模块的行为。

## Decisions

1. **模板基线选 azure 模式而非 digital-ocean 极简模式**：azure 配置含 home-manager 集成 + sops + 完整 SSH/用户基线，是功能最全的云主机模板；digital-ocean 过于精简（无 HM、无用户）。新主机保留 sops 模块与 `sops.nix`（即使模板阶段只声明共享密钥），避免以后补接密钥时要动 `.sops.yaml` 与配置两处。业务模块（sub-store / caddy / hypervGuest / azure.nix）一律不导入。
2. **disko 布局复制 `hosts/azure/disko.nix`**：GPT + 1M EF02 + 1G ESP(`/boot`) + swap + ext4 `/`。EF02 分区让 grub 的 `devices` 自动填充，UEFI 下仍走 `efiInstallAsRemovable`，是仓库已验证的模式。备选的 digital-ocean LVM 方案仅在没有标准分区需求时才有价值，不采用。磁盘设备名（`/dev/vda` vs `/dev/sda`）在 nixos-anywhere 首次接管时按实际云商磁盘命名确定，写在本主机 disko.nix，README 中注明如何核对。
3. **flake 输出照抄 azure 条目结构**：`nixpkgs.lib.nixosSystem` + `disko.nixosModules.disko` + `home-manager.nixosModules.home-manager` + `sops-nix.nixosModules.sops` + `./hosts/pascal-cloud-01/configuration.nix`，`system = "x86_64-linux"`，`specialArgs = { inherit inputs; }`。home-manager 用户文件新建 `home-manager/luyan-pascal-cloud-01.nix`，从最接近的 Linux 云主机 HM 文件派生最小内容。
4. **sops 接入沿用现有惯例**：`.sops.yaml` 增加 coverage 该主机 age key（由 `ssh-to-age` 转换自主机 SSH ed25519 host key）的 creation rule → `sops updatekeys secrets/common.yaml` 重加密；主机侧 `sops.nix` 用 `SOPS_AGE_SSH_PRIVATE_KEY_FILE = /etc/ssh/ssh_host_ed25519_key`（与 azure 相同的 SSH key workaround）。**主机 SSH host key 必须在 nixos-anywhere 接管前从 Debian 侧取不到——实际流程是：接管完成后首次登录生成新 host key，再回填 `.sops.yaml`**；若要密钥在首装即生效，则在 README 中提供把已知 host key 通过 `environment.etc` 预置的选项（本模板默认走"接管后回填"路径，业务密钥尚未部署，无实际影响）。
5. **初始化用 nixos-anywhere `--build-on remote`**：Debian 13 侧只需 `apt install openssh-server` + 放入 root 公钥。远端构建避免本地交叉编译 x86_64 闭包的体积问题，且与 azure 流程一致。devShell 已含 `nixos-anywhere` / `nixos-rebuild` / `sops`，无需改 devShell。

## Risks / Trade-offs

- [Debian 13 磁盘设备名与假设不符（vda vs sda/nvme）] → README 首步要求 `lsblk` 核对并按需改 `disko.nix`；接管是一次性格式化，操作前确认目标盘。
- [首次接管后主机 SSH host key 变化导致本地 known_hosts 报警] → README 提示清除旧条目；`.sops.yaml` 回填在接管后进行，属预期流程。
- [sops 密钥在 host key 回填前不可解密] → 模板阶段未部署依赖密钥的服务，风险为零；回填 + `sops updatekeys` 在 tasks 中列为部署后步骤。
- [nixos-anywhere 接管会清空整盘（Debian 数据全失）] → 该机器为全新机器，README 顶部以显著方式警告"会重装整盘"。
- [模板 stateVersion 直接写死新 nixpkgs 当前版本] → 与现有主机保持同值（flake 已锁 nixos-26.05），无需特殊处理。

## Rollback

全部改动为新增文件 + `flake.nix` / `.sops.yaml` 各一小段增量，`git revert` 对应提交即可完全回退；已接管后的机器回退到 Debian 需云商重装镜像，不在本变更范围。
