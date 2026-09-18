# Tasks

## 1. Module and profile wiring

- [x] 1.1 Create `home-manager/modules/aerospace.nix` enabling `programs.aerospace` with `launchd.enable`, a `package` selection and a `settings` attribute; verify with `nix eval .#homeConfigurations."luyan@macbook".config.programs.aerospace.enable` returning `true`.
- [x] 1.2 Guard the module on Darwin (`pkgs.stdenv.hostPlatform.isDarwin`) so non-Darwin profiles that ever import it stay inert; verify the option is unset when the guard is false.
- [x] 1.3 Import the module from `home-manager/luyan-macbook.nix` alongside the other macOS-only modules; verify the import is present and no other host or profile references it.
- [x] 1.4 Declare the launchd agent expectations through the module; verify `nix eval .#homeConfigurations."luyan@macbook".config.launchd.agents.aerospace.enable` returns `true`.

## 2. Build and inspect the generated artefacts

- [x] 2.1 Build the standalone profile: `nix build --no-link '.#homeConfigurations."luyan@macbook".activationPackage'` succeeds.
- [x] 2.2 Inspect the generated TOML in the profile generation and confirm the config file is complete, that `start-at-login = false` and `after-login-command = []` are forced, and that the main and service binding modes are fully spelled out.
- [x] 2.3 Inspect the generated launchd plist and confirm `RunAtLoad`, `KeepAlive` and the program path into the AeroSpace package's application bundle.

## 3. Activate and verify on the machine

- [x] 3.1 Switch the profile (`home-manager switch --flake .#luyan@macbook`) and verify `~/.aerospace.toml` is a home-manager link into the profile generation.
- [x] 3.2 Verify the agent is loaded and, before the accessibility grant, that the daemon process stays resident instead of exiting repeatedly (`launchctl print gui/$(id -u)/org.nix-community.home.aerospace` shows `runs = 1` and `job state = running`).
- [x] 3.3 After granting Accessibility, verify the client talks to the daemon: `aerospace list-workspaces --all` returns the configured persistent workspaces.
- [x] 3.4 Verify the effective config is the generated file and its bindings parsed: `aerospace config --config-path` and `aerospace config --all-keys`.
- [x] 3.5 Verify real window management: switch workspaces with `aerospace workspace <name>` and confirm the focused workspace changes; open a panel application and confirm `aerospace list-windows --all --format '%{window-parent-container-layout}'` reports its window as floating.

## 4. Repository-level validation

- [x] 4.1 Run `nix flake check --no-build` and confirm every host check still evaluates.
- [x] 4.2 Run `openspec validate add-aerospace-macbook --strict` and confirm the change validates.
