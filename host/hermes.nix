{ config, lib, pkgs, ... }:

{
  services.hermes-agent = {
    enable = true;
    
    # 启用官方混合容器模式
    container.enable = true;
    # 将指定用户的所有 hermes CLI 请求自动路由进容器
    container.hostUsers = [ "lishangshui" ];
    
    # 全局暴露 hermes 命令行
    addToSystemPackages = true;
    
    # 这里我们使用一个环境文件，后续只需在里面添加密钥即可（例如 LITELLM_BASE_URL 等）
    # 创建对应目录和空文件以确保启动不会失败
    environmentFiles = [ "/persist/secrets/hermes.env" ];
  };
  
  system.activationScripts.hermes-env = ''
    mkdir -p /persist/secrets
    if [ ! -f /persist/secrets/hermes.env ]; then
      touch /persist/secrets/hermes.env
      chmod 600 /persist/secrets/hermes.env
      chown lishangshui:users /persist/secrets/hermes.env
    fi
  '';
}
