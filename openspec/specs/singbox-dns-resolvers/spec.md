# singbox-dns-resolvers Specification

## Purpose

TBD - created by syncing change 'harden-dns-bootstrap'. Update as needed.

## Requirements

### Requirement: 出站域名引导解析必须走加密直连 DNS

sing-box 配置模板中，`route.default_domain_resolver` SHALL 指向一个加密的、直连出站的 DNS 服务器（`dns-direct`，DoH 223.5.5.5）。该服务器自身 SHALL 使用 IP 地址作为 `server`（避免引导递归），且 SHALL NOT 设置 `detour`（新格式 DNS 服务器默认即直连；sing-box 1.14 运行时拒绝 detour 到空 direct 出站）。

#### Scenario: 机场节点域名解析不受本地 DNS 污染影响
- **WHEN** 订阅注入的出站需要解析其服务器域名（无显式 `domain_resolver`）
- **THEN** 解析经 `dns-direct`（DoH，加密、直连）完成，ISP 无法在途投毒

#### Scenario: dns-direct 自身无引导递归
- **WHEN** sing-box 初始化 `dns-direct`
- **THEN** 其 `server` 为 IP 地址（223.5.5.5），无需额外解析即可直连

### Requirement: 私网域名解析走系统 DNS

配置模板 SHALL 包含 DNS 规则：`rule_set: [geosite-private]` 的查询路由到 `dns-local`（`type: local`）。该规则 SHALL 位于 clash_mode 规则之后、其他内容规则之前。

#### Scenario: 局域网主机名可解析
- **WHEN** 客户端查询私网主机名（如 `router.lan`、`.local`、`.home.arpa` 域）
- **THEN** 查询由 `dns-local`（系统解析器）处理，返回局域网结果而非 NXDOMAIN

#### Scenario: 私网解析不受代理状态影响
- **WHEN** 代理出站不可用或用户切换 clash 模式（rule 模式下）
- **THEN** 私网域名解析不依赖任何代理出站

### Requirement: DNS 服务器职责划分

配置模板 SHALL 维持三类 DNS 服务器的明确分工：
- `dns-local`（`type: local`）：仅服务私网域名与 CN 域名（geo 正确性）
- `dns-direct`（DoH 直连）：服务出站域名引导（默认域名解析器）
- `dns-remote`（DoT 经代理）：服务被墙域名（`final` 兜底不变）

#### Scenario: CN 域名 geo 解析正确性保持
- **WHEN** 匹配 CN 规则集的域名发起查询
- **THEN** 仍由 `dns-local` 解析，CDN 调度结果与改动前一致

#### Scenario: 被墙域名解析路径不变
- **WHEN** 不匹配任何 DNS 规则的域名（含被墙域名）发起查询
- **THEN** 兜底仍为 `dns-remote`（DoT 经 `select-out` 代理），行为与改动前一致
