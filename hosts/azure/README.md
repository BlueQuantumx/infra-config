# Azure 部署 NixOS:OpenTofu + nixos-anywhere

使用 [OpenTofu](https://opentofu.org) 在 Azure 上创建虚拟机,再通过 [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) 将 NixOS 安装到该虚拟机。

## 目录结构

```
hosts/azure/
├── configuration.nix   # NixOS 配置
├── disko.nix           # 磁盘分区布局
└── (defaults 在仓库根 tofu/defaults.nix,见下)
```

```
tofu/                     # OpenTofu 配置(仓库根,与 hosts/ 平级)
├── defaults.nix          # 共享值单一数据源(域名/Tailscale tailnet/EasyTier(可选)/VM 规格等)
├── providers.tf          # azurerm provider 声明与配置
├── variables.tf          # 变量(地区、VM 规格、SSH 密钥等)
├── main.tf               # Azure 资源、Entra 自定义域名与 Cloudflare DNS
├── nixos.tf              # null_resource:调用 nixos-anywhere 安装
├── outputs.tf            # 输出:公网 IP、SSH 命令
├── terraform.tfvars.json # 由 `nix run .#tofu-vars` 生成,gitignored,tofu 自动加载
└── terraform.tfvars.example  # 复制为 terraform.tfvars 填写订阅 ID
```

根目录 `flake.nix` 中注册了 `nixosConfigurations.azure`(nixos-anywhere 通过 `.#azure` 解析 flake 属性,必须挂在根 flake 上)。

## 前置条件

- `az login` 已登录(订阅 "Azure for Students" 等)，且当前账号有 Microsoft Graph
  `Domain.ReadWrite.All` 权限(首次调用时按提示同意)
- Nix + direnv(devShell 提供 `opentofu`、`nixos-anywhere`、`azure-cli`)
- SSH 密钥对:`~/.ssh/azure`(私钥)与 `~/.ssh/azure.pub`(公钥),私钥需已加载到 ssh-agent:
  ```sh
  ssh-add ~/.ssh/azure
  ```
  > 私钥有口令保护时,必须在 ssh-agent 中加载;tofu 的 local-exec 无 TTY,无法交互输入口令。

- flake 相关文件需被 git 跟踪(`git add`),否则 `nix build .#...` 报 "not tracked by Git"

## 工作原理

### Entra 自定义域名

`tofu apply` 通过 `az rest` 调用 Microsoft Graph 确保自定义域 `mse.egrecho47.top`
在 Entra 中存在（不存在则创建），并保持其注册。域名**验证是一次性 bootstrap**：
一旦在 Entra 中成为已验证默认域（`isVerified`/`isDefault`），配置便不再管理验证
TXT 记录，避免每次 `tofu apply` 都重写记录并重跑校验。Azure CLI 使用当前
`az login` 会话，不在仓库中保存 Graph 凭据。

### 为什么不用官方 terraform 模块

nixos-anywhere 官方 `all-in-one` terraform 模块内部用 `nix-build` 模块在**本地**构建
`x86_64-linux` 系统闭包。本机是 aarch64-darwin 且无远程 builder,无法本地构建 Linux 产物,
模块不可用。因此改为:

- OpenTofu 只负责 Azure 基础设施(VM 等)
- `null_resource` 的 `local-exec` 直接调用 `nixos-anywhere --build-on remote`:
  本地只做 flake 求值与 SSH,系统闭包在远端(kexec 后的 NixOS 安装器)构建

### 整体流程

```
tofu apply
  ├─ 创建资源组/VNet/子网/NSG/公网IP/NIC
  ├─ 创建 Ubuntu 22.04 Gen2 VM(admin_ssh_key 注入 ~/.ssh/azure.pub)
  └─ local-exec: nixos-anywhere --build-on remote --flake <repo>#azure luyan@<IP>
       ├─ 生成临时 SSH 密钥并 ssh-copy-id(经 ssh-agent 认证)
       ├─ kexec 进 NixOS 安装器(aarch64/x86_64 自动选择)
       ├─ 远端构建 disko 脚本并格式化磁盘
       ├─ 远端构建系统闭包(从 cache.nixos.org 拉取)
       ├─ 安装 NixOS(含 GRUB UEFI 引导)
       └─ 重启,部署完成
```

## 部署步骤

共享值(域名、Tailscale tailnet、EasyTier(可选)、VM 规格等)的单一数据源是 `defaults.nix`,
NixOS 配置与 OpenTofu 共用。tofu 侧 `variables.tf` **没有默认值**,所有变量值
必须来自自动加载的 `terraform.tfvars.json`(gitignored),改 `defaults.nix` 后重新生成:

```sh
nix run .#tofu-vars      # 从 Nix 重新生成 tofu/terraform.tfvars.json
```

```sh
# 1. 进入 tofu 目录并准备变量(填写真实订阅 ID;或直接用 flake app)
cd tofu
cp terraform.tfvars.example terraform.tfvars

# 2. 初始化(首次)
tofu init

# 3. 刷新 tfvars.json(若缺失,tofu plan/apply 会报 "No value for required variable")
nix run .#tofu-vars      # 或直接用下面的 flake app,会自动刷新

# 4. 预览 / 部署(`nix run .#tofu-plan` / `nix run .#tofu-apply` 等价,且会先刷新 tfvars.json)
tofu plan
tofu apply

# 5. 验证
ssh root@$(tofu output -raw vm_public_ip)
```

安装完成后:

```sh
hostname        # azure-nixos
uname -m        # x86_64
nixos-version   # 26.05.20260731.5b4f72e
lsblk           # sda: EF02 1M + ESP 1G(/boot) + swap 4G + ext4 35G(/)
```

## 遇到的问题与修复

| 问题 | 原因 | 修复 |
| --- | --- | --- |
| NSG 创建失败 `Unsupported value used: *` | Azure 拒绝 `source_address_prefixes = ["*"]` | 改为 `["0.0.0.0/0"]` |
| SSH `Connection reset by peer` | apply 被中断,VM 处于 kexec 安装器残留状态 | `tofu destroy` 后重新 `tofu apply`;或 `az vm restart` 重启回 Ubuntu |
| `incorrect passphrase supplied to decrypt private key` | `~/.ssh/azure` 有口令,local-exec 无 TTY 无法解密 | 去掉 `-i` 参数,改用 ssh-agent 认证 |
| 远端构建报 "I am a 'x86_64-linux'" | 误以为 `Standard_B2als_v2` 是 ARM,配置写成 aarch64-linux | 查微软文档确认 B 系列 `*ats_v2`/`*als_v2`/`*as_v2` 均为 AMD x86-64(ARM 是 `B*pts_v2` 系列),改回 `x86_64-linux` |
| `You must set the option 'boot.loader.grub.devices'` | 纯 UEFI 分区无 EF02,disko 无法自动填充 grub 设备 | disko 分区表添加 1M EF02 分区 |

## 日常操作

```sh
# 连接
ssh root@<IP>          # 需 ssh-agent 含 azure 密钥

# 更新 NixOS(远程,配置在 git 仓库中)
ssh root@<IP> 'nixos-rebuild switch --flake <git仓库URL>#azure'

# 重装(VM 重建时 null_resource 自动重新安装)
tofu apply

# 销毁全部资源
tofu destroy
```

- `null_resource` 的触发条件是 `instance_id`:仅当 VM 被重建时才会重跑 nixos-anywhere,
  日常 `tofu apply` 不会重装系统。
- Azure 未安装 waagent,门户可能显示 provisioning 未完成,属正常现象,不影响使用。

## 关键配置说明

| 配置 | 说明 |
| --- | --- |
| `virtualisation.hypervGuest.enable` | Azure 是 Hyper-V 客户机,加载 hv_* 驱动与 hyperv-daemons |
| `boot.loader.grub.efiInstallAsRemovable` | Azure Gen2 UEFI 走可移除引导路径 |
| `disko` 磁盘 `/dev/sda` | Azure OS 磁盘为 SCSI(无临时盘,Basv2 无 ephemeral) |
| `services.tailscale` | Azure 作为 tailnet 的 server + exit 节点(`--advertise-exit-node`，退出节点由 tailnet ACL 自动批准)。密钥由 `tofu/tailnet` 栈生成，经 `tofu-tailnet-secrets` 同步进 sops；NSG 不开放任何 tailnet 入站端口，连接均为出站发起。 |
| EasyTier(可选回退) | EasyTier 配置全部保留，但默认关闭(`defaults.nix` 的 `easytier.enable`)。开启时同时启用服务/密钥/NSG 规则；关闭时不声明 sops 密钥、不建 NSG 规则。 |
| `Standard_B2ats_v2` | 2 vCPU / 1 GiB,AMD x86-64;学生套餐免费规格(750 小时/月),x86 免费档中的最大内存版本(B1s 仅 1 vCPU / 1 GiB) |
| 固定公网 IP | 每次重建后 IP 保持不变(同一订阅/区域) |
