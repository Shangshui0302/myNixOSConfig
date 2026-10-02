{ pkgs }:

# Strata —— 键盘优先的 GTK4 文件管理器（Rust，MIT）。上游只发布预编译 tarball
# （AUR 走 `strata-bin`），这里从 v0.20.1 tag 源码构建，依赖全部来自 nixpkgs；
# Cargo.lock 的 373 个 crate 全部来自 crates.io，因此 fetchCargoVendor 一次锁定即可。
#
# NixOS 适配：预览与缩略图在 bubblewrap 内渲染，而上游 src/sandbox.rs 的
# runtime_command() 写死 FHS 布局（`--ro-bind /usr /usr`、`--setenv PATH /usr/bin`、
# `/usr/bin/prlimit`，且不 bind /nix/store）。配套补丁 strata-nixos-sandbox.patch 把
# 沙箱内 PATH/prlimit 换成构建期注入的 store 路径、追加只读 /nix/store，
# 并把 GStreamer 插件目录带进沙箱；详见 wiki/dev/nix-packaging.md。
let
  inherit (pkgs) lib;

  # 上游 install.sh 的 REQUIRED_PACKAGES：运行时（而非链接期）依赖，由包装脚本放进 PATH。
  # 注意 trusted_command::resolve 只搜索固定系统目录（/run/current-system/sw/bin 等）、
  # 不读 PATH，所以 bwrap 仍须由系统 profile 提供。
  #
  # 与上游清单的两处偏差，都是为了缩减闭包（应用自身闭包 1168 MiB）：
  #   - ffmpeg → ffmpeg-headless：应用只用命令行 ffmpeg/ffprobe（在 sandbox_helper 里），
  #     完整 ffmpeg 闭包 980 MiB，headless 302 MiB 且已由 ffmpegthumbnailer 带入；
  #   - 不带 gst-plugins-bad：它不在上游 REQUIRED_PACKAGES 里，闭包 810 MiB（flite/freepats 等）。
  runtimeTools = with pkgs; [
    bubblewrap
    coreutils
    desktop-file-utils
    ffmpeg-headless
    ffmpegthumbnailer
    squashfs-tools
    util-linux
    xdg-utils
  ];

  # 媒体预览用的 GStreamer 插件：core 的 setup hook 会把 lib/gstreamer-1.0 追加进
  # GST_PLUGIN_SYSTEM_PATH_1_0，wrap-gapps-hook 再把该变量写进包装脚本。
  gstPlugins = with pkgs.gst_all_1; [
    gst-libav
    gst-plugins-base
    gst-plugins-good
    gstreamer
  ];
in
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "strata";
  version = "0.20.1";

  src = pkgs.fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    tag = "v${finalAttrs.version}";
    hash = "sha256-uAMpUXgcoqejW6acuMbzCEbO8NNFsqlbQf6XP7hMwWY=";
  };

  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-XA6rV+BRj1XG3LlGBBVMUXjnhR1E5FUoL4oT78XazmA=";
  };

  # NixOS 适配补丁：只改 src/sandbox.rs 里构造 bubblewrap 参数的地方，
  # 不动沙箱的命名空间/clearenv/Landlock/seccomp 边界。
  patches = [ ./strata-nixos-sandbox.patch ];

  # build.rs 通过 glib-build-tools 把 data/strata.gresource.xml 编译成 GResource。
  nativeBuildInputs = with pkgs; [
    glib
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    pkgs.cairo
    pkgs.fontconfig
    pkgs.gdk-pixbuf
    pkgs.gtk4
    pkgs.gtksourceview5
    pkgs.poppler
  ]
  ++ gstPlugins;

  # build.rs 注入的发布身份；不显式给出时会依赖构建环境里有没有 git（沙箱里没有，
  # 会退化成 unknown/stable），这里写死以保证可复现。
  # STRATA_SANDBOX_* 是补丁的编译期输入（option_env!），决定沙箱内 PATH、prlimit
  # 和 GStreamer 插件目录；缺了它们补丁会退回上游的 /usr/bin 假设。
  env = {
    STRATA_RELEASE_TAG = "v${finalAttrs.version}";
    STRATA_BUILD_KIND = "stable";
    STRATA_SANDBOX_PATH = lib.makeBinPath runtimeTools;
    STRATA_SANDBOX_PRLIMIT = "${lib.getBin pkgs.util-linux}/bin/prlimit";
    # 注意用 out 输出：gst_all_1.gstreamer 的默认输出是 bin，里面没有 lib/gstreamer-1.0。
    STRATA_SANDBOX_GST_PLUGIN_PATH = lib.makeSearchPath "lib/gstreamer-1.0" (
      map (lib.getOutput "out") gstPlugins
    );
  };

  # 上游 scripts/check.sh 用 `cargo test --all-targets --all-features`，其 GUI/e2e 用例
  # 需要显示服务器（上游另用 Xvfb 跑 test-headless.py）；Nix 构建沙箱里没有，
  # 强行开启只会失败而非提供证据。
  doCheck = false;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath runtimeTools}
    )
  '';

  postInstall = ''
        install -Dm644 data/io.github.lgse.Strata.desktop \
          "$out/share/applications/io.github.lgse.Strata.desktop"
        install -Dm644 data/icons/scalable/apps/io.github.lgse.Strata.svg \
          "$out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg"

        # 声明包管理器归属：Settings → Updates 会显示 "Installed by Nix as strata."，
        # 并拒绝用自更新覆盖 store 里的二进制（不设 channel，避免锁死发布通道）。
        install -d "$out/share/strata"
        cat > "$out/share/strata/install-source.toml" <<'EOF'
    manager = "Nix"
    package = "strata"
    EOF

        install -Dm644 LICENSE "$out/share/licenses/strata/LICENSE"
        install -Dm644 THIRD_PARTY_LICENSES.md "$out/share/licenses/strata/THIRD_PARTY_LICENSES.md"
  '';

  meta = {
    description = "A fast, keyboard-first file manager for Linux";
    homepage = "https://stratafiles.io/";
    changelog = "https://github.com/lgse/strata/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "strata";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
