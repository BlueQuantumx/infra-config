# Tasks: optimize-singbox-routing

## 1. 编辑模板

- [x] 1.1 `hosts/azure/substore-templates/1.14/linux-headless.json`：删除 route 规则 `rule_set: ["geosite-geolocation-cn"]` → direct-out，删除 dns 规则 `rule_set: ["geosite-geolocation-cn"]` → dns-local，删除对应的 rule-set 定义
- [x] 1.2 在 `geoip-cn` 路由规则之前插入 `{ "action": "resolve", "server": "dns-direct" }`（非终态规则）
- [x] 1.3 将 `geosite-speedtest` rule-set 改为 `.srs` binary（url: `.../category-speedtest.srs`，`format: "binary"`）

## 2. 验证

- [x] 2.1 `jq empty` 验证 JSON 合法；diff 确认无其他改动
- [x] 2.2 抽查 `cn.srs` 与被删除的 `geolocation-cn` 覆盖差异，确认重要域名无遗漏（有遗漏则补 domain_suffix 或记录接受走代理）
  - 结论：无遗漏。v2fly `data/cn` = `include:tld-cn` + `include:geolocation-cn`，即 `geosite-cn` 按构造 ⊇ `geolocation-cn`
- [ ] 2.3 部署后（substore 重新生成订阅 + 目标机 `update-singbox-subscription`）跑 `sing-box check`，并在 dashboard 验证：CN 域名 direct、冷门国外域名经 resolve 后走 fallback-out、局域网主机名仍可解析（`singbox-dns-resolvers` spec 回归）
