{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.xcode;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  keybindingsDir = "Library/Developer/Xcode/UserData/KeyBindings";

  copyScript = lib.concatStrings (
    lib.mapAttrsToList (
      name: value:
      let
        source =
          if builtins.isPath value || lib.isDerivation value then
            toString value
          else
            toString (pkgs.writeText name value);
      in
      ''
        dst="$HOME/${keybindingsDir}/${name}"
        mkdir -p "$(dirname "$dst")"
        rm -f "$dst"
        cp ${lib.escapeShellArg source} "$dst"
      ''
    ) cfg.keybindings
  );
in
{
  options.programs.xcode = {
    enable = lib.mkEnableOption "Xcode keybindings management";

    keybindings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
      default = { };
      example = lib.literalExpression ''
        {
          "Custom.idekeybindings" = ./Custom.idekeybindings;
        }
      '';
      description = ''
        Xcode keybinding files to deploy to
        {file}`~/Library/Developer/Xcode/UserData/KeyBindings/`.

        Each attribute name is the target filename, e.g.
        {file}`Custom.idekeybindings`.
        The value is either a file path or the raw XML string content.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && isDarwin && cfg.keybindings != { }) {
      home.activation.xcodeKeybindings = lib.hm.dag.entryAfter [ "writeBoundary" ] copyScript;
    })

    {
      warnings = lib.optional (
        cfg.enable && !isDarwin
      ) "programs.xcode is only supported on Darwin platforms. Keybindings will not be deployed.";
    }
  ];
}
