# singbox-routing-rules Specification (Delta)

## ADDED Requirements

### Requirement: CN 域名分流由 geosite-cn 单点覆盖

1.14 linux-headless 配置模板 SHALL 在 route 规则与 DNS 规则中各只保留一条 CN 兜底规则（`rule_set: ["geosite-cn"]`），SHALL NOT 同时保留 `geosite-geolocation-cn` 规则；`geosite-geolocation-cn` rule-set 定义 SHALL 被移除。

#### Scenario: route 中无重复 CN 规则
- **WHEN** 检查模板的 `route.rules`
- **THEN** 存在一条 `geosite-cn` → `direct-out` 规则，且不存在 `geosite-geolocation-cn` 规则

#### Scenario: DNS 中无重复 CN 规则
- **WHEN** 检查模板的 `dns.rules`
- **THEN** 存在一条 `geosite-cn` → `dns-local` 规则，且不存在 `geosite-geolocation-cn` 规则

#### Scenario: rule-set 定义已清理
- **WHEN** 检查模板的 `route.rule_set`
- **THEN** 不存在 tag 为 `geosite-geolocation-cn` 的定义

### Requirement: geoip-cn 兜底解析使用显式 resolve 动作

模板 SHALL 在 `geoip-cn` 路由规则之前放置一条非终态 `action: "resolve"` 规则，显式指定 `server: dns-direct`，使末尾 geoip 匹配所需的域名解析可见、可控（缓存、超时、client_subnet），而不是依赖 geoip 规则的隐式解析。

#### Scenario: 冷门国外域名的解析路径显式化
- **WHEN** 一个仅含域名的连接未匹配任何 geosite 规则并到达 geoip-cn 判定
- **THEN** 解析由显式 `resolve` 规则经 `dns-direct` 完成并进入 DNS 缓存，geoip 匹配复用该结果，不产生第二次查询

### Requirement: rule-set 统一使用 binary 格式

模板中所有 remote rule-set SHALL 使用 `.srs` binary 格式（`format: "binary"`），SHALL NOT 使用 `format: "source"`。

#### Scenario: speedtest 规则集为 binary
- **WHEN** 检查 tag 为 `geosite-speedtest` 的 rule-set
- **THEN** 其 url 指向 `.srs` 文件且 `format` 为 `binary`

### Requirement: 分流行为保持项

模板 SHALL 保持以下行为不变：路由规则顺序、clash_mode 规则、`find_process: true` 与 aria2c 进程直连规则、端口 22/587 直连规则、三类 DNS 服务器职责划分（见 `singbox-dns-resolvers` spec）。

#### Scenario: find_process 与进程规则保留
- **WHEN** 检查模板
- **THEN** `route.find_process` 为 true，且存在 `process_name: aria2c` → `direct-out` 规则

#### Scenario: 顺序与 DNS 职责不变
- **WHEN** 对比改动前后的模板
- **THEN** 除本 spec 明确允许的删除/新增外，路由规则相对顺序、DNS 服务器定义与 `final` 均不变
