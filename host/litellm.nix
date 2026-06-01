{ ... }:
{
  services.litellm = {
    enable = true;

    host = "0.0.0.0";
    port = 4000;

    environmentFile = "/persist/secrets/litellm.env";

    settings = {
      model_list = [
        {
          model_name = "claude-opus-4-7";
          litellm_params = {
            model = "anthropic/deepseek-v4-pro";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 32000;
            temperature = 0.7;
            timeout = 600;
          };
        }
        {
          model_name = "claude-sonnet-4-6";
          litellm_params = {
            model = "anthropic/deepseek-v4-flash";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 24000;
            temperature = 0.7;
            timeout = 600;
          };
        }
        {
          model_name = "claude-sonnet-4-6-1m";
          litellm_params = {
            model = "anthropic/deepseek-v4-flash";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 64000;
            temperature = 0.7;
            timeout = 1200;
          };
        }
        {
          model_name = "claude-haiku-4-5";
          litellm_params = {
            model = "anthropic/deepseek-v4-flash";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 12000;
            temperature = 0.5;
            timeout = 300;
          };
        }
        {
          model_name = "claude-haiku-4-5-20251001";
          litellm_params = {
            model = "anthropic/deepseek-v4-flash";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 12000;
            temperature = 0.5;
            timeout = 300;
          };
        }
        {
          model_name = "claude-opus-4-6";
          litellm_params = {
            model = "anthropic/deepseek-v4-pro";
            api_base = "https://api.deepseek.com/anthropic";
            api_key = "os.environ/DEEPSEEK_API_KEY";
            max_tokens = 32000;
            temperature = 0.7;
            timeout = 600;
          };
        }
      ];

      router_settings = {
        routing_strategy = "simple-shuffle";
        fallbacks = [
          { "claude-opus-4-7" = [ "claude-sonnet-4-6" ]; }
          { "claude-opus-4-6" = [ "claude-sonnet-4-6" ]; }
          { "claude-sonnet-4-6" = [ "claude-haiku-4-5" ]; }
          { "claude-sonnet-4-6-1m" = [ "claude-sonnet-4-6" ]; }
        ];
      };

      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
      };

      litellm_settings = {
        set_verbose = true;
        request_timeout = 1200;
        drop_params = true;
        num_retries = 3;
        retry_after = 5;
        stream_timeout = 1200;
        modify_params = true;
        add_function_to_prompt = true;
      };
    };

    openFirewall = false;
  };
}
