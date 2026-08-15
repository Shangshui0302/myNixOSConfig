{ pkgs }:
pkgs.buildNpmPackage {
  pname = "deepseek-harness";
  version = "0.1.0-rc.6";

  # DeepSeek Harness (dsh) — 官方 npm 分发即预编译产物（lib/bin.js + 61 个 @deepseek-ai/* 依赖）。
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.0-rc.6.tgz";
    hash = "sha512-brpZfED7ieRa2PQ5tUxMhHrM1pb2CmKFVM/f6yMULBDMicahk+Z2OsHgTwTDnoiZm23Ftu9rQz0NN4pflaoJcg==";
  };

  # npm 发布默认排除 package-lock.json，vendor 一份供 fetchNpmDeps 锁定依赖版本
  postPatch = ''
    cp ${./deepseek-harness/package-lock.json} ./package-lock.json
  '';

  # cordis-plugin-hmr（web profile 默认 bundle 内）要求 node 以 --expose-internals 启动，
  # 否则 boot 时抛 "failed to apply loader entry ... --expose-internals is required for HMR service"。
  # 重写 nodejsInstallExecutables 生成的 wrapper，补上该标志。
  postInstall = ''
    cat > "$out/bin/dsh" <<EOF
  #! ${pkgs.bash}/bin/bash -e
  exec ${pkgs.nodejs}/bin/node --expose-internals "$out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js" "\$@"
  EOF
    chmod +x "$out/bin/dsh"
  '';

  dontNpmBuild = true;

  npmDepsHash = "sha256-JqdeASu+HOdSSP8HbgbS4FLd0IUS4WkNoO8CjIWWNv0=";

  meta = with pkgs.lib; {
    description = "DeepSeek Harness — agent framework where everything is a plugin (dsh CLI)";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = licenses.mit;
    mainProgram = "dsh";
  };
}
