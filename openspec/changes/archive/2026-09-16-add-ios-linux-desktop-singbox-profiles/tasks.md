## 1. Linux desktop profile

- [x] 1.1 Create `hosts/azure/substore-templates/1.14/linux-desktop.json` from `1.14/mac.json`, changing only the Tailscale endpoint hostname to `linux-desktop` and the auth-key placeholder to `__TAILSCALE_AUTHKEY_LINUX_DESKTOP__`; verify it parses as JSON and its `endpoints` block differs from `mac.json`.
- [x] 1.2 Create `hosts/azure/substore-templates/1.13/linux-desktop.json` from `1.13/mac.json` the same way; verify it parses as JSON and its identity matches 1.1.

## 2. iOS profiles

- [x] 2.1 Create `hosts/azure/substore-templates/1.14/ios.json` from `1.14/mac.json`, changing the Tailscale endpoint hostname to `iphone` and the auth-key placeholder to `__TAILSCALE_AUTHKEY_IOS__`; verify it parses as JSON.
- [x] 2.2 In `1.14/ios.json`, remove `experimental.clash_api`, `route.find_process`, and the `process_name: aria2c` route rule; verify `services.api` (with dashboard) and `http_clients` remain and no process-based routing remains.
- [x] 2.3 Create `hosts/azure/substore-templates/1.13/ios.json` from `1.13/mac.json` with the iOS identity, add `services.api` + `http_clients` in the `1.14` shape so the dashboard works, and remove process-based routing; verify it parses as JSON.

## 3. Version compatibility

- [x] 3.1 Validate each new profile against its target sing-box schema; verify `1.13/ios.json` either validates with its added `http_clients` or falls back to no dashboard per design.md.
- [x] 3.2 Verify every profile in `hosts/azure/substore-templates/{1.13,1.14}/` carries a distinct Tailscale identity and none reuses another profile's placeholder, by diffing the `endpoints` blocks.

## 4. Integration and follow-up

- [x] 4.1 Run `nix flake check` (or the `azure` sub-store dry-build) and verify the new templates are consumed without errors.
- [x] 4.2 Record that the two new Tailscale auth-key placeholders still need provisioning (out of scope here) so the profiles can bring Tailscale up.
