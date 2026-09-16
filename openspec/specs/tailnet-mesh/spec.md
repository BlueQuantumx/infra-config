# tailnet-mesh Specification

## Purpose

Defines how each host joins the tailnet — node roles and tags, exit-node advertisement and consumption policy, the Mac's userspace sing-box endpoint, and the service path that Caddy exposes across the tailnet — replacing the EasyTier mesh.

## Requirements

### Requirement: Cloud and home hosts join the tailnet with tagged credentials

The NixOS hosts `azure` and `raspi` SHALL enable the Tailscale service and enroll using an auth key supplied through sops-nix, never a plaintext credential in the host configuration. Each host SHALL carry role tags that classify it for access policy.

#### Scenario: NixOS host enrolls from a sops-provided key

- **WHEN** the `azure` or `raspi` NixOS configuration is evaluated
- **THEN** `services.tailscale` is enabled with its auth key read from a sops-nix secret path
- **AND** no auth key value appears in the repository

#### Scenario: Hosts are tagged by role

- **WHEN** `azure` or `raspi` enrolls
- **THEN** the node carries a server tag and an exit tag

### Requirement: Hosts advertise exit nodes; no client consumes one by default

`azure` and `raspi` SHALL advertise themselves as Tailscale exit nodes, and SHALL be configured to advertise only (not to consume routes). Host and template configuration SHALL NOT select an exit node by default; a client uses an exit node only when explicitly configured.

#### Scenario: Hosts advertise an exit node

- **WHEN** the `azure` or `raspi` Tailscale service starts
- **THEN** the node advertises itself as an exit node

#### Scenario: No default exit consumer

- **WHEN** `raspi` or the Mac is evaluated without an explicit exit-node selection
- **THEN** no outbound traffic is routed through another node's exit

### Requirement: The Mac joins through sing-box's userspace tailscale endpoint

The Mac sing-box template SHALL declare a `tailscale` endpoint in place of the EasyTier WireGuard endpoint, and SHALL NOT request a system interface, so the endpoint participates in sing-box's own routing instead of creating a second TUN device. The endpoint's auth key SHALL be injected at render time from sops, never stored in the template file.

#### Scenario: Auth key is injected at render time

- **WHEN** the sub-store payload for the Mac template is rendered
- **THEN** the endpoint's auth key is substituted from a sops placeholder
- **AND** the committed template contains no key material

#### Scenario: Endpoint stays in userspace

- **WHEN** the Mac's sing-box configuration is evaluated
- **THEN** the tailscale endpoint does not create a system interface

#### Scenario: Tailnet traffic routes to the endpoint

- **WHEN** the Mac sends traffic to a tailnet address
- **THEN** it is routed to the tailscale endpoint rather than a proxy or the default outbound

### Requirement: Caddy reaches navidrome through the tailnet

The `azure` Caddy virtual host for navidrome SHALL reverse-proxy to `raspi`'s tailnet address rather than its former EasyTier address.

#### Scenario: Navidrome upstream uses the tailnet

- **WHEN** the `azure` Caddy configuration is evaluated
- **THEN** the navidrome reverse proxy target is `raspi`'s tailnet address

### Requirement: EasyTier is retained as an opt-in fallback

The EasyTier mesh module, its flake registration, its `defaults.nix` values, its sops secret and its OpenTofu NSG rules SHALL be preserved, but SHALL be inactive by default. A single boolean in `defaults.nix` SHALL control the whole fallback: when it is off, no host activates the EasyTier service and no host decrypts the EasyTier secret; when it is on, the EasyTier mesh is configured as it was before Tailscale was introduced.

#### Scenario: Fallback disabled by default

- **WHEN** a host is evaluated with the fallback flag off
- **THEN** the EasyTier service is not enabled and the EasyTier sops secret is not declared
- **AND** the Tailscale service remains enabled

#### Scenario: Fallback can be switched back on

- **WHEN** the fallback flag is on
- **THEN** the EasyTier service and its sops secret are configured
- **AND** every host still evaluates, including the IP-forwarding sysctl shared with Tailscale
