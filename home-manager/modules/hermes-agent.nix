# Appends the Hermes Agent snippet to the generated ~/.zshrc.
#
# The snippet prepends `$HOME/.local/bin` to `PATH` the way a hand-written
# dotfile would: the `case` guard makes it idempotent, so repeated sourcing
# (or a `PATH` that already contains the directory, e.g. from a login shell
# or `home.sessionVariables`) leaves it in place exactly once and keeps the
# user's own ordering.
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.hermes-agent;
in
{
  options.programs.hermes-agent = {
    enable = lib.mkEnableOption ''
      Hermes Agent command PATH snippet in zsh
    '';
  };

  config = lib.mkIf cfg.enable {
    # `mkAfter` keeps the snippet at the very end of `.zshrc`, so it wins over
    # anything earlier that reshapes `PATH`.
    programs.zsh.initContent = lib.mkAfter ''
      # Hermes Agent command
      case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
    '';

    warnings =
      lib.optional (cfg.enable && !config.programs.zsh.enable)
        "programs.hermes-agent requires programs.zsh.enable, but zsh is disabled: the PATH snippet will not be written.";
  };
}
