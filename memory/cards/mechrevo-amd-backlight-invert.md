---
id: mechrevo-amd-backlight-invert
type: hardware
tags: [mechrevo, amd, backlight, display, 780M]
date: 2026-08-07
---

# 机械革命无界14X AMD 背光 PWM 反转

## 问题

Noctalia 亮度调到 100% 时屏幕反而最暗。`brightness` sysfs 写 65535 (max) → `actual_brightness` 返回 0 → 屏幕最暗。

## 根因

机械革命 WUJIE14XA (MechRevo 无界14X) 的 AMD 780M 集成 GPU 的 PWM 背光控制器是**反转**的：sysfs 值越大 → 物理亮度越低。这是硬件接线（active-low PWM）导致，AMD GPU 驱动未包含此机型的 DMI quirk。

仅有 `amdgpu_bl1` 一个背光接口，`scale = non-linear`，`type = raw`。

## 决策

尝试通过内核参数 `acpi_backlight=native` + 加载 `acpi_video` 模块，暴露 ACPI 背光接口（可能为非反转）。

配置位置：`host/boot.nix` → `boot.kernelParams = [ "acpi_backlight=native" ]` + `boot.kernelModules = [ "acpi_video" ]`

## 待验证

重启后检查：
```bash
ls /sys/class/backlight/  # 是否出现 acpi_video0
```
- 若 `acpi_video0` 出现且亮度正常 → 问题解决
- 若未出现或同样反转 → 需要备选方案（内核 patch 或 userspace 反转脚本）

## 备选方案

若 ACPI 背光不可用，需通过内核 DMI quirk 或 userspace 脚本将写入 sysfs 的值反转（`max - value`）。
