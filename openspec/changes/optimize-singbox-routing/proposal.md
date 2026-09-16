# Proposal: optimize-singbox-routing

## Why

1.14 linux-headless 分流模板（`hosts/azure/substore-templates/1.14/linux-headless.json`）存在一处明确冗余：`geosite-geolocation-cn` 与 `geosite-cn` 两条路由规则及对应 DNS 规则完全同向（都 → direct-out / dns-local），重复加载 rule-set、重复匹配。另外路由尾部 `geoip-cn` 规则会让所有未匹配 geosite 的冷门国外域名各付一次引导解析（走 `dns-direct`），需要调查并确定处理方案。

探索阶段已确认的取舍：保留 `find_process`（aria2c 规则仍在用），路由规则顺序保持不变。

## What Changes

- 移除路由与 DNS 规则中冗余的 `geosite-geolocation-cn` 规则（route + dns 各一处）及其 rule-set 定义，仅保留 `geosite-cn`。
- 调查 `geoip-cn` 尾部规则的域名解析成本，确定并落地缓解方案（见 design.md）。
- 顺带统一 `geosite-speedtest` rule-set 为 binary（`.srs`）格式，与其他 rule-set 一致。
- 不改动：规则顺序、clash_mode 规则、`find_process`、端口/进程直连规则、DNS 服务器职责划分（沿用 `singbox-dns-resolvers` spec）。

## Capabilities

### New Capabilities

- `singbox-routing-rules`: sing-box 分流模板的路由/DNS 规则行为约定：CN 域名去重后由 `geosite-cn` 单点覆盖；`geoip-cn` 兜底规则的解析成本处理策略；rule-set 格式约定（统一 binary）。

### Modified Capabilities

（无 — `singbox-dns-resolvers` 的三类 DNS 服务器职责与引导解析行为不受影响，本轮不改其需求。）

## Impact

- `hosts/azure/substore-templates/1.14/linux-headless.json`（route.rules、dns.rules、route.rule_set 三处编辑）。
- 订阅产物 config.json 由 substore 模板重新生成后生效；`sing-box check` 必须通过。
- 行为影响：此前被 `geolocation-cn` 命中但不在 `geosite-cn` 中的极少数域名将从 direct 变为走 final（fallback-out）——需在验证时确认覆盖差异可接受。
