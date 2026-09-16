## Why

sing-box 客户端配置中，机场节点的服务器域名（订阅动态注入、无法白名单）经 `route.default_domain_resolver` → `dns-local`（`type: local`，系统明文 DNS）解析。ISP 可污染该链路，导致代理静默失效。此外，私网主机名（如 `router.lan`）不匹配任何 DNS 规则，落入 `final = dns-remote`（经代理解析）必然 NXDOMAIN。

## What Changes

- 所有 4 份 sing-box 配置模板（`1.13`/`1.14` × `mac`/`linux-headless`）新增 `dns-direct` DNS 服务器（DoH 223.5.5.5，`detour: direct-out`，加密直连、IP 无引导递归）
- `route.default_domain_resolver` 由 `dns-local` 改为 `dns-direct`，使机场域名经加密通道解析
- 新增 DNS 规则 `geosite-private → dns-local`，私网主机名/搜索域走系统解析（修复 NXDOMAIN 问题，并让 `type: local` 职责单一化）
- `dns-local` 与 `dns-remote` 角色不变（CN 域名 geo 解析 / 被墙域名经代理）

## Capabilities

### New Capabilities
- `singbox-dns-resolvers`: sing-box 配置模板的 DNS 服务器职责划分与域名解析路由要求（私网、CN、被墙、出站引导四类流量的解析路径）

### Modified Capabilities
- （无——现有 specs 均不涉及 sing-box 配置模板）

## Impact

- 文件：`hosts/azure/substore-templates/{1.13,1.14}/{mac,linux-headless}.json`（azure 主机经 Sub-Store 分发）
- 受影响主机：**azure**（托管模板）、**raspi**（消费 linux-headless 模板，sing-box 1.13）、**macbook**（消费 mac 模板，GUI 客户端）
- 不涉及 secrets 与 OpenTofu state；不涉及 Nix 模块逻辑变更（`hosts/modules/sing-box.nix` 无需改动）
- 验证：`sing-box check`（1.13.19 / 1.14.0 两版二进制）+ 引用完整性检查
