# pascal-cloud-01

x86_64-linux 云服务器。当前（初始状态）运行 Debian 13，通过 nixos-anywhere 接管为 NixOS。

> ⚠️ **警告：接管过程会清空整块磁盘并重装，Debian 上的所有数据都会丢失。**
> 确认机器上没有需要保留的数据后再继续。

## 日常操作

```bash
# 本地构建并部署
nixos-rebuild switch --flake .#pascal-cloud-01 --target-host root@<ip>

# 或仅构建
nixos-rebuild build --flake .#pascal-cloud-01
```

## 从 Debian 13 初始化接管（仅首次）

### 1. Debian 侧准备

以现有方式登录 Debian，启用 SSH 并允许 root 公钥登录：

```bash
apt update && apt install -y openssh-server
```

把本机公钥（`hosts/azure/configuration.nix` 中 authorized keys 对应的私钥）写入 `/root/.ssh/authorized_keys`，确认 `/etc/ssh/sshd_config` 允许 root 公钥登录（`PermitRootLogin prohibit-password`），然后重启 sshd。

核对磁盘设备名：

```bash
lsblk
```

若不是 `/dev/vda`（例如 `/dev/sda` 或 `/dev/nvme0n1`），修改 `hosts/pascal-cloud-01/disko.nix` 中的 `device` 值。

### 2. nixos-anywhere 接管

在本仓库 devShell 中执行（`nix develop`）：

```bash
nixos-anywhere --build-on remote --flake .#pascal-cloud-01 root@<ip>
```

完成后机器即为 NixOS，主机名 `pascal-cloud-01`。

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

  取消 `.sops.yaml` 中 `&pascal-cloud-01` 相关注释并填入转换结果，然后重加密该主机专属的 secrets 文件（接收者随该主机的 age key 一起加入）：

  ```bash
  sops updatekeys secrets/pascal-cloud-01.yaml
  ```

- 验证：`nix flake check`、`nixos-rebuild dry-build --flake .#pascal-cloud-01`。
- 登录检查：SSH 仅公钥可登录、`luyan` 免密 sudo、`lsblk` 中 ESP 挂载 `/boot`、`swapon` 显示 swap 生效、sops secret 在重启后于 `/run/secrets` 可见。

## 故障排查

| 现象 | 处理 |
| --- | --- |
| nixos-anywhere 卡在磁盘阶段 | 确认 `disko.nix` 的 `device` 与 `lsblk` 一致 |
| 接管后 SSH 被拒 | 确认使用 authorized keys 中对应的私钥；清理本地 known_hosts |
| sops secret 不可见 | 确认 `.sops.yaml` 已含该主机 age key，且已对该主机专属 secrets 文件执行 `sops updatekeys` |
