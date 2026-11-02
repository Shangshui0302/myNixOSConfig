---
title: NextKDE 桌面变体
category: 桌面
tags: [nextkde, kos, plasma, sddm, specialisation]
updated: 2026-11-02
---

# NextKDE 桌面变体

NextKDE 是独立的 NixOS specialisation，使用 Plasma Wayland、SDDM 和 KOS 桌面组件。它复用系统与用户基础配置，但不继承主桌面的 Hyprland/niri 或 Darkman；Matugen 仅作为 KDE 应用色板生成器使用。当前配置需要用户应用并在实际会话中验收。

## 构建和进入

NextKDE 上游提交固定在 `3fa1d7006869bbd3404a05d362c6e6028e0fe3da`，使用根 flake 的 nixpkgs。该开发提交的上游版本字段仍为 `0.1.0-dev`，实际身份以完整 revision 为准。可单独构建包：

```bash
nix build path:.#nextkde -L --no-link --print-out-paths
```

在修改尚未合并前，以下命令须在本任务 worktree 中执行；确认希望安装候选配置后，由用户手动运行：

```bash
sudo nixos-rebuild boot --flake path:.#MechRevo-NixOS
```

然后重启，在启动菜单选择该代的 `nextkde` 变体，进入 SDDM 并登录 Plasma。`boot` 为下次启动准备配置，不会在当前会话切换显示管理器。返回主桌面时重启并选择普通主配置；也可选择旧 generation。具体菜单名称以实际显示为准。

## 桌面与共享数据

KOS 的服务随 Plasma 工作区启动和停止。会话集成统一引用本地补丁包，不再同时安装原版和补丁版 Shell；原生插件仍复用固定上游的构建。Shell 文件仅在来源包变化或部署不完整时重新复制，同一代次登录会跳过复制。需要恢复手动改坏的文件时可运行 `KOS_SYNC_FORCE=1 kos-ctl sync`，然后重新登录。控制中心和启动台已去掉上游的最低模糊限制；液态玻璃的模糊滑杆为 0 时，两者提交的 Gaussian sigma 也为 0，调高后仍按原比例增加。这依赖 KOS 的 `glass` 插件实际加载；普通 KWin `blur` 不处理该参数。Plasma shell 保留壁纸，KOS 负责面板、Dock 和桌面文件；KScreenLocker 使用 KOS 锁屏主题，认证机制不变。默认文件管理器是 Dolphin；Strata 仅在主桌面安装。输入法由 `kos-colors` 选择独立的 Mellow KDE 明暗色板，保留半透明但关闭候选框背景模糊；字体、词库及候选布局保持原设置。

KDE 强调色与深浅模式驱动独立的应用颜色分发，缓存位于 `~/.cache/kos-colors/`，更新 Fcitx5、Neovim、Zellij、btop、Yazi 和 mpv。由 `kos-colors.path` 在 KDE 配置变化时触发 `kos-colors.service` 单次同步，登录也运行一次；无需额外常驻分发进程。KDE 启用“从当前壁纸获取强调色”后，KOS/Plasma 换壁纸会驱动更新。只更新应用色板，不改 KDE 全局主题、图标、装饰或 KOS 面板。完整边界见[深色模式与配色分发](darkmode.md#桌面变体的分发边界)。

## 已补齐的桌面功能

以下包、服务及初始化仅由 `host/nextkde/`、`home/nextkde.nix` 引入：

- 剪贴板历史：`wl-clipboard` 和 `cliphist`，由 KOS 平台服务管理监听；`Meta+V` 打开。
- 终端：Foot，保留原有字体、Fish、滚动缓冲和 0.55 背景透明度；通知使用桌面通知接口，不调用 Hyprland 的聚焦命令。可从启动器打开或运行 `foot`。
- 启动环境：KOS 服务使用完整的 NixOS profile 路径，并优先查找 `/run/wrappers/bin`；从 KOS 打开的应用和终端可以找到正常的 `sudo` 及用户安装的程序。
- 台前调度：提供上游脚本需要的 `qdbus6` 兼容入口，指向 Nixpkgs 的 Qt 6 `qdbus`；`Meta+Y` 切换台前调度，插件按上游流程加载，不强制常驻启用。
- 输入法：通过 `/etc/xdg/kwinrc` 的 `[Wayland] InputMethod[$i]` 固定选择 Fcitx 5 Wayland Launcher，由 KWin 提供原生输入法连接。该单键仅在 NextKDE 受 Nix 管理，虚拟键盘设置页不能覆盖；其他 KWin 设置仍可写，主桌面不受影响。
- Dolphin 配色：NextKDE 将应用配色固定为“跟随系统”。KOS 深浅色切换使用 `WhiteSur` / `WhiteSurDark`，同时控制 Dolphin 的背景、交替行和文字；`kos-colors` 同步 Kvantum 明暗主题，已运行 Qt 应用可能需要重启。
- Qt 输入法：NextKDE 清空全局 `QT_IM_MODULE`，以 `QT_IM_MODULES=wayland;fcitx;ibus` 优先使用 KWin 原生输入通道。系统设置、搜索等 Qt 应用不再优先使用只读浅色 `Theme` 的客户端候选框，由 Fcitx 按系统 Portal 选择现有明暗主题；词库与用户设置不迁移。
- 亮度调节：保留 KDE 接口，并提供 `brightnessctl` 回退。
- 配套应用：日历、待办、计算器、天气，以及独立的 KMusic（命令 `kmusic`、启动器入口 KMusic）；KMusic 与主配置共享，支持本地音乐和在线音源，无自动启动服务。日历与待办共用 KOS PIM 服务，随 Plasma 登录启动，桌面卡片无需先手动打开应用即可读取数据。
- 壁纸取色：启动前将有效的 `ShellPackage` 单键写入用户 `plasmashellrc`，让上游只能读取用户文件的取色器找到正确的壁纸配置；保留其他设置及用户显式选择。
- 音频与文件操作：补齐 `pactl` 和 `gio`，供应用混音、音频设备切换、回收站与打开方式使用；音频服务仍使用现有 PipeWire。
- 切换用户：将上游 LightDM 命令兼容到 KDE/SDDM 流程，先锁屏，再返回登录界面。
- 锁屏：静态主题文件由 Home Manager 管理，天气数据文件保持可写；应用时自动迁移旧的整目录链接，解决天气发布失败。
- 空间壁纸：Nix 固定下载并校验两个模型，合计约 265 MiB；首次登录复制到可写缓存并启用服务和空间壁纸。首次图片处理可能需要等待，实际渲染效果须登录后验收。
- KDE 设置管理（plasma-manager）：在 `home/nextkde.nix` 接入 `plasma-manager` 模块并提供 `rc2nix` 工具。采用增量合并方式管理 KDE 配置，不破坏文件的运行时可写性；KOS 独立负责桌面面板与 Dock，因此不使用 `programs.plasma.panels`，KWin 行为、快捷键、窗口规则与外设可通过 `programs.plasma` 声明式管理。可以通过终端运行 `rc2nix` 快速提取当前手动调好的配置。

空间壁纸初始化只运行一次，保留 macOS/liquid 等现有外观字段。不另存配置备份，完成标记为 `~/.local/state/quickshell/kos/appearance/.spatial-bootstrap-v1`。之后在 KOS 设置中关闭功能或清理模型，后续登录不会强行恢复。遵循 `XDG_STATE_HOME` 与 `XDG_CACHE_HOME`；默认模型位置为 `~/.cache/liquid-shell/models/`。Nix store 仍保存固定资源，清理缓存不会删除 store 中的副本。

独立构建入口：

```bash
nix build path:.#nextkde-shell path:.#nextkde-sync-shell path:.#nextkde-apps path:.#nextkde-spatial-models path:.#kmusic --no-link
```

`Meta+Space` 打开启动器，`Meta+B` 打开控制中心；这些快捷键由 KOS 注册。Dock 与外观保留当前选择，可继续在 KOS 设置中调整。


## GUI 调整与 HM 固化

先在 Plasma GUI 调整并确认效果，再对照 `rc2nix -n` 与当前 Nix 声明，把需要长期保留的值写入 `home/nextkde.nix`。`rc2nix` 是取证辅助，不能将整份输出直接导入；它也会包含默认快捷键、最近文件、窗口布局等状态。

固化采用增量合并，保留 GUI 可写性；下次应用 HM 会恢复已声明的值。因此 GUI 调整满意后，应先同步 Nix，再 rebuild，避免新偏好被旧声明覆盖。

已纳入的当前偏好：

- 3 个虚拟桌面、单行排列；左下角显示桌面，右上角打开 KRunner；夜间颜色关闭。
- 摇晃窗口、透明效果、对话框薄片效果、最小化所有窗口脚本与桌面切换提示。
- `Meta+Shift+D` 最小化所有窗口、`Meta+Shift+O` 最小化其他窗口，`Meta+A` / `Meta+Shift+A` 切换活动。
- US 键盘布局、触摸板开启且自然滚动、该设备的鼠标关闭自然滚动；中文区域格式。
- 沿用设备自动挂载开关；Dolphin 面板不锁定、位置图标固定 22；Spectacle 自动保存截图并复制图像，保存到 `Pictures/Screenshots`。
- 壁纸取强调色、自动明暗外观以及已有 WhiteSur 配色设置；字体渲染偏好见下方排障条目。

KOS 的玻璃参数、面板、Dock 和快捷键仍归 KOS；动态颜色、显示器标识/缩放状态、虚拟桌面 UUID、最近文件和设备挂载历史不导入。当前 `kwinrulesrc` 仅有残留的 `steam` 排序项，没有可迁入的完整窗口规则。

## 状态边界

NextKDE 撤销主桌面留下的 Flatpak 全局 `GTK_THEME`，让沙箱应用自行读取桌面主题；其它 Flatpak 权限和环境覆盖继续保留。设备挂载由 KDE 提供，不另启动 udiskie。

各变体使用同一个用户家目录。应用写入的设置、数据和状态不会随系统 generation 回滚；切换或回退系统时，这些可写文件仍可能影响其他会话。

Home Manager 不生成配置备份；切回主桌面时直接接管 GTK4 主题文件和 Hyprland 自动生成的示例配置。旧 generation 仍使用旧策略，应从新版普通主配置返回 Hyprland/niri。

`/etc/xdg/kwinrc` 保留系统级固定 Fcitx 输入法选择（`InputMethod[$i]`），`/etc/xdg/dolphinrc` 保留系统级配色覆盖（`ColorScheme[$i]=`），防止污染共享 `$HOME` 下的 `~/.config/dolphinrc`。KWin 插件（模糊/玻璃/桥接/上下文菜单/Dock动画）、窗口装饰、WhiteSur 明暗外观包默认值以及 `plasmashellrc` 的 `ShellPackage` 均已迁移至 Home Manager（`home/nextkde.nix` 中的 `programs.plasma.configFile`），由 Home Manager 声明式写入用户配置并保持增量合并。WhiteSur 外观包默认值由 plasma-manager 管理；KOS 平台包只保留 WhiteSur 明暗配色名称替换。Plasma 会话提供 `plasma-apply-colorscheme`，正常切换走配色工具，不应用整套全局主题；不再维护删除上游缺失工具回退分支的补丁。

用户的 `~/.config/kwinrc` 与 `~/.config/plasmashellrc` 由 Home Manager 声明基础项，其余运行时配置仍由 KOS 与 Plasma 在用户层正常写入，除受管理的 Fcitx `InputMethod` 单键外保持可写。上述配置仅在 NextKDE 会话生效；已有共享应用数据不做迁移。

## 故障排查

- **Fcitx5 强调色变化，以为 KDE 正在运行 Matugen**：旧版本沿用主桌面留下的 Matugen 色板。当前 `kos-colors` 从 KDE 强调色生成独立的 `mellow-kde` / `mellow-kde-dark`，不改主桌面主题；模式变化只切换已生成的色板。
- **重启后图标、装饰回到 Breeze**：当前版本补齐可覆盖的 WhiteSur 全局包默认值；先前仅选择组件或明暗主题对、没有有效全局包选择时，Plasma 可能以 Breeze 生成登录默认值。已有用户选择仍优先，重启后的实际持久性须登录验收。

- **登录后没有面板或 Dock，QuickShell 未启动**：若日志出现 `kos-shell.service/start deleted to break ordering cycle`，旧配置的 PIM 服务仍依赖 `graphical-session.target`，与 Plasma 工作区启动顺序形成循环。修复版本完整替换 PIM unit 并保留 D-Bus 就绪语义；空的 `After=` 覆盖项无法删除已有依赖。安装新版并重新登录后检查 `systemctl --user status kos-shell kos-pim-service`。
- **资源调度提示缺少 fg-schedd**：它是上游设置页检测的外部守护程序，与台前侧栏和窗口动画分开。截至 2026-10-30，当前固定源码和公开发行附件中未找到其实现或安装包，因此本配置未安装，也未用同名占位程序掩盖检测。需要上游提供可核验来源后才能继续集成。
- **台前调度开关无效**：若 `kos-shell` 日志包含 `qdbus6: 未找到命令`，说明仍在运行缺少兼容入口的旧 generation；安装新版 NextKDE 后重试。插件 `stageanim13` 已随 KOS 安装，兼容入口只补命令名称。
- **每次登录都要重选 Fcitx 虚拟键盘**：新版配置固定 KWin 启动入口，覆盖用户文件中的空值、旧路径及错误转义键。安装后需重新进入 NextKDE 会话才能验证开机连接；无需手改用户 `kwinrc` 或反复重启 Fcitx。
- **Dolphin 出现黑白交替行、文字看不清或不跟随深浅色**：旧的 `dolphinrc` 可能固定了 Matugen 配色，与当前 KDE 配色混用。新版 NextKDE 通过 `/etc/xdg/dolphinrc` 的 `[UiSettings] ColorScheme[$i]=` 覆盖该选择；安装后重新打开 Dolphin，应用级配色应为跟随系统。
- **WhiteSur 配色切换后变回微风**：锁定的上游 KOS 将应用配色写死为 Breeze。本变体使用 `nextkde-platform-whitesur` 修正为 WhiteSur 明暗配色，并安装 `whitesur-kde` 提供资源。安装新版并重新登录后，在 KOS 中切换一次明暗即可应用；Dolphin 保持“跟随系统”，无需单独选择 WhiteSur。这里只切换配色，不应用完整全局主题，也不替换图标、窗口装饰或控件样式。已有用户目录中的同名 WhiteSur 配色优先于系统包。
- **系统设置、搜索中的输入法候选框一直是浅色**：新版会话改走 KWin 原生输入协议，需要重新登录使应用获得新环境；Fcitx 的 `UseDarkTheme=True` 才会跟随系统。少数旧 Qt 5 XWayland 应用若无法输入，可仅对该应用指定 `QT_IM_MODULE=fcitx`，不要重新设置整个会话。
- **sudo 报缺少 setuid 权限**：旧版 KOS 服务的精简 PATH 会误用 `/run/current-system/sw/bin/sudo`。用 `/run/wrappers/bin/sudo nixos-rebuild boot --flake path:.#MechRevo-NixOS` 安装修复后，重启进入新版 NextKDE；已有终端不会自动获得新环境。正常情况下 `command -v sudo` 应输出 `/run/wrappers/bin/sudo`，无需修改 sudo 文件权限。
- **登录后界面异常**：先检查是否从启动菜单进入了 `nextkde`，并查看 `journalctl --user -b` 中 KOS 和 Plasma 的日志。系统构建成功本身不能证明桌面运行正常。
- **效果、装饰或壁纸不符合预期**：检查上述两个用户配置文件是否已有覆盖项，并与 `/etc/xdg/` 中的默认值比较；按需自行调整。
- **目录打开了其他程序**：用户的 `~/.config/mimeapps.list` 中已有目录关联可能优先于系统默认值。详见[文件管理器与归档工具](../productivity/files.md)。
- **字体抗锯齿设置**：沿用已选的抗锯齿开启、RGB 子像素和 full hinting，由 `home/nextkde.nix` 中 HM 原生字体选项和 plasma-manager 管理。Plasma 6.8.1 的字体 GUI 可能选中 HM 的字体配置并将链接改写为普通文件，导致后续 HM 激活报 `would be clobbered`。允许继续在 GUI 中试调，满意后再把实际值同步回 Nix。若 GUI 把 HM 链接变成普通文件，核对差异并保留偏好后一次性移开冲突文件，由 HM 下次应用恢复管理；不设置只读标记、全局备份或长期强制覆盖。
- **rebuild 后 Mellow 仍模糊或新配置未出现**：先检查 `systemctl status home-manager-lishangshui.service`。若 Home Manager 激活失败，系统代次更新不等于用户配置已安装。遇到 `would be clobbered` 时，先核对报错文件的内容和来源，再一次性备份移开该文件；不要为单个冲突启用全局覆盖或备份策略。激活成功并重新登录后应有 `~/.local/share/fcitx5/themes/mellow-kde{,-dark}`，且 `classicui.conf` 选择对应主题。用 `qdbus org.kde.KWin /Effects org.kde.kwin.Effects.loadedEffects` 检查运行效果：应有 `glass`，不应有独立的 `blur`；若仍只加载 `blur`，控制中心/启动台的零 sigma 不会由 KOS 插件处理，不能靠继续修改 QML 半径修复。
- **需要返回原桌面**：重启后在启动菜单选择普通主配置或旧 generation；用户家目录中的可写状态不会自动回退。

## 相关链接

- [架构总览](../architecture/index.md)
- [Flake 配置管理](../architecture/flake.md)
- [文件管理器与归档工具](../productivity/files.md)
