{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  programs.ghostty = {
    enable = true;

    package = lib.mkIf isDarwin pkgs.ghostty-bin;

    settings = {
      # 字体配置
      font-family = [
        "JetBrainsMono Nerd Font"
        "PingFang SC"
      ];
      font-size = 14;
      # 开启原生连字支持
      font-feature = [
        "calt"
        "liga"
        "dlig"
      ];

      # 主题与外观
      # 使用经过社区广泛测试且极具人气的内置主题，且支持跟随 macOS 系统自动切换深浅模式
      theme = "dark:Catppuccin Frappe,light:Catppuccin Latte";

      # macOS 原生视觉风格 (沉浸式标题栏与毛玻璃背景)
      macos-titlebar-style = "transparent";
      window-padding-x = 10;
      window-padding-y = 10;

      # 解决 macOS 下 Option 键作为 Alt 使用的问题
      macos-option-as-alt = true;

      # 悬挂终端 (Quake 风格顶部弹出终端)
      quick-terminal-position = "top";
      quick-terminal-animation-duration = 0.2;

      # 社区常用快捷键
      keybind = [
        # 呼出/隐藏悬挂终端 (全局快捷键 Cmd + `，可根据习惯改为任一组合键)
        "global:cmd+`=toggle_quick_terminal"

        # 分屏导航（Vim 风格）
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+l=goto_split:right"
        "ctrl+shift+k=goto_split:up"
        "ctrl+shift+j=goto_split:down"
        # 新建分屏
        "ctrl+shift+enter=new_split:down"
        "ctrl+shift+backspace=new_split:right"
        # 关闭当前分屏/标签
        "ctrl+shift+w=close_surface"
        # 标签页切换
        "ctrl+tab=next_tab"
        "ctrl+shift+tab=previous_tab"
      ];
    };

    # Shell 集成
    enableZshIntegration = true;
  };
}
