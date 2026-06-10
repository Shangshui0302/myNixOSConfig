# fcitx5 在 Qt 应用中显示浅色主题

## 状态
**OPEN** | 优先级: 中 | 创建: 2026-06-10

## 现象
- fcitx5 候选窗在 Noctalia (Quickshell) 和其他 Qt 应用中显示**浅色主题 + 锯齿**
- 在其他应用 (GTK/foot/Chrome) 中正常深色
- 全局 `color-scheme` 已确认为 `prefer-dark` (uint32 1)

## 已确认
- fcitx5 通过 D-Bus portal 读取全局 `color-scheme`，**不逐窗口切换**
- 问题影响所有 Qt 应用 (ghostwriter 同现)，非 Noctalia 独有
- `QT_IM_MODULE=fcitx` 已设置

## 方向
- Qt 应用的 fcitx5 IM module 渲染路径与 Wayland text-input 协议路径不同
- 需排查 fcitx5-qt module 的主题继承/渲染管线

## 临时绕过
- `~/.config/fcitx5/conf/classicui.conf`: `UseDarkTheme=False` + `Theme=mellow-wechat-dark` 硬编码暗色主题
