## ADDED Requirements

### Requirement: 529-2 使用专属 sops secrets 文件

`.sops.yaml` SHALL 为 `529-2` 提供接收者条目，且 per-host `sops.nix` SHALL 指向该主机专属的 secrets 文件；该主机 MUST NOT 成为其他主机专属 secrets 文件的接收者。

#### Scenario: 主机使用专属 secrets 文件

- **WHEN** 求值 `nixosConfigurations."529-2"` 的 sops 配置
- **THEN** `sops.defaultSopsFile` 指向 529-2 专属的 secrets 文件

#### Scenario: 不读取其他主机的密钥

- **WHEN** 在 529-2 上激活 sops-nix 并尝试解密其他主机专属的 secrets 文件
- **THEN** 解密失败，因为 529-2 不是该文件的接收者

#### Scenario: 专属文件可解密

- **WHEN** 在 529-2 上激活 sops-nix
- **THEN** 529-2 专属 secrets 文件中的密钥可在该主机上解密

## REMOVED Requirements

### Requirement: sops 接收者以占位形式预留

**Reason**: 529-2 的 age key 已填入，主机不再使用共享 secrets 文件；接收者与 per-host files 的约定由「529-2 使用专属 sops secrets 文件」取代。
**Migration**: 将 `hosts/529-2/sops.nix` 的 `defaultSopsFile` 指向 529-2 专属文件，并对该文件执行 `sops updatekeys`。
