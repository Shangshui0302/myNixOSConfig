# Noctalia Shell 使用指南

Noctalia 是本机的桌面 Shell 环境，替代传统的顶栏、Dock、应用启动器等组件，统一管理壁纸、配色、通知、锁屏等。

> **参考文档 (v5)**: `~/Documents/noctalia-docs-v5/`

## 面板布局

顶栏分三个区域：

| 区域 | Widget | 说明 |
|------|--------|------|
| 左 | 启动器 (🚀) | 点击打开应用启动器 |
| 左 | 时钟 | `HH:mm ddd, MMM dd` 格式 |
| 左 | 系统监视器 | CPU 使用率/温度/核心数 + 内存使用，紧凑模式 |
| 左 | 媒体面板 | 专辑封面、进度环、可视化效果（播放时显示） |
| 中 | 活动窗口 | 当前窗口标题，悬停滚动截断文本 |
| 中 | 工作区 | 数字索引标签，圆点指示占用状态，滚轮切换 |
| 中 | 特殊工作区 | 抽屉式弹出，含 messaging 工作区 |
| 中 | 工作区总览 | 点击进入 Exposé 风格总览 |
| 中 | GitHub 动态 | GitHub 通知/Star/Fork/PR 面板 |
| 中 | AI 助手 | Gemini 2.5 Flash 对话面板（右侧弹出，宽 520px） |
| 右 | 网络指示器 | 上传/下载速率 |
| 右 | 电池 | 简洁图形模式，无电池时隐藏 |
| 右 | 音量 | 悬停展开调整，中键打开 pavucontrol |
| 右 | 亮度 | 悬停展开调整 |
| 右 | 隐私指示器 | 麦克风/摄像头使用状态 |
| 右 | 截图/录屏 | 区域/窗口截图 + 录屏，编辑用 Swappy |
| 右 | HVE | Hyprland 可视化编辑器（主题热加载） |
| 右 | 通知历史 | 未读计数标记 |
| 右 | 系统托盘 | 固定 Chrome 图标，抽屉收纳其余 |
| 右 | 控制中心 | Noctalia 图标，点击打开 |

顶栏：不透明度 93%，胶囊背景，comfortable 密度，始终可见。

## 快捷键（与 Hyprland 绑定）

| 按键 | 功能 |
|------|------|
| `Super + Space` | 应用启动器 |
| `Super + K` | 控制中心 |
| `Super + ,` | 设置面板 |
| `Super + Tab` | 工作区总览 |

## 鼠标操作

| 操作 | 行为 |
|------|------|
| 滚轮（顶栏空白处） | 切换工作区 |
| 中键（顶栏空白处） | 打开设置 |
| 右键（顶栏空白处） | 打开控制中心（跟随鼠标） |

## 应用启动器

- **打开方式**：`Super + Space` 或点击顶栏 🚀 图标
- **剪贴板历史**：已启用，支持文本和图片，自动预览
- **固定应用**：Nemo、Google Chrome、Obsidian、QQ
- **排序**：按使用频率排序
- **视图模式**：列表，显示分类
- **终端命令**：foot

## 控制中心

点击顶栏最右侧图标或 `Super + K` 打开。

**左侧快捷操作：**
| 项目 | 说明 |
|------|------|
| Network | WiFi 管理（列表视图）、蓝牙管理、飞行模式 |
| Bluetooth | 蓝牙设备管理，自动连接已配对设备 |
| WallpaperSelector | 壁纸选择器 |
| NoctaliaPerformance | 性能模式（禁用桌面小组件） |
| Screen Toolkit | 屏幕取色、OCR |

**右侧快捷操作：**
| 项目 | 说明 |
|------|------|
| PowerProfile | 电源方案切换 |
| KeepAwake | 阻止自动休眠 |
| NightLight | 夜间色温（已配置自动调度） |
| DarkMode | 暗色模式切换 |
| Color Scheme Creator | 配色方案生成器 |

**卡片区域：** Profile、Shortcuts、Audio、Brightness、Weather、Media/Sysmon

## Dock

- **位置**：底部，自动隐藏
- **固定应用**：QQ
- **启动器图标**：使用发行版 Logo
- **分组**：同一应用窗口合并，圆点指示器，点击列表切换
- **行为**：仅显示当前屏幕的应用

## 壁纸管理

- **壁纸目录**：`~/Pictures/Wallpapers/`
- **填充模式**：crop（裁剪填充）
- **过渡效果**：fade / disc / stripes / wipe / pixelate / honeycomb（随机选取）
- **过渡时间**：1500ms
- **收藏壁纸**：yamadaryou.png，自动应用 yamadaryou 配色方案
- **多屏**：所有显示器使用同一壁纸
- **自动切换**：未启用（手动选择）

## 配色方案 (yamadaryou)

当前主题：**yamadaryou**（自定义 Material You 风格）

| 模式 | 主色 | 强调色 | 表面色 |
|------|------|--------|--------|
| 暗色 | `#ffec15` (金) | `#006ff1` (蓝) | `#000000` (黑) |
| 亮色 | `#0055ff` (蓝) | `#e6c814` (金) | `#fffaf3` (暖白) |

**调度模式**：根据地理位置（成都）自动切换暗色/亮色模式。
**模板同步**：Hyprland 边框、Qt/GTK 主题、Steam、Telegram 皮肤自动跟随配色。

暗色模式切换时：`color-scheme` 由 Noctalia GTK 模板通过 gsettings → portal 分发（避免 dconf/gsettings 双重写入导致 Chrome 闪烁）；hook 仅写入 `gtk-theme`、`gtk-application-prefer-dark-theme` 和 `qt5ct.conf`。

## 锁屏与空闲

| 事件 | 时间 | 说明 |
|------|------|------|
| 屏幕关闭 | 600 秒（10 分钟） | 5 秒淡出过渡 |
| 自动锁定 | 660 秒（11 分钟） | 屏幕关闭后 60 秒 |
| 自动休眠 | 1800 秒（30 分钟） | 锁定后 19 分钟 |

- 锁屏：模糊背景 (0.6)，显示时钟 + 密码输入
- 倒计时 10 秒，显示会话按钮（锁屏/休眠/重启/关机/注销）
- 锁屏媒体控件：已启用

## 通知与 OSD

| 项目 | 设置 |
|------|------|
| 位置 | 右上角 |
| 密度 | 紧凑 |
| 低/普通/紧急 | 3s / 8s / 15s |
| 媒体切换提示 | 启用 |
| 键盘布局提示 | 启用 |
| 电池提示 | 启用 |
| OSD 位置 | 顶部，2 秒自动消失 |

## 会话菜单

关机/重启/休眠/注销/锁定，支持倒计时 5 秒，居中显示。

## 常用操作流程

### 切换主题（暗色/亮色）

```
Super + K        # 打开控制中心
点击 DarkMode    # 切换暗色/亮色模式
# 自动触发 hook 写入 dconf 和 qt5ct
```

### 更换壁纸

```
Super + K        # 控制中心
WallpaperSelector # 浏览壁纸目录
点击选择          # 带过渡动画切换
```

### 查看系统性能

```
顶栏左侧系统监视器  # 实时 CPU/内存
Super + K → Media/Sysmon 卡片  # 详细信息
```

### 使用 AI 助手

```
点击顶栏 AI 助手面板     # 右侧弹出面板
输入问题                 # Gemini 2.5 Flash 回复
# 支持实时翻译（Google，自动检测→英文）
```

## 故障排查

```bash
# 重启 Noctalia Shell
pkill noctalia-shell; noctalia-shell &

# 查看日志
journalctl --user -u noctalia-shell -f

# 强制切换暗色模式
noctalia-shell ipc call darkMode setDark
noctalia-shell ipc call darkMode setLight
```
