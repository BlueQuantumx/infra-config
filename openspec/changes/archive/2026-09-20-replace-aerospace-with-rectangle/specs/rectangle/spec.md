## Purpose

Declares how the MacBook's Rectangle window snapping is configured from the repository: how the application is installed and updated, where its preferences are declared, how those preferences reach the running application without seizing the preference domain, and what window behaviour they guarantee.

## ADDED Requirements

### Requirement: Rectangle is installed as a managed cask and configured from the MacBook profile

The MacBook darwin configuration SHALL declare the Rectangle application as a Homebrew cask, and the MacBook home profile SHALL declare Rectangle's preferences in `home-manager/modules/rectangle.nix`, imported from `home-manager/luyan-macbook.nix`. Application installation and preference declaration SHALL be separate: the cask owns the application binary, the home profile owns the preferences. Other hosts and home profiles SHALL NOT declare either.

#### Scenario: Cask is declared in the darwin configuration

- **WHEN** the MacBook darwin configuration is evaluated
- **THEN** the Rectangle cask appears in the declared Homebrew casks

#### Scenario: Preference module is imported by the MacBook home profile

- **WHEN** the MacBook home profile is evaluated
- **THEN** `targets.darwin.defaults."com.knollsoft.Rectangle"` is declared, and the declaration lives in `home-manager/modules/rectangle.nix`

#### Scenario: Other hosts are unaffected

- **WHEN** the flake's other host and home-manager configurations are evaluated
- **THEN** none of them declare the Rectangle cask or Rectangle preferences

### Requirement: Rectangle's preferences are declared through the home-manager module

The MacBook home profile SHALL declare Rectangle's preferences through home-manager's `programs.rectangle` module in `home-manager/modules/rectangle.nix`, rendering them into `~/Library/Preferences/com.knollsoft.Rectangle.plist`, and SHALL leave the application package to the Homebrew cask by setting `package = null`. Because the preference file is then owned by home-manager rather than by the application, the declared keys are the complete source of truth for the preference domain, and preference changes made inside the application are not persisted.

#### Scenario: Declared keys are rendered into the preference file

- **WHEN** the generated `com.knollsoft.Rectangle.plist` for the MacBook home profile is inspected
- **THEN** it contains the declared keys with the declared values

#### Scenario: The preference file is home-manager managed

- **WHEN** the activated preference file path is inspected
- **THEN** it is a home-manager link into the profile generation, so the application cannot write preference changes back through it

#### Scenario: The profile installs no application package

- **WHEN** the profile's Rectangle module is evaluated
- **THEN** no Rectangle package is added to the home environment, because the application comes from the Homebrew cask

#### Scenario: Undeclared state is not carried over

- **WHEN** the preference file is replaced by an activation while a different file already occupies that path
- **THEN** the previous file is not merged into the declared domain; activation either backs it up or stops with a collision error

### Requirement: Declared preferences cover startup, drag snapping and gaps

The declared preferences SHALL start Rectangle at login and SHALL give placed windows a non-zero gap from the screen edges. They SHALL declare Rectangle's drag-to-edge snapping explicitly in one of its determinate states rather than leaving it unset, so the application neither re-prompts about the conflict with the macOS built-in drag-to-edge tiling nor fights the declared value. Keyboard shortcut assignments SHALL NOT be declared, leaving Rectangle's built-in shortcuts in force and adjustable in the application.

#### Scenario: Startup and gap preferences are declared

- **WHEN** the module's declared preferences are inspected (in the evaluated configuration or the applied domain)
- **THEN** automatic start at login is enabled and the gap value is greater than zero

#### Scenario: Drag snapping is declared determinately

- **WHEN** the declared snapping preference is inspected
- **THEN** it holds the enabled or the disabled state, not the unset state, so the application's conflict check with the macOS built-in tiling cannot silently rewrite it

#### Scenario: Shortcut assignments are left to the application

- **WHEN** the declared preferences are inspected
- **THEN** they contain no keyboard shortcut assignments

#### Scenario: Rectangle is running after login

- **WHEN** the user logs in to the MacBook with the accessibility permission already granted
- **THEN** the Rectangle process is running without the user starting it by hand

### Requirement: Window actions move the focused window

With the accessibility permission granted, Rectangle SHALL move and resize the focused window for its window actions, so the snapping behaviour is available both from its keyboard shortcuts and from its action URLs.

#### Scenario: A half action resizes the focused window

- **WHEN** an action that snaps a window to a screen half is requested while an ordinary window is focused
- **THEN** that window's frame becomes the corresponding half of the screen's visible frame

#### Scenario: Accessibility permission is required, not assumed

- **WHEN** the accessibility permission has not been granted
- **THEN** the configuration still activates and starts Rectangle, and the window actions take effect once the permission is granted, without any change to the Nix configuration
