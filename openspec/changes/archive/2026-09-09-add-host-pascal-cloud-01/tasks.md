# Tasks: add-host-pascal-cloud-01

## 1. 主机配置模板

- [x] 1.1 创建 `hosts/pascal-cloud-01/disko.nix`：复制 `hosts/azure/disko.nix` 布局（GPT + 1M EF02 + 1G ESP `/boot` + swap + ext4 `/`），设备名标注待核对（默认 `/dev/vda`），验证 `nix flake check` 前的文件存在与语法（`nix-instantiate --parse`）
- [x] 1.2 创建 `hosts/pascal-cloud-01/sops.nix`：仿照 `hosts/azure/sops.nix` 设置 `SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/etc/ssh/ssh_host_ed25519_key"`，声明共享密钥（`secrets/common.yaml` 中已用到的 key 暂按需最小声明，无业务则留空结构），验证文件可被后续 flake 导入
- [x] 1.3 创建 `hosts/pascal-cloud-01/configuration.nix`：导入 `./disko.nix`、`./sops.nix` 与共享 `../modules/prelude.nix`、`../modules/prelude-linux.nix`；配置 UEFI grub（`efiInstallAsRemovable`）、`networking.useDHCP`、SSH 加固（禁密码、`PermitRootLogin = "prohibit-password"`）、`luyan` 用户（wheel + zsh + authorized keys）与 root authorized keys、`security.sudo.wheelNeedsPassword = false`、`home-manager` 集成、`system.stateVersion`；hostname 设为 `pascal-cloud-01`
- [x] 1.4 创建 `home-manager/luyan-pascal-cloud-01.nix`：从现有 Linux 云主机 HM 文件（如 `home-manager/luyan-azure.nix`）派生最小配置，`configuration.nix` 中引用；验证导入路径正确

## 2. Flake 与 secrets 接线

- [x] 2.1 在 `flake.nix` 新增 `nixosConfigurations."pascal-cloud-01"`（x86_64-linux，导入 disko / home-manager / sops-nix 模块 + `./hosts/pascal-cloud-01/configuration.nix`），运行 `nix flake check` 通过
- [x] 2.2 运行 `nixos-rebuild dry-build --flake .#pascal-cloud-01` 确认求值与构建计划无误
- [ ] 2.3 在 `.sops.yaml` 增加覆盖该主机 age key 的 creation rule（key 由主机 SSH ed25519 经 `ssh-to-age` 转换，接管后回填），运行 `sops updatekeys secrets/common.yaml` 验证重加密成功且 `git diff` 仅见接收者变化

## 3. 初始化文档与实际接管

- [x] 3.1 编写 `hosts/pascal-cloud-01/README.md`：警告整盘重装；Debian 13 侧准备（`apt install openssh-server`、root 公钥、`lsblk` 核对磁盘设备名并按需修正 disko.nix）；`nixos-anywhere --build-on remote --flake .#pascal-cloud-01 root@<ip>`；接管后 known_hosts 更新、SSH host key 回填 `.sops.yaml` 并 `sops updatekeys`；日常迭代 `nixos-rebuild switch --flake .#pascal-cloud-01`
- [ ] 3.2 按 README 在真实机器执行接管，验证：新系统能 SSH（key-only）、`luyan` 免密 sudo、`/boot` 与 swap 挂载正确（`lsblk` / `swapon`）、sops secret 在重启后可见
- [ ] 3.3 完成回填后再次运行 `nix flake check` 与 `nixos-rebuild dry-build --flake .#pascal-cloud-01`，并 `git add` 全部新文件（确认无明文密钥入库）
