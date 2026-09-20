# Tasks

## 1. Disable AeroSpace

- [x] 1.1 Remove the `./modules/aerospace.nix` import from `home-manager/luyan-macbook.nix` and document the module as dormant in its header; verified `nix eval .#homeConfigurations."luyan@macbook".config.programs.aerospace.enable` returns `false`.
- [x] 1.2 Switch the home profile and verify no residual state: no `org.nix-community.home.aerospace` in `launchctl list`, `~/.aerospace.toml` gone, no AeroSpace process running.

## 2. Rectangle configuration and application

- [x] 2.1 Create `home-manager/modules/rectangle.nix` declaring the preferences through `programs.rectangle` with `package = null`; verify the generated `com.knollsoft.Rectangle.plist` renders the declared keys.
- [x] 2.2 Import the module from `home-manager/luyan-macbook.nix`; verified no other host or home profile declares the Rectangle module or the `com.knollsoft.Rectangle` domain.
- [x] 2.3 Declare the Rectangle cask in `hosts/macbook/configuration.nix`; verify it appears in the darwin configuration's `homebrew.casks`.
- [x] 2.4 Install the application and verify it is present and signed: `/Applications/Rectangle.app` version 1.100, Developer ID signed (Team XSYZ3E4B7D), so its accessibility grant survives upgrades.
- [x] 2.5 Launch Rectangle, grant the accessibility permission, and verify a window action applies the declared gap; measured on a 1512x949 visible frame: `left-half` gave `x=8, y=41, w=740, h=933` (half width and full height minus 8px on every edge), `right-half` gave `x=764` on the same screen.
- [ ] 2.6 Verify a profile activation installs the preference file as a home-manager link. Not done: the activation currently stops with `Existing file '…/com.knollsoft.Rectangle.plist' would be clobbered`, because a real preference file left by the application occupies that path; it needs `home-manager switch -b backup`, a configured `home-manager.backupFileExtension`/`backupCommand`, or `force = true` on that file entry.
- [ ] 2.7 Verify Rectangle registers its login item at launch (`launchOnLogin` is declared `true`). Not verified: `sfltool dumpbtm` reports nothing readable for the app from a non-root shell.

## 3. Repository-level validation

- [ ] 3.1 Run `nix flake check --no-build` and confirm every host check still evaluates. Not run for this change.
- [x] 3.2 Run `openspec validate replace-aerospace-with-rectangle --strict` and confirm the change validates.
