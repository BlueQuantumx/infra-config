## 1. Configure nh in the MacBook home profile

- [x] 1.1 In `home-manager/luyan-macbook.nix`, add a `programs.nh` block that enables nh and sets `flake` to the repository's absolute path; leave `programs.nh.clean.enable` unset. Verify with `nix eval .#homeConfigurations."luyan@macbook".config.programs.nh.enable` returning `true`.
- [x] 1.2 Verify the nh flake environment variable is emitted: `nix eval .#homeConfigurations."luyan@macbook".config.home.sessionVariables.NH_FLAKE` returns the repository path.

## 2. Build and verify the profile

- [x] 2.1 Build the standalone home profile: `nix build .#homeConfigurations."luyan@macbook".activationPackage` succeeds, and `./result/home-path/bin/nh --version` prints an nh version.
- [x] 2.2 Confirm no second GC schedule is introduced: `nix eval .#homeConfigurations."luyan@macbook".config.programs.nh.clean.enable` returns `false`, and no `nh-clean` agent appears in the evaluated profile's launchd agents.

## 3. Final validation

- [x] 3.1 Run `nix flake check --no-build` and confirm all host checks still evaluate.
- [x] 3.2 From outside the repository with only `NH_FLAKE` set, run `nh darwin switch --dry` (resolves the Darwin target automatically) and `nh home switch --dry -c luyan@macbook` (resolves the home target with the configuration name); confirm both build without `--flake`.
