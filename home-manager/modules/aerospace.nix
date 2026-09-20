# AeroSpace —— macOS 上 i3 风格的平铺窗口管理器。
#
# 当前状态：**未启用**。这个模块不再被 home-manager/luyan-macbook.nix 引入
# （2026-09-18 起改用 Rectangle），保留下来是为了随时一行 import 就能切回。
# 未被引入时它不产生任何效果：没有 launchd agent、没有 ~/.aerospace.toml。
# 要重新启用：在 luyan-macbook.nix 的 macOS-only 列表里加回
# `./modules/aerospace.nix`，并在「系统设置 → 隐私与安全性 → 辅助功能」里
# 重新勾选 AeroSpace（store 里的 App 是 adhoc 签名，换了 store 路径就要重新授权）。
#
# home-manager 负责生成 ~/.config/aerospace/aerospace.toml，并通过 launchd 托管
# 进程（programs.aerospace.launchd）。所以 AeroSpace 自身的 start-at-login 与
# after-login-command 由模块强制覆盖为 false/[]，不要在 settings 里设置它们。
#
# 首次启用后需要在「系统设置 → 隐私与安全性 → 辅助功能」里授权 AeroSpace。
{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  programs.aerospace = {
    enable = lib.mkIf isDarwin true;

    # 稳定版 26.05 只有 0.20.3：未授权辅助功能时会 `tccutil reset` 后直接退出，
    # launchd 的 KeepAlive 于是每 10 秒重启一次并反复弹权限框。0.21.x 改为原地
    # 等待授权（托盘图标提示），所以这里用 unstable 的包。
    package = lib.mkIf isDarwin pkgs.unstable.aerospace;

    # 登录后由 launchd 拉起并保持存活，崩溃自动重启
    launchd.enable = lib.mkIf isDarwin true;

    settings = {
      # v2 才支持 persistent-workspaces 等新键
      config-version = 2;

      # 容器归一化：合并同向嵌套容器、翻转方向冲突的嵌套容器
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      accordion-padding = 30;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # 焦点跨显示器移动时把鼠标一起带过去
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      # 误触 cmd+h 隐藏应用后，切回该应用时自动恢复窗口
      automatically-unhide-macos-hidden-apps = true;

      # 空工作区也常驻，alt-<数字> 可以直接跳过去
      persistent-workspaces = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];

      gaps = {
        inner = {
          horizontal = 8;
          vertical = 8;
        };
        outer = {
          left = 8;
          bottom = 8;
          top = 8;
          right = 8;
        };
      };

      # 面板型窗口不参与平铺
      on-window-detected = [
        {
          "if" = {
            app-id = "com.apple.systempreferences";
          };
          run = "layout floating";
        }
        {
          "if" = {
            app-id = "com.apple.calculator";
          };
          run = "layout floating";
        }
      ];

      # mode 绑定不会从默认配置继承，必须完整写出
      mode.main.binding = {
        # 焦点
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # 移动窗口
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # 调整窗口尺寸
        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        # 切换工作区
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # 把聚焦窗口送到工作区
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        # 上一个工作区 / 把工作区丢到下个显示器
        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        # 布局：平铺 / 手风琴
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        # 全屏、浮动切换、关闭窗口
        alt-f = "fullscreen";
        alt-shift-f = "layout floating tiling";
        alt-shift-q = "close";

        # 进入 service 模式
        alt-shift-semicolon = "mode service";
      };

      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        # 重置当前工作区布局
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];

        # 把聚焦窗口并入相邻容器
        alt-shift-h = [
          "join-with left"
          "mode main"
        ];
        alt-shift-j = [
          "join-with down"
          "mode main"
        ];
        alt-shift-k = [
          "join-with up"
          "mode main"
        ];
        alt-shift-l = [
          "join-with right"
          "mode main"
        ];
      };
    };
  };
}
