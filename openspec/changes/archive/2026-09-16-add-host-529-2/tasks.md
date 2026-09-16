# Tasks: add-host-529-2

## 1. 主机注册与 flake 接线

- [x] 1.1 在 `defaults.nix` 的 `hosts` 注册表新增 `"529-2"` 条目（`hostname` / `role` / `isRemote` / `adminKeys` 用占位值并注 TODO），运行 `nix eval .#nixosConfigurations --apply builtins.attrNames` 确认求值不因缺字段失败
- [x] 1.2 在 `flake.nix` 的 `nixosConfigurations` 新增 `"529-2"`（`x86_64-linux`、`sops = true`、`modules = [ ./hosts/529-2/configuration.nix ]`），并在 `hostChecks.x86_64-linux` 增加对应条目，运行 `nix flake check --no-build` 确认求值通过

## 2. per-host 模板文件

- [x] 2.1 创建 `hosts/529-2/configuration.nix`：导入 `./hardware-configuration.nix`、`./disko.nix`、`./sops.nix` 与 `inputs.self.nixosModules.base` / `server` / `overlays`；不导入业务模块与 home-manager；用 `nix-instantiate --parse` 校验语法
- [x] 2.2 创建 `hosts/529-2/disko.nix`：复制 `hosts/azure/disko.nix` 的 GPT 布局（EF02 + ESP `/boot` + swap + ext4 `/`），设备名留占位并注 TODO「用 `lsblk` 核对后填写」；`nix-instantiate --parse` 通过
- [x] 2.3 创建 `hosts/529-2/hardware-configuration.nix` 占位文件（含 `fileSystems."/"`、`swapDevices` 或最小骨架 + 文件头注释「必须在目标机 `nixos-generate-config` 覆盖」）；`nix-instantiate --parse` 通过
- [x] 2.4 运行 `nixos-rebuild dry-build --flake .#529-2` 确认占位内容下构建计划生成成功

## 3. sops 占位

- [x] 3.1 创建 `hosts/529-2/sops.nix`，设置 `sops.defaultSopsFile = ../../secrets/common.yaml;`（不声明具体 secret）；确认能被 `configuration.nix` 导入
- [x] 3.2 在 `.sops.yaml` 增加 `&529-2` 注释占位锚点（注明由 SSH host ed25519 经 `ssh-to-age` 转换后填入）及对应的注释 creation rule 行；运行一次现有 `sops -d secrets/common.yaml > /dev/null`（或等效）确认现有加解密无回归，且 `git diff` 无明文密钥

## 4. 整体校验

- [x] 4.1 运行 `nix flake check`，确认 `nixosConfigurations."529-2"` 与 `hostChecks` 中 `529-2` 条目均求值成功，现有主机不受影响
- [x] 4.2 人工检查新增文件：仅含占位内容与 TODO，无明文密钥；确认 `hosts/529-2/` 中磁盘设备名、authorized keys、age key、硬件模块均标注待填写
