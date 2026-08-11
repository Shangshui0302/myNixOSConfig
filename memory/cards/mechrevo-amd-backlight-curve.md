---
id: mechrevo-amd-backlight-curve
type: hardware
tags: [mechrevo, amd, backlight, display, 780M, kernel]
date: 2026-08-07
---

# 机械革命无界14X AMD 背光曲线溢出

## 问题

Noctalia 亮度调到 100% 时屏幕反而全黑。写 `amdgpu_bl1/brightness` 超过约 64650 时 `actual_brightness` 归零。内核日志：`amdgpu: [drm] Using custom brightness curve`。

## 根因

不是 PWM 反转、也不是裸满量程溢出。amdgpu 自内核 6.15+ 启用面板固件的 **custom brightness curve**（非线性映射，输入信号恒为 0–255），驱动把用户写入值经曲线插值后输出，曲线顶端增益 >1，结果超过 16-bit 上限（65535）后回绕溢出为 0。本机实测：set=64500→actual=65535（触顶），set=64800→actual=0（溢出）。

## 决策

`host/boot.nix` 加内核参数 `amdgpu.dcdebugmask=0x40000`（`DC_DISABLE_CUSTOM_BRIGHTNESS_CURVE`），禁用固件曲线，恢复线性映射（set=X → actual≈X）。已撤销 deepseek 早前基于错误"PWM 反转"判断的 `acpi_backlight=native`/`acpi_video`/`abmlevel=0`。2026-08-11 曾尝试叠加 0x10+0x400（禁 PSR/Replay）修 niri 雪花点，实测无效已回退，见 [[memory/cards/mechrevo-psr-snow-artifacts]]。

## Why

`0x40000` 对应内核 `enum DC_DEBUG_MASK` 里的 `DC_DISABLE_CUSTOM_BRIGHTNESS_CURVE`（源码确认），是官方开关而非偏方。禁用曲线后顶端不再放大溢出，且与内核版本解耦——不必冒险升级到 6.18+/7.x（那里有 RDNA 硬挂起回归，见 `amd-kernel-stay-lts`）。

## How to apply

- 配置位置：`host/boot.nix` → `boot.kernelParams = [ "amdgpu.dcdebugmask=0x40000" ]`
- kernelParams 改动需 reboot 才生效
- 重启后验证：`cat /sys/module/amdgpu/parameters/dcdebugmask` == `262144`；写 65535 后 `actual_brightness` ~65535 而非 0
- 未来内核若修复 curve（0–255↔0–65535 换算），可尝试移除此位测试

相关: [[memory/cards/amd-kernel-stay-lts]] | [[memory/cards/hyprland-056-blur-amd]] | issues/archived/backlight-curve-overflow.md
