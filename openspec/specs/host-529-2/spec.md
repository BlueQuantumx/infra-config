# host-529-2

## Purpose

定义物理桌面主机 `529-2`（x86_64-linux）的最小接入契约：flake 输出可求值、磁盘布局由 disko 声明、SSH 与用户基线复用共享模块、sops 使用该主机专属的 secrets 文件，per-host 文件以可求值的占位内容交付，具体机器相关值留待填写。

## Requirements

### Requirement: Flake 提供 529-2 主机输出

flake SHALL 在 `nixosConfigurations` 中提供 `529-2` 输出（x86_64-linux），复用 `disko` 与 `sops-nix` 模块，且只导入 `hosts/529-2/` 下的 per-host 文件与 `hosts/modules/` 共享模块，不引入新的共享模块。

#### Scenario: flake 校验通过

- **WHEN** 运行 `nix flake check`
- **THEN** `nixosConfigurations."529-2"` 求值成功，且 `hostChecks` 中包含该主机的检查条目

#### Scenario: 干构建通过

- **WHEN** 运行 `nixos-rebuild dry-build --flake .#529-2`
- **THEN** 构建计划生成成功，无求值错误

### Requirement: 主机注册表提供占位条目

`defaults.nix` 的 `hosts` 注册表 SHALL 包含 `"529-2"` 条目，使共享 `base` 模块能解析该主机；条目中的机器相关字段在模板阶段 MAY 为占位值。

#### Scenario: 共享模块解析主机

- **WHEN** 构建 `nixosConfigurations."529-2"`
- **THEN** `hosts/modules/base.nix` 能从 `defaults.hosts."529-2"` 读取该主机配置，占位值不导致求值失败

### Requirement: 磁盘布局由 disko 声明

主机 SHALL 使用 disko 声明 GPT 磁盘布局：EFI 分区挂载于 `/boot`、swap 分区、其余空间为 ext4 root。磁盘设备名 SHALL 只出现在 per-host 的 disko 文件中，不得在共享模块中硬编码。

#### Scenario: 初始化时自动分区

- **WHEN** 在目标机上以该配置执行 disko 分区
- **THEN** disko 按声明完成分区、格式化与挂载，系统可正常启动

### Requirement: SSH 与用户基线复用共享模块

主机 SHALL 通过共享 `server` 模块获得 SSH 加固（禁用密码认证、root 仅允许 key 登录）与 admin 用户基线，per-host 文件 SHALL NOT 重复实现这些策略。

#### Scenario: 密码登录被拒绝

- **WHEN** 未持有 authorized keys 的客户端尝试 SSH 密码登录
- **THEN** sshd 拒绝认证

#### Scenario: 管理员可登录

- **WHEN** 持有已配置公钥的客户端以 admin 用户或 root 登录
- **THEN** 认证成功，admin 用户可免密执行 sudo

### Requirement: sops 接收者以占位形式预留

`.sops.yaml` SHALL 为 `529-2` 预留一条可启用的接收者条目（模板阶段为注释占位），在 age key 填入前 MUST NOT 影响现有 secrets 的加解密；per-host `sops.nix` SHALL 指向共享 secrets 文件。

#### Scenario: 未填 key 时不影响现有流程

- **WHEN** 在 age key 尚未填入的情况下执行现有 sops 加解密流程
- **THEN** 行为与新增该主机前一致

#### Scenario: 填入 key 后可解密共享密钥

- **WHEN** 填入该主机 age key 并执行 `sops updatekeys` 后，在主机上激活 sops-nix
- **THEN** 共享 secrets 文件中的密钥可在该主机上解密

### Requirement: 模板文件以可求值占位内容交付

per-host 的 `configuration.nix`、`disko.nix`、`sops.nix` 与 `hardware-configuration.nix` SHALL 以可求值的占位内容交付；机器相关值（磁盘设备名、authorized keys、age key、硬件模块）MUST 标注为待填写。

#### Scenario: 占位内容下 flake 求值通过

- **WHEN** 以未修改的占位内容运行 `nix flake check`
- **THEN** 求值成功，且待填写项在文件中可被识别

#### Scenario: 不含明文密钥

- **WHEN** 检查新增文件
- **THEN** 不存在任何明文密钥或私钥
