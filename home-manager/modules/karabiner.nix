# Karabiner-Elements —— macOS 上的键盘重映射工具（simple / complex modifications、
# 设备级 ignore、fn 键、虚拟键盘类型都写在同一个 JSON 里）。
#
# App 本体不在这里管（手动装在 /Applications/Karabiner-Elements.app），本模块只把
# 配置 ~/.config/karabiner/karabiner.json 声明式投放到位，内容原样来自
# home-manager/karabiner/karabiner.json。
#
# 为什么用「复制」而不是 home.file 的符号链接：Karabiner-Elements 的 GUI 会直接
# 改写 karabiner.json，保存时是「写临时文件 + rename」，会把指向 /nix/store 的符号
# 链接替换成普通文件；此后每次 switch，home.file 都会因为该路径被真实文件占用而
# 报错（non-force 冲突）。复制成普通文件则两边都成立：仓库是唯一事实来源，App 侧
# 的改动能落盘，并在下次 switch 时被覆盖回声明值。
#
# 注意：Karabiner-Elements 监视该文件的 mtime 并自动重载，switch 之后不用手动重启
# App；但 GUI 里改过的内容会在下次 switch 时被仓库里的版本覆盖。
{ lib, ... }:
let
  source = ../karabiner/karabiner.json;
in
{
  home.activation.karabinerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dst="$HOME/.config/karabiner/karabiner.json"
    if [ ! -f "$dst" ] || ! cmp -s ${source} "$dst"; then
      verboseEcho "Deploying Karabiner-Elements config to $dst"
      run mkdir -p "$(dirname "$dst")"
      # 用 install(1) 而不是 cp：store 里的源文件是只读的，cp 会把 0444 权限一起带
      # 到目标，Karabiner 的 GUI 就写不进去了。install -m 0644 保证目标可写。
      run install -m 0644 ${source} "$dst"
    fi
  '';
}
