# Design: add-host-529-2

## Context

`529-2` 是一台 x86_64 物理桌面机，尚未纳入本 flake。仓库现有主机分为云 VM（`hosts/azure/`、`hosts/pascal-cloud-01/`、`hosts/digital-ocean/`）、边缘设备（`hosts/raspi/`）与容器（`hosts/orb/`）。所有 NixOS 主机统一通过 `lib/default.nix` 的 `mkNixos` 构造，共享模块来自 `hosts/modules/`，per-host 差异只放在 `hosts/<name>/`。动机与范围见 proposal.md，行为契约见 `specs/host-529-2/spec.md`。

## Goals / Non-Goals

**Goals:**

- 提供一套最小、可求值的 x86_64 物理主机骨架，`nix flake check` 通过。
- 复用现有 `base` / `server` / `overlays` 共享模块，不新增共享模块。
- 预留 sops 接入点，使后续填写 age key 时无需改动结构。

**Non-Goals:**

- 不填写具体机器值（磁盘设备名、authorized keys、age key、硬件模块）——留给后续。
- 不接入 home-manager、Tailscale、sing-box、sub-store 等业务模块。
- 不写 OpenTofu 资源、不引入 colmena / deploy-rs。
- 不改动任何现有主机行为。

## Decisions

1. **采用最小模板：`base` + `server` + `overlays`**。`base` 提供 `stateVersion` 与 hostName（经 `defaults.hosts`），`server` 提供 SSH 加固与 admin 用户基线，`overlays` 提供 nixpkgs 覆盖。相比 `pascal-cloud-01`（额外含 home-manager、cloud-vm、sops 及大量业务模块），本模板刻意剔除业务层。备选：直接把 `pascal-cloud-01` 整体复制——被否，用户明确要求最简模板。**不引入 `cloud-vm`**：那是云 VM 的 removable-UEFI + DHCP 约定，物理桌面应显式声明自己的 boot loader 与网络（`NetworkManager` 或 DHCP 由填写者决定）。
2. **不接入 home-manager**。最简模板只保证系统可构建、可 SSH 登录；用户在 `server` 模块下已有 shell 与 sudo。后续若需要，按 `pascal-cloud-01` 模式加 `home-manager.users.luyan.imports` 与 `home-manager/luyan-529-2.nix` 即可。
3. **disko 复制 `hosts/azure/disko.nix` 的简单布局**（GPT + 1M EF02 + 1G ESP `/boot` + swap + ext4 `/`）。这是仓库已验证、且不依赖 UEFI/BIOS 细节的通用方案；设备名以占位值交付，要求填写者用 `lsblk` 核对后修改（写在本主机 disko 文件内，不进入共享模块）。
4. **`hardware-configuration.nix` 以占位文件交付并在 `configuration.nix` 中导入**，使 flake 在未上机时也能求值；文件头注释说明必须在目标机用 `nixos-generate-config` 覆盖。备选：用 `(modulesPath + "/installer/scan/not-detected.nix")` 规避硬件文件——被否，物理机的 CPU/GPU/文件系统细节需要真实 hardware-config，占位文件更明确地提示待办。
5. **flake 输出与检查条目照抄现有结构**：`nixosConfigurations."529-2" = helper.mkNixos { hostName = "529-2"; system = "x86_64-linux"; sops = true; modules = [ ./hosts/529-2/configuration.nix ]; }`，并在 `hostChecks.x86_64-linux` 增加 `529-2` 条目。属性名含前导数字与连字符，必须加引号（`"529-2"`），`hosts."529-2"` 同理。
6. **sops 占位沿用现有惯例**：`.sops.yaml` 增加一条注释形式的 `&529-2` 锚点与对应 creation rule 行（保持注释），填入由 `ssh-to-age` 转换的 host key 后取消注释并执行 `sops updatekeys secrets/common.yaml`；host 侧 `sops.nix` 用 `sops.defaultSopsFile = ../../secrets/common.yaml;`（仅声明默认文件，不声明任何具体 secret，避免模板阶段引用不存在的 key）。

## Risks / Trade-offs

- [占位 `hardware-configuration.nix` 与真实硬件不符，直接部署会缺驱动] → 文件头与 tasks 明确要求上机后 `nixos-generate-config` 覆盖，且首装走标准 NixOS 安装流程而非直接 switch。
- [磁盘设备名占位值错误导致误格式化] → 设备名单独放在本机 disko 文件并标注 TODO；tasks 要求在分区前 `lsblk` 核对。
- [`.sops.yaml` 占位 anchor 未被注释干净，导致 sops 报未定义 key] → 占位整行保持注释，tasks 包含运行 `sops -d`/现有加解密流程确认无回归。
- [“最简模板”省去 home-manager 后，用户后续需要额外结构] → 加 home-manager 是纯增量（一条 import + 一个文件），不影响已交付内容。
- [属性名前导数字在未加引号时求值报错] → 所有出现处统一用引号形式。

## Rollback

全部改动为新增文件加 `flake.nix` / `defaults.nix` / `.sops.yaml` 的小段增量，`git revert` 对应提交即可完全回退；未触及任何现有主机。若后续在真机上已执行 disko 分区，回退需重装目标机，不在本变更范围。
