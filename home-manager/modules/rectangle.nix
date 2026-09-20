# Rectangle —— macOS 上的快捷键 / 拖拽分屏窗口管理器。
#
# 应用本体由 macOS 侧的 Homebrew cask 提供（见 hosts/macbook/configuration.nix 的
# homebrew.casks）。这里只声明它的偏好设置
#
# 注意：Rectangle 只在启动时读取偏好，改完这里的值要重启 Rectangle（或重新登录）才生效。
#
# 首次运行需要在「系统设置 → 隐私与安全性 → 辅助功能」里授权 Rectangle；
# cask 安装的 App 有 Developer ID 签名，授权在升级后依然有效。
{ ... }:
{
  # unable to declare homebrew pkgs in home-manager
  # homebrew.cask = [
  #   "rectangle"
  # ];
  programs.rectangle = {
    enable = true;
    # use homebrew
    package = null;
    defaults = {
      # 跟随登录启动（由 Rectangle 自己注册登录项）
      launchOnLogin = true;

      # 吸边 / 分屏后窗口与屏幕边缘留出的间隙（像素）
      gapSize = 8.0;

      # 拖到屏幕边缘吸附。Rectangle 的 OptionalBoolDefault 是整数三态：
      # 1 = 开启，2 = 关闭，0 = 未设置。
      # macOS 15+ 自带「拖拽窗口到屏幕边缘平铺」（com.apple.WindowManager 的
      # EnableTilingByEdgeDrag，默认开启）。两者同时开启时 Rectangle 会弹
      # "Conflict with macOS tiling" 对话框，并在选择「Disable in Rectangle」后
      # 自己把这里改写成 2 —— 也就是说声明 1 会被 App 覆盖，还要多弹一次框。
      # 因此这里显式声明为 2：边缘拖拽交给 macOS 自带实现，Rectangle 负责快捷键动作。
      # 若想反过来（关掉 macOS 自带平铺、用 Rectangle 的吸附），把这里改成 1，
      # 并在 hosts/macbook/configuration.nix 里把系统的 EnableTilingByEdgeDrag 设为 false。
      windowSnapping = 2;
    };
  };
}
