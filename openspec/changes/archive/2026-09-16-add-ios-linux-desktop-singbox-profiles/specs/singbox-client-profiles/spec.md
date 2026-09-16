## Purpose

Defines which sing-box client profile templates this repo ships and the per-platform shape of each, so every supported device class can reach the tailnet with its own identity while sharing the routing and DNS rules of its template version.

## ADDED Requirements

### Requirement: Client profile coverage per template version

The template set SHALL provide a sing-box client profile for every supported device class in each maintained template version under `hosts/azure/substore-templates/<version>/`.

#### Scenario: Profile present in every maintained version
- **WHEN** a device class is supported by the repo
- **THEN** a matching profile file exists in every maintained template version directory

### Requirement: Distinct tailnet identity per remote device profile

Each remote-device profile SHALL declare its own Tailscale endpoint identity, using a distinct auth-key placeholder and hostname, and SHALL NOT reuse another profile's identity.

#### Scenario: Devices authenticate as separate nodes
- **WHEN** two remote-device profiles are materialized and run at the same time
- **THEN** each authenticates to the tailnet as its own node rather than sharing one identity

### Requirement: Platform-appropriate routing behavior

A profile SHALL retain the shared routing and DNS rule set of its template version while omitting rules and inbound options that the target platform cannot support.

#### Scenario: Mobile profile omits process-based routing
- **WHEN** a mobile profile is loaded on its target platform
- **THEN** it contains no process-inspection routing and no Linux-only inbound options

### Requirement: Platform-appropriate control surface

A profile SHALL expose only the control surface supported by its target platform, and any exposed API service SHALL ship with its dashboard support intact.

#### Scenario: Mobile profile exposes the API surface only
- **WHEN** the mobile profile's control surface is inspected
- **THEN** the API service and its dashboard are present and the alternate clash control surface is absent

### Requirement: Template version compatibility

A profile SHALL remain valid for the sing-box version its template directory targets. When a requested control surface relies on configuration unavailable in that version, the profile SHALL reproduce the companion configuration that version requires or omit the unsupported surface.

#### Scenario: Control surface on an older template version
- **WHEN** a profile targets a template version whose schema lacks part of a requested control surface
- **THEN** the profile either supplies that version's required companion configuration or omits the unsupported surface
