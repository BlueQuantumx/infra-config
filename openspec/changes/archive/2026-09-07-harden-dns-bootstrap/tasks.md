## 1. 模板修改（4 份文件，内容一致仅格式差异）

- [x] 1.1 在 `1.14/mac.json` 的 `dns.servers` 中新增 `dns-direct`（`type: https`，`server: 223.5.5.5`，`server_port: 443`，`path: /dns-query`，`detour: direct-out`），置于 `dns-local` 之后
- [x] 1.2 将 `1.14/mac.json` 的 `route.default_domain_resolver.server` 由 `dns-local` 改为 `dns-direct`
- [x] 1.3 在 `1.14/mac.json` 的 `dns.rules` 中 clash_mode 规则之后新增 `{ "action": "route", "rule_set": ["geosite-private"], "server": "dns-local" }`
- [x] 1.4 对 `1.14/linux-headless.json` 重复 1.1–1.3
- [x] 1.5 对 `1.13/mac.json` 重复 1.1–1.3（注意 jq 格式的多行数组/缩进差异）
- [x] 1.6 对 `1.13/linux-headless.json` 重复 1.1–1.3

## 2. 验证

- [x] 2.1 用 sing-box 1.13.19 与 1.14.0 二进制分别 `check` 4 份模板（空 urltest/selector 组填充 `direct-out`，linux 模板临时去掉 `auto_redirect` 以便本机校验）
- [x] 2.2 jq 校验引用完整性：`dns-direct` 被 `default_domain_resolver` 引用；`dns-local` 同时被 CN 规则集规则与 `geosite-private` 规则引用；无悬空出站/DNS/规则集引用
- [x] 2.3 `git add hosts/azure/substore-templates/`（flake 可见性）

## 3. 部署提示（交付给用户）

- [x] 3.1 提交后提醒：raspi `nixos-rebuild` 或手动触发 `update-singbox-subscription.timer` 拉取新模板；macbook 客户端重新订阅 `Mac (sing-box 1.14)` 文件
