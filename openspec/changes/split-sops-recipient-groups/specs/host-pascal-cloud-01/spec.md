## ADDED Requirements

### Requirement: pascal-cloud-01 使用专属 sops secrets 文件

`.sops.yaml` SHALL 包含覆盖新主机 age key（由 SSH host ed25519 key 转换）的 creation rule，且该主机 SHALL 使用专属的 per-host secrets 文件（接收者仅包含该主机与 administration key），而不是共享 secrets 文件。

#### Scenario: 新主机解密专属密钥

- **WHEN** 部署后的 pascal-cloud-01 启动并激活 sops-nix
- **THEN** 该主机专属 secrets 文件中声明的密钥以 sops run-secret 形式落盘可读

#### Scenario: 不读取其他主机的密钥

- **WHEN** 在 pascal-cloud-01 上尝试解密其他主机专属的 secrets 文件
- **THEN** 解密失败，因为该主机不是该文件的接收者

#### Scenario: 密钥从不明文入库

- **WHEN** 检查仓库中的 secrets 文件
- **THEN** 所有内容均为 sops 加密，主机 SSH 私钥不出现在仓库中

## REMOVED Requirements

### Requirement: sops 密钥可解密

**Reason**: 共享 secrets 文件被拆分为 per-host 文件，接收者约定由「pascal-cloud-01 使用专属 sops secrets 文件」取代。
**Migration**: 主机启用时创建 pascal-cloud-01 专属 secrets 文件并执行 `sops updatekeys`，将 `hosts/pascal-cloud-01/sops.nix` 的 `defaultSopsFile` 指向该文件。
