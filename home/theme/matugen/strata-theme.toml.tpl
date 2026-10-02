# Strata 自定义主题（Matugen → Material 3 语义角色）
#
# 落点：~/.config/strata/themes/<id>.toml，文件名 stem 即主题 id（这里是 matugen），
# 文件内的 name 只是显示名。Strata 只在启动时扫描该目录一次，且不监听文件变化，
# 所以换壁纸/深浅色后需要重开 Strata 才会读入新配色。
#
# 必需键：name + background/surface/text/accent/muted/highlight/border/dim_text；
# danger 缺省为 #e5484d，syntax_* 缺省时由 Strata 从 accent/text 推导。
name = "Matugen"

# 窗口最底层背景 / 标题栏·面板·弹窗底色：沿用本仓库 GUI 一族的 surface 语义。
background = "{{colors.surface_container_lowest.default.hex}}"
surface = "{{colors.surface_container.default.hex}}"
# 主文字与次要文字。
text = "{{colors.on_surface.default.hex}}"
dim_text = "{{colors.on_surface_variant.default.hex}}"
# 重点色：选中、焦点环、链接、按钮强调，另外也是图标主色。
accent = "{{colors.primary.default.hex}}"
# 选中行/项底色（style.css 多以 alpha 叠加）。
highlight = "{{colors.secondary_container.default.hex}}"
# 惰性填充与分隔线。
muted = "{{colors.surface_container_high.default.hex}}"
border = "{{colors.outline_variant.default.hex}}"
# 危险操作与错误。
danger = "{{colors.error.default.hex}}"

# 代码预览（GtkSourceView）的 5 个 syntax_* 键故意省略：Strata 会从 accent/text
# 之间做 blend 推导（theme.rs 的 resolved_source_palette）。本仓库的 Matugen 用
# scheme-content + saturation，secondary/tertiary 常与 primary 收敛成同色，
# 显式写反而更差；需要时再按需补这 5 个键。
