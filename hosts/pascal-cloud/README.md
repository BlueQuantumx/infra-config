# pascal-cloud

x86_64-linux 云服务器。当前（初始状态）运行 Debian 13，通过 nixos-anywhere 接管为 NixOS。

> ⚠️ **警告：接管过程会清空整块磁盘并重装，Debian 上的所有数据都会丢失。**
> 确认机器上没有需要保留的数据后再继续。

## 日常操作

```bash
# 本地构建并部署
nixos-rebuild switch --flake .#pascal-cloud --target-host root@<ip>

# 或仅构建
nixos-rebuild build --flake .#pascal-cloud
```

## 从 Debian 13 初始化接管（仅首次）

### 1. Debian 侧准备

以现有方式登录 Debian，启用 SSH 并允许 root 公钥登录：

```bash
apt update && apt install -y openssh-server
```

把本机公钥（`hosts/azure/configuration.nix` 中 authorized keys 对应的私钥）写入 `/root/.ssh/authorized_keys`，确认 `/etc/ssh/sshd_config` 允许 root 公钥登录（`PermitRootLogin prohibit-password`），然后重启 sshd。

该主机不使用 disko（`hosts/pascal-cloud/disko.nix` 已在接管完成后删除），磁盘布局沿用安装时的 `/dev/vda`。

### 2. nixos-anywhere 接管

在本仓库 devShell 中执行（`nix develop`）：

```bash
nixos-anywhere --build-on remote --flake .#pascal-cloud root@<ip>
```

完成后机器即为 NixOS，主机名 `pascal-cloud`。

### 3. 接管后收尾

- 本机 `known_hosts` 会因 host key 变化报警，按提示清理旧条目。
- 新系统会生成新的 SSH host key：

  ```bash
  ssh root@<ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub'
  ```

- 将该公钥经 `ssh-to-age` 转换后填入 `.sops.yaml`：

  ```bash
  ssh root@<ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
  ```

  把转换结果填入 `.sops.yaml` 中 `&pascal-cloud`（已填；主机换 host key 后需重做），然后重加密该主机专属的 secrets 文件（接收者随该主机的 age key 一起加入）：

  ```bash
  sops updatekeys secrets/pascal-cloud.yaml
  ```

- 验证：`nix flake check`、`nixos-rebuild dry-build --flake .#pascal-cloud`。
- 登录检查：SSH 仅公钥可登录、`luyan` 免密 sudo、`lsblk` 中 ESP 挂载 `/boot`、`swapon` 显示 swap 生效、sops secret 在重启后于 `/run/secrets` 可见。

## DDNS 上报

本机通过 `services.pascal-ddns`（`hosts/modules/pascal-ddns.nix`）每 5 分钟上报一次自身地址，把 `zly.svr.pascal-lab.net` 指向本机（本机复用现有条目 `zly`，不单独建条目）。流程：

1. 在 <https://ddns.pascal-lab.net> 用统一账号登录，创建（或复用）条目，复制它给出的 `report_uuid`。
2. 把该 `report_uuid` 写入本主机专属的 secrets 文件：

   ```bash
   sops set secrets/pascal-cloud.yaml '["pascal_ddns_auth"]' '"<report_uuid>"'
   ```

3. 部署。上报内容就是原始 `ip a` 输出（服务端可用条目的 `preferred_interface_mac` 固定选用哪块网卡的地址），经由公共服务前端 `https://ddns.pascal-lab.net` 提交。

> ⚠️ 在 `pascal_ddns_auth` 写入 secrets 文件之前，主机上的 sops 激活（`sops-install-secrets`）会因缺少该 key 而失败，`nixos-rebuild switch` 也会随之报错；本地 `nix flake check` 不受影响。

`529-2` 也用同一模块，但它直连校园网后端 `http://pascal08.svr.pascal-lab.net:8788`。

## 故障排查

| 现象 | 处理 |
| --- | --- |
| nixos-anywhere 卡在磁盘阶段 | 该主机不使用 disko，按默认布局重装后确认 `lsblk` 与预期一致 |
| 接管后 SSH 被拒 | 确认使用 authorized keys 中对应的私钥；清理本地 known_hosts |
| sops secret 不可见 | 确认 `.sops.yaml` 已含该主机 age key，且已对该主机专属 secrets 文件执行 `sops updatekeys` |
| `pascal_ddns_auth` 报 key 不存在 | 见「DDNS 上报」，需先把条目 `report_uuid` 写入 `secrets/pascal-cloud.yaml` |
| 构建卡在 `proxy.golang.org`（`sops-install-secrets` 的 go-modules 拉取超时） | 本机访问不到 `proxy.golang.org`，`hosts/modules/sops-common.nix` 已把 `sops.package` 的 Go 模块拉取指向 `goproxy.cn`；确认该主机仍 import `nixosModules.sops` |
