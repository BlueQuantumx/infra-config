# host-pascal-cloud-01

## Purpose

定义新云服务器主机 `pascal-cloud-01` 的行为契约：flake 输出可构建、磁盘布局、SSH 与用户基线、sops 密钥接入，以及从 Debian 13 初始化为 NixOS 的流程约定。

## Requirements

### Requirement: Flake 提供 pascal-cloud-01 主机输出

flake SHALL 在 `nixosConfigurations` 中提供 `pascal-cloud-01` 输出（x86_64-linux），复用 `disko`、`home-manager`、`sops-nix` 模块，并只导入 `hosts/pascal-cloud-01/` 下的 per-host 配置与 `hosts/modules/` 共享模块。

#### Scenario: flake 校验通过

- **WHEN** 运行 `nix flake check`
- **THEN** `nixosConfigurations.pascal-cloud-01` 求值成功且通过校验

#### Scenario: 干构建通过

- **WHEN** 运行 `nixos-rebuild dry-build --flake .#pascal-cloud-01`
- **THEN** 构建计划生成成功，无求值错误

### Requirement: 磁盘布局由 disko 声明

主机 SHALL 使用 disko 声明 GPT 磁盘布局：ESP（可被 grub 使用的 EFI 分区）挂载于 `/boot`、swap 分区、其余空间为 ext4 root；磁盘设备名不得在共享模块中硬编码。

#### Scenario: 初始化时自动分区

- **WHEN** 通过 nixos-anywhere 应用该配置到裸机/VM
- **THEN** disko 按声明完成分区、格式化与挂载，系统可正常启动

### Requirement: SSH 与用户基线

主机 SHALL 禁用 SSH 密码认证与 root 密码登录，仅允许 authorized keys；SHALL 提供 `luyan` 普通用户（wheel 组、zsh）与 root 的 SSH 公钥登录，免密 sudo 策略与现有云主机一致。

#### Scenario: 密码登录被拒绝

- **WHEN** 未持有 authorized keys 的客户端尝试 SSH 密码登录
- **THEN** sshd 拒绝认证

#### Scenario: 管理员可登录

- **WHEN** 持有已配置公钥的客户端以 `luyan` 或 root 登录
- **THEN** 认证成功，`luyan` 可免密执行 sudo

### Requirement: sops 密钥可解密

`.sops.yaml` SHALL 包含覆盖新主机 age key（由 SSH host ed25519 key 转换）的 creation rule，且现有共享 secrets 文件在执行 `sops updatekeys` 后 SHALL 包含该主机的接收者，使 sops-nix 能在主机上解密 `secrets/common.yaml` 中的共享密钥。

#### Scenario: 新主机解密共享密钥

- **WHEN** 部署后的 pascal-cloud-01 启动并激活 sops-nix
- **THEN** `secrets/common.yaml` 中声明的共享密钥以 sops run-secret 形式落盘可读

#### Scenario: 密钥从不明文入库

- **WHEN** 检查仓库中的 secrets 文件
- **THEN** 所有内容均为 sops 加密，主机 SSH 私钥不出现在仓库中

### Requirement: Debian 13 初始化流程有文档约定

仓库 SHALL 提供 `hosts/pascal-cloud-01/README.md`，约定从 Debian 13 接管为 NixOS 的流程：Debian 侧启用 SSH 并配置 root 公钥访问，随后用 nixos-anywhere `--build-on remote` 应用 `.#pascal-cloud-01`，后续日常变更用 `nixos-rebuild` 部署。

#### Scenario: 依照文档完成接管

- **WHEN** 按照 README 在一台全新 Debian 13 机器上执行流程
- **THEN** 机器被重装为 NixOS 并以 `pascal-cloud-01` 主机名加入 flake 管理，后续 `nixos-rebuild switch --flake` 可正常迭代
