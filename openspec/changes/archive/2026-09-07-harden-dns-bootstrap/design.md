## Context

sing-box 配置模板（`hosts/azure/substore-templates/{1.13,1.14}/{mac,linux-headless}.json`）由 azure 主机经 Sub-Store 分发：raspi 消费 `linux-headless`（sing-box 1.13），macbook 消费 `mac`（GUI 客户端）。

当前解析链：订阅动态注入的机场出站无显式 `domain_resolver`，走 `route.default_domain_resolver = dns-local`（`type: local`，系统明文 DNS）。机场域名不可白名单（动态变化），故只能在解析通道上加固。污染面分析确认：出站域名引导是唯一暴露面（规则集 URL 与测速域名经代理远端解析，`dns-remote` 自身为 IP）。

4 份模板结构一致（仅平台差异与 1.13/1.14 字段差异），本改动对 4 份通用（`local`/`https` DNS 服务器类型 1.12+ 均支持）。

## Goals / Non-Goals

**Goals**
- 出站域名引导经加密直连 DNS，免疫本地污染
- 修复私网主机名 NXDOMAIN（现落入 `final = dns-remote` 经代理解析）
- 保持 CN geo 解析正确性与被墙域名解析路径不变

**Non-Goals**
- 不引入 1.14 `evaluate`/`race` 抗污染模式（浏览面已被规则集+final 覆盖，重武器无必要）
- 不处理 `type: local` × 1.14 `dns_mode: hijack` 的行为验证（爆炸半径已缩至私网，另行 spike）
- 不改 Nix 模块（`hosts/modules/sing-box.nix`）、不加新规则集

## Decisions

### D1: 新增 `dns-direct`（DoH 223.5.5.5，detour: direct-out）而非复用 dns-local
- DoH 加密传输免疫在途投毒；`server` 为 IP → 无引导递归；443 端口比 DoT 853 更不易被针对性阻断
- 备选：`type: local` 保留默认解析器 → 污染面原样存在，否决；DoT 853 → 端口更易被 QoS/阻断，否决
- 命名沿用 `dns-` 前缀规范，语义为"直连加密解析器"

### D2: `default_domain_resolver` 指向 `dns-direct`，CN DNS 规则仍指 `dns-local`
- 引导路径与浏览路径分离：机场域名加密解析；CN 域名继续走系统 DNS 保证 geo 正确性（alidns 与系统 DNS 对 CN CDN 结果等价，但保留 local 以跟随系统环境，如路由器自定义域）
- 备选：全部收敛到 dns-direct → 丢失搜索域/.local 能力，否决（见 D3）

### D3: 新增 `geosite-private → dns-local` DNS 规则
- 修复现存 NXDOMAIN bug：私网主机名目前落入 final 经代理解析必失败
- 规则置于 clash_mode 规则之后、其他内容规则之前（clash 模式显式选择优先于内容规则）
- `geosite-private` 规则集已存在并被 route 规则引用，无新增下载

## Risks / Trade-offs

- [alidns DoH 自身不可用时出站域名解析失败] → 概率极低（alidns 多可用区）；`dns-local` 仍服务 CN 域名，浏览不中断；可后续加第二 provider 冗余
- [1.14 hijack 模式下 `type: local` 行为未验证] → 影响面缩至私网解析；spike 验证（dashboard trace 观察 `.lan` 查询路径）
- [模板漂移] → 4 份文件手工同步；现有任务清单 + 双版本 `sing-box check` + 引用完整性校验兜底

## Migration Plan

1. 按 tasks.md 修改 4 份模板（新增 server、改 default_domain_resolver、加 DNS 规则）
2. 双版本 `sing-box check` + 出站/DNS/规则集引用完整性校验
3. `git add`（flake 可见性）→ 用户重新部署：raspi `nixos-rebuild`（下载新模板后 `systemctl restart download-singbox-subscription`），mac 客户端重新订阅
4. 回滚：还原模板 JSON 即可，无状态迁移（DNS 解析无持久化依赖）

## Open Questions

- 无阻塞项。后续可选项：`dns-direct` 加 timeout（1.14 `dns.timeout`）、第二直连 DoH 冗余
