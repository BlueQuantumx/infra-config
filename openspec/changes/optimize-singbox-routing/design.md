# Design: optimize-singbox-routing

## Context

目标文件：`hosts/azure/substore-templates/1.14/linux-headless.json`（substore 订阅模板，由 Azure 上的 substore + `inject-proxies.js` 注入出站后下发到 Linux 主机）。改动只涉及该 JSON 模板；nix 模块（`hosts/modules/sing-box.nix`）不动。

## 调查结论：geoip-cn 尾部解析成本（对应 proposal 调查项）

现状：`geoip-cn` 是最后一条路由规则。对「只有域名、未命中任何 geosite」的连接，geoip 匹配需要 IP，sing-box 会隐式解析域名（走 `route.default_domain_resolver` = `dns-direct`），解析完不是 CN 再落到 `final`。

已对照官方文档（Rule Action / resolve, 1.12–1.14）确认的方案空间：

| 方案 | 机制 | 结论 |
|---|---|---|
| A. 显式 `resolve` action | 在 geoip 规则前插入非终态规则 `{action: "resolve", server: "dns-direct"}`；解析结果进 DNS 缓存，geoip 匹配与后续拨号复用 | **采纳**。行为与隐式解析一致，但 server/超时/缓存/client_subnet 变为显式可控，成本可见 |
| B. 删除 geoip-cn | 冷门 CN 域名走代理 | 拒绝：CDN 调度劣化 |
| C. 隐式解析维持现状 | 无配置改动 | 拒绝：成本不可见、不可调 |
| D. `bypass` action（1.13+，Linux auto_redirect pre-match） | 内核态绕过 sing-box | 不适用本问题：pre-match 无法对域名做 geoip 判定；且会扩大改动面（用户已要求顺序与行为保持） |

方案 A 的关键点：`resolve` 是非终态动作，规则继续向下匹配；一次解析，geoip 匹配与拨号共享缓存，不产生额外第二次查询。不需要设置 `client_subnet`（`dns-direct` 是阿里 DoH，天然返回对 CN 友好的结果）。

## Decisions

1. **去重**：`cn.srs`（MetaCubeX）内容已基本覆盖 `geolocation-cn`。删除 route 与 dns 中两条 `geosite-geolocation-cn` 规则及 rule-set 定义，只留 `geosite-cn`。
   - 风险：极少数「在 geolocation-cn 但不在 cn」的域名将从 direct 变为走 final（fallback-out → select-out）。验收时用 sing-box rule-set 内容抽查确认覆盖差异可接受；若发现重要域名，直接补进模板的 domain_suffix 或接受走代理。
2. **显式 resolve**：在 `geoip-cn` 规则之前插入：
   ```json
   { "action": "resolve", "server": "dns-direct" }
   ```
   位置：所有终态 route 规则之后、geoip-cn 之前（即规则列表末尾两个位置）。
3. **speedtest 转 binary**：url 改为 `.../category-speedtest.srs`，`format` 改 `binary`。
4. **不改动**：规则顺序（仅上述插入/删除）、clash_mode、`find_process`、aria2c、端口直连、DNS 服务器定义与 `final`、`default_domain_resolver`。

## Validation

- `sing-box check -c <生成后的 config>` 必须通过（模板本身可先 `jq empty` + 人工比对）。
- 本地无 1.14 Linux 环境时，至少验证 JSON 合法性与 diff 最小化；真机验证走 `update-singbox-subscription` 定时任务 + dashboard 确认分流命中（CN 域名 direct、冷门国外域名 resolve→proxy）。
