const { type, name } = $arguments;

let config = JSON.parse($files[0]);
let mainProxies = await produceArtifact({
  name: "main",
  type: "collection",
  platform: "sing-box",
  produceType: "internal",
});

let backupProxies = await produceArtifact({
  name: "backup",
  type: "collection",
  platform: "sing-box",
  produceType: "internal",
});

config.outbounds.push(...mainProxies);
config.outbounds.push(...backupProxies);
// 按 tag 字段去重，保留最后一个
config.outbounds = [
  ...new Map(config.outbounds.map((item) => [item.tag, item])).values(),
];

config.outbounds.map((i) => {
  if (["all-out"].includes(i.tag)) {
    i.outbounds.push(...getTags(mainProxies));
    i.outbounds.push(...getTags(backupProxies));
  }
  if (["manual-out"].includes(i.tag)) {
    i.outbounds.push(...getTags(mainProxies));
    i.outbounds.push(...getTags(backupProxies));
  }
  if (["hk-out"].includes(i.tag)) {
    i.outbounds.push(...getTags(mainProxies, /港|hk|hongkong|hong kong|🇭🇰/i));
  }
  if (["tw-out"].includes(i.tag)) {
    i.outbounds.push(...getTags(mainProxies, /台|tw|taiwan|🇹🇼/i));
  }
  if (["jp-out"].includes(i.tag)) {
    i.outbounds.push(...getTags(mainProxies, /日本|jp|japan|🇯🇵/i));
  }
  if (["sg-out"].includes(i.tag)) {
    i.outbounds.push(
      ...getTags(mainProxies, /^(?!.*(?:us)).*(新|sg|singapore|🇸🇬)/i),
    );
  }
  if (["us-out"].includes(i.tag)) {
    i.outbounds.push(
      ...getTags(mainProxies, /美|us|unitedstates|united states|🇺🇸/i),
    );
  }
  i.outbounds = [...new Set(i.outbounds)];
});

$content = JSON.stringify(config, null, 2);

function getTags(proxies, regex) {
  return (regex ? proxies.filter((p) => regex.test(p.tag)) : proxies).map(
    (p) => p.tag,
  );
}
