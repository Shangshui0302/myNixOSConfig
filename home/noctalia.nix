{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    settings = {
      settingsVersion = 0;
      bar = {
        barType = "simple";
        position = "top";
        monitors = [ ];
        density = "comfortable";
        showOutline = true;
        showCapsule = true;
        capsuleOpacity = 0.1;
        capsuleColorKey = "primary";
        widgetSpacing = 6;
        contentPadding = 2;
        fontScale = 1.11;
        enableExclusionZoneInset = true;
        backgroundOpacity = 0.93;
        useSeparateOpacity = false;
        floating = false;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 8;
        frameRadius = 12;
        outerCorners = true;
        hideOnOverview = false;
        displayMode = "always_visible";
        autoHideDelay = 500;
        autoShowDelay = 150;
        showOnWorkspaceSwitch = true;
        widgets = {
          left = [
            {
              id = "Launcher";
              icon = "rocket";
              useDistroLogo = false;
              iconColor = "none";
              enableColorization = false;
              colorizeSystemIcon = "none";
              customIconPath = "";
            }
            {
              id = "Clock";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              tooltipFormat = "HH:mm ddd, MMM dd";
              clockColor = "none";
              useCustomFont = false;
              customFont = "";
            }
            {
              id = "SystemMonitor";
              showCpuUsage = true;
              showCpuTemp = true;
              showCpuFreq = false;
              showCpuCores = true;
              showMemoryUsage = true;
              showMemoryAsPercent = false;
              showSwapUsage = false;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showDiskAvailable = false;
              showGpuTemp = false;
              showNetworkStats = false;
              showLoadAverage = false;
              compactMode = true;
              useMonospaceFont = true;
              textColor = "none";
              iconColor = "error";
              diskPath = "/";
              usePadding = false;
            }
            {
              id = "MediaMini";
              showAlbumArt = true;
              showArtistFirst = false;
              showProgressRing = true;
              showVisualizer = true;
              panelShowAlbumArt = true;
              visualizerType = "linear";
              compactMode = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              maxWidth = 145;
              scrollingMode = "hover";
              textColor = "none";
              useFixedWidth = false;
            }
          ];
          center = [
            {
              id = "ActiveWindow";
              showIcon = true;
              maxWidth = 145;
              scrollingMode = "hover";
              textColor = "none";
              useFixedWidth = false;
              hideMode = "hidden";
              colorizeIcons = false;
            }
            {
              id = "Workspace";
              labelMode = "index";
              showApplications = false;
              showApplicationsHover = false;
              showLabelsOnlyWhenOccupied = true;
              characterCount = 2;
              enableScrollWheel = true;
              followFocusedScreen = false;
              hideUnoccupied = false;
              showBadge = true;
              iconScale = 0.8;
              pillSize = 0.6;
              fontWeight = "bold";
              emptyColor = "secondary";
              occupiedColor = "secondary";
              focusedColor = "primary";
              unfocusedIconsOpacity = 1.0;
              groupedBorderOpacity = 1.0;
              colorizeIcons = false;
            }
            {
              id = "plugin:special-workspaces";
              defaultSettings = {
                drawer = true;
                expandDirection = "down";
                borderRadius = 1;
                hideEmptyWorkspaces = true;
                mainIcon = "layout-grid";
                focusBorderColor = "primary";
                primaryPillColor = "none";
                primaryShowPill = false;
                primarySize = 0.9;
                primarySymbolColor = "none";
                secondaryPillColor = "primary";
                secondaryShowPill = true;
                secondarySize = 0.9;
                secondarySymbolColor = "none";
                workspaces = [
                  { icon = "message"; name = "communication"; }
                ];
              };
            }
            {
              id = "plugin:workspace-overview";
              defaultSettings = { };
            }
            {
              id = "plugin:github-feed";
              defaultSettings = {
                username = "";
                token = "";
                refreshInterval = 1800;
                notifyStars = true;
                notifyForks = true;
                notifyPRs = true;
                notifyRepoCreations = true;
                notifyMyRepoStars = true;
                notifyMyRepoForks = true;
                notifyGitHubNotifications = true;
                showStars = true;
                showForks = true;
                showPRs = true;
                showRepoCreations = true;
                showMyRepoStars = true;
                showMyRepoForks = true;
                showNotificationBadge = true;
                openInBrowser = true;
                enableSystemNotifications = false;
                maxEvents = 50;
                defaultTab = 0;
                colorizationEnabled = false;
                colorizationIcon = "Primary";
                colorizationBadge = "Primary";
                colorizationBadgeText = "Primary";
              };
            }
            {
              id = "plugin:assistant-panel";
              defaultSettings = {
                panelWidth = 520;
                panelPosition = "right";
                panelHeightRatio = 0.85;
                panelDetached = true;
                scale = 1.0;
                maxHistoryLength = 100;
                ai = {
                  provider = "google";
                  model = "gemini-2.5-flash";
                  temperature = 0.7;
                  systemPrompt = "You are a helpful assistant integrated into a Linux desktop shell. Be concise and helpful.";
                  openaiBaseUrl = "https://api.openai.com/v1/chat/completions";
                  openaiLocal = false;
                  maxHistoryLength = 100;
                  apiKeys = { };
                };
                translator = {
                  backend = "google";
                  sourceLanguage = "auto";
                  targetLanguage = "en";
                  realTimeTranslation = true;
                  deeplApiKey = "";
                };
              };
            }
          ];
          right = [
            {
              id = "plugin:network-indicator";
              defaultSettings = {
                arrowType = "caret";
                minWidth = 0;
                iconSizeModifier = 1;
                fontSizeModifier = 1;
                spacingInbetween = 0;
                forceMegabytes = false;
                byteThresholdActive = 1024;
                showNumbers = true;
                useCustomColors = false;
              };
            }
            {
              id = "Battery";
              displayMode = "graphic-clean";
              showNoctaliaPerformance = false;
              showPowerProfiles = false;
              hideIfIdle = false;
              hideIfNotDetected = true;
              deviceNativePath = "__default__";
            }
            {
              id = "Volume";
              displayMode = "onhover";
              iconColor = "none";
              textColor = "none";
              middleClickCommand = "pwvucontrol || pavucontrol";
            }
            {
              id = "Brightness";
              displayMode = "onhover";
              iconColor = "none";
              textColor = "none";
              applyToAllMonitors = false;
            }
            {
              id = "plugin:privacy-indicator";
              defaultSettings = {
                activeColor = "primary";
                inactiveColor = "none";
                enableToast = true;
                hideInactive = false;
                iconSpacing = 4;
                micFilterRegex = "";
                removeMargins = false;
              };
            }
            {
              id = "plugin:screen-shot-and-record";
              defaultSettings = {
                enableCross = true;
                enableWindowsSelection = true;
                screenshotEditor = "swappy";
              };
            }
            {
              id = "plugin:hyprland-visual-editor";
              defaultSettings = {
                isSystemActive = false;
                autoApply = true;
                overlayPath = "~/.cache/noctalia/HVE/overlay.conf";
                borderSize = 2;
                activeAnimFile = "";
                activeBorderFile = "";
                activeShaderFile = "";
              };
            }
            {
              id = "NotificationHistory";
              showUnreadBadge = true;
              unreadBadgeColor = "primary";
              iconColor = "none";
              hideWhenZero = false;
              hideWhenZeroUnread = false;
            }
            {
              id = "Tray";
              pinned = [ "chrome_status_icon_1" ];
              drawerEnabled = true;
              hidePassive = false;
              chevronColor = "none";
              colorizeIcons = false;
              blacklist = [ ];
            }
            {
              id = "ControlCenter";
              icon = "noctalia";
              useDistroLogo = false;
              enableColorization = false;
              colorizeDistroLogo = false;
              colorizeSystemIcon = "none";
              customIconPath = "";
            }
          ];
        };
        mouseWheelAction = "workspace";
        reverseScroll = false;
        mouseWheelWrap = true;
        middleClickAction = "settings";
        middleClickFollowMouse = false;
        middleClickCommand = "";
        rightClickAction = "controlCenter";
        rightClickFollowMouse = true;
        rightClickCommand = "";
        screenOverrides = [ ];
      };
      general = {
        avatarImage = "${config.home.homeDirectory}/Pictures/ProfiePictures/yamadaRyou_glassesHeadsphone.jpg";
        dimmerOpacity = 0.0;
        showScreenCorners = false;
        forceBlackScreenCorners = false;
        scaleRatio = 1.0;
        radiusRatio = 1.0;
        iRadiusRatio = 1.0;
        boxRadiusRatio = 1.0;
        screenRadiusRatio = 1.0;
        animationSpeed = 1;
        animationDisabled = false;
        compactLockScreen = false;
        lockScreenAnimations = true;
        lockOnSuspend = true;
        showSessionButtonsOnLockScreen = true;
        showHibernateOnLockScreen = true;
        enableLockScreenMediaControls = true;
        enableShadows = true;
        enableBlurBehind = true;
        shadowDirection = "bottom";
        shadowOffsetX = 0;
        shadowOffsetY = 3;
        language = "";
        allowPanelsOnScreenWithoutBar = true;
        showChangelogOnStartup = true;
        telemetryEnabled = false;
        enableLockScreenCountdown = true;
        lockScreenCountdownDuration = 10000;
        autoStartAuth = false;
        allowPasswordWithFprintd = false;
        clockStyle = "custom";
        clockFormat = "yyyy-MM-dd ddd HH:mm:ss yy ";
        passwordChars = true;
        lockScreenMonitors = [ ];
        lockScreenBlur = 0.6;
        lockScreenTint = 0.0;
        keybinds = {
          keyUp = [ "Up" ];
          keyDown = [ "Down" ];
          keyLeft = [ "Left" ];
          keyRight = [ "Right" ];
          keyEnter = [ "Return" "Enter" ];
          keyEscape = [ "Esc" ];
          keyRemove = [ "Del" ];
        };
        reverseScroll = false;
      };
      ui = {
        fontDefault = "JetBrainsMono NF";
        fontFixed = "DejaVu Sans Mono";
        fontDefaultScale = 0.9;
        fontFixedScale = 1.05;
        tooltipsEnabled = true;
        scrollbarAlwaysVisible = true;
        boxBorderEnabled = false;
        panelBackgroundOpacity = 1.0;
        translucentWidgets = false;
        panelsAttachedToBar = true;
        settingsPanelMode = "attached";
        settingsPanelSideBarCardStyle = true;
      };
      location = {
        name = "Chengdu, China";
        weatherEnabled = true;
        weatherShowEffects = true;
        useFahrenheit = false;
        use12hourFormat = false;
        showWeekNumberInCalendar = true;
        showCalendarEvents = true;
        showCalendarWeather = true;
        analogClockInCalendar = false;
        firstDayOfWeek = 0;
        hideWeatherTimezone = false;
        hideWeatherCityName = false;
      };
      calendar = {
        cards = [
          { enabled = true; id = "calendar-header-card"; }
          { enabled = true; id = "calendar-month-card"; }
          { enabled = true; id = "weather-card"; }
        ];
      };
      wallpaper = {
        enabled = true;
        overviewEnabled = false;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        monitorDirectories = [
          {
            name = "eDP-1";
            directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
            wallpaper = "";
          }
        ];
        enableMultiMonitorDirectories = false;
        showHiddenFiles = false;
        viewMode = "recursive";
        setWallpaperOnAllMonitors = true;
        fillMode = "crop";
        fillColor = "#000000";
        useSolidColor = false;
        solidColor = "#1a1a2e";
        automationEnabled = false;
        wallpaperChangeMode = "random";
        randomIntervalSec = 300;
        transitionDuration = 1500;
        transitionType = [ "fade" "disc" "stripes" "wipe" "pixelate" "honeycomb" ];
        skipStartupTransition = false;
        transitionEdgeSmoothness = 0.05;
        panelPosition = "follow_bar";
        hideWallpaperFilenames = true;
        overviewBlur = 0.4;
        overviewTint = 0.6;
        useWallhaven = false;
        wallhavenQuery = "";
        wallhavenSorting = "relevance";
        wallhavenOrder = "desc";
        wallhavenCategories = "111";
        wallhavenPurity = "100";
        wallhavenRatios = "";
        wallhavenApiKey = "";
        wallhavenResolutionMode = "atleast";
        wallhavenResolutionWidth = "";
        wallhavenResolutionHeight = "";
        sortOrder = "name";
        favorites = [
          {
            path = "${config.home.homeDirectory}/Pictures/Wallpapers/yamadaryou.png";
            colorScheme = "yamadaryou";
            darkMode = false;
            generationMethod = "monochrome";
            useWallpaperColors = false;
            paletteColors = [ ];
          }
        ];
      };
      appLauncher = {
        enableClipboardHistory = true;
        autoPasteClipboard = false;
        enableClipPreview = true;
        clipboardWrapText = true;
        enableClipboardSmartIcons = true;
        enableClipboardChips = true;
        clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
        clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
        position = "center";
        pinnedApps = [ "nemo" "google-chrome" "obsidian" "qq" ];
        sortByMostUsed = true;
        terminalCommand = "foot";
        customLaunchPrefixEnabled = false;
        customLaunchPrefix = "";
        viewMode = "list";
        showCategories = true;
        iconMode = "native";
        showIconBackground = true;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
        enableSessionSearch = true;
        ignoreMouseInput = false;
        screenshotAnnotationTool = "";
        overviewLayer = true;
        density = "comfortable";
      };
      controlCenter = {
        position = "close_to_bar_button";
        diskPath = "/";
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
            { id = "NoctaliaPerformance"; }
            {
              id = "plugin:screen-toolkit";
              defaultSettings = {
                colorHistory = [ ];
                paletteColors = [ ];
                installedLangs = [ "eng" ];
                selectedOcrLang = "eng";
                transAvailable = false;
              };
            }
          ];
          right = [
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
            { id = "DarkMode"; }
            {
              id = "plugin:color-scheme-creator";
              defaultSettings = {
                iconColor = "none";
              };
            }
          ];
        };
        cards = [
          { enabled = true; id = "profile-card"; }
          { enabled = true; id = "shortcuts-card"; }
          { enabled = true; id = "audio-card"; }
          { enabled = true; id = "brightness-card"; }
          { enabled = true; id = "weather-card"; }
          { enabled = true; id = "media-sysmon-card"; }
        ];
      };
      systemMonitor = {
        cpuWarningThreshold = 80;
        cpuCriticalThreshold = 90;
        tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        gpuCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        swapWarningThreshold = 80;
        swapCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        diskAvailWarningThreshold = 20;
        diskAvailCriticalThreshold = 10;
        batteryWarningThreshold = 20;
        batteryCriticalThreshold = 5;
        enableDgpuMonitoring = false;
        useCustomColors = true;
        warningColor = "#c57358";
        criticalColor = "#ff3092";
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
      };
      noctaliaPerformance = {
        disableWallpaper = false;
        disableDesktopWidgets = true;
      };
      dock = {
        enabled = true;
        position = "bottom";
        displayMode = "auto_hide";
        dockType = "attached";
        backgroundOpacity = 1.0;
        floatingRatio = 1.0;
        size = 1.0;
        onlySameOutput = true;
        monitors = [ ];
        pinnedApps = [ "qq" ];
        colorizeIcons = false;
        showLauncherIcon = true;
        launcherPosition = "start";
        launcherUseDistroLogo = true;
        launcherIcon = "";
        launcherIconColor = "primary";
        pinnedStatic = true;
        inactiveIndicators = false;
        groupApps = true;
        groupContextMenuMode = "list";
        groupClickAction = "list";
        groupIndicatorStyle = "dots";
        deadOpacity = 1.0;
        animationSpeed = 1;
        sitOnFrame = false;
        showDockIndicator = true;
        indicatorThickness = 6;
        indicatorColor = "none";
        indicatorOpacity = 1.0;
      };
      network = {
        wifiEnabled = true;
        airplaneModeEnabled = false;
        bluetoothRssiPollingEnabled = false;
        bluetoothRssiPollIntervalMs = 60000;
        networkPanelView = "wifi";
        wifiDetailsViewMode = "list";
        bluetoothDetailsViewMode = "list";
        bluetoothHideUnnamedDevices = false;
        disableDiscoverability = true;
        bluetoothAutoConnect = true;
      };
      sessionMenu = {
        enableCountdown = true;
        countdownDuration = 5000;
        position = "center";
        showHeader = true;
        showKeybinds = false;
        largeButtonsStyle = false;
        largeButtonsLayout = "grid";
        powerOptions = [
          { action = "lock"; enabled = true; keybind = "1"; }
          { action = "suspend"; enabled = true; keybind = "2"; }
          { action = "hibernate"; enabled = true; keybind = "3"; }
          { action = "reboot"; enabled = true; keybind = "4"; }
          { action = "logout"; enabled = true; keybind = "5"; }
          { action = "shutdown"; enabled = true; keybind = "6"; }
          { action = "rebootToUefi"; enabled = false; keybind = ""; }
          { action = "userspaceReboot"; enabled = false; keybind = ""; }
        ];
      };
      notifications = {
        enabled = true;
        enableMarkdown = true;
        density = "compact";
        monitors = [ ];
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 1.0;
        respectExpireTimeout = true;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
        clearDismissed = true;
        saveToHistory = { low = true; normal = true; critical = true; };
        sounds = {
          enabled = false;
          volume = 0.5;
          separateSounds = false;
          criticalSoundFile = "";
          normalSoundFile = "";
          lowSoundFile = "";
          excludedApps = "discord,firefox,chrome,chromium,edge";
        };
        enableMediaToast = true;
        enableKeyboardLayoutToast = true;
        enableBatteryToast = true;
      };
      osd = {
        enabled = true;
        location = "top";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1.0;
        enabledTypes = [ 0 1 2 3 ];
        monitors = [ ];
      };
      audio = {
        volumeStep = 5;
        volumeOverdrive = false;
        spectrumFrameRate = 30;
        visualizerType = "mirrored";
        spectrumMirrored = true;
        mprisBlacklist = [ ];
        preferredPlayer = "";
        volumeFeedback = true;
        volumeFeedbackSoundFile = "";
      };
      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = false;
        backlightDeviceMappings = [ ];
      };
      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "yamadaryou";
        darkMode = false;
        schedulingMode = "location";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        generationMethod = "monochrome";
        monitorForColors = "";
      };
      templates = {
        activeTemplates = [
          { enabled = true; id = "hyprland"; }
          { enabled = true;  id = "qt"; }
          { enabled = true;  id = "steam"; }
          { enabled = true;  id = "telegram"; }
          { enabled = true; id = "gtk"; }
        ];
        enableUserTheming = true;
      };
      nightLight = {
        enabled = false;
        forced = false;
        autoSchedule = true;
        nightTemp = "5122";
        dayTemp = "6500";
        manualSunrise = "06:30";
        manualSunset = "18:30";
      };
      hooks = {
        enabled = true;
        darkModeChange = "if [ \"$1\" = \"true\" ]; then ${pkgs.darkman}/bin/darkman set dark; else ${pkgs.darkman}/bin/darkman set light; fi";
        startup = "${pkgs.systemd}/bin/systemctl --user restart darkman";
        screenUnlock = "${pkgs.systemd}/bin/systemctl --user restart darkman";
      };
      plugins = {
        autoUpdate = true;
        notifyUpdates = true;
      };
      idle = {
        enabled = true;
        screenOffTimeout = 600;
        lockTimeout = 660;
        suspendTimeout = 1800;
        fadeDuration = 5;
        screenOffCommand = "";
        lockCommand = "";
        suspendCommand = "";
        resumeScreenOffCommand = "";
        resumeLockCommand = "";
        resumeSuspendCommand = "";
        customCommands = "[]";
      };
      desktopWidgets = {
        enabled = false;
        overviewEnabled = true;
        gridSnap = true;
        gridSnapScale = true;
        monitorWidgets = [
          {
            name = "eDP-1";
            widgets = [ ];
          }
        ];
      };
    };
  };

  # yamadaryou color scheme
  xdg.configFile."noctalia/colorschemes/yamadaryou/yamadaryou.json".text = builtins.toJSON {
    dark = {
      mPrimary = "#ffec15";
      mOnPrimary = "#000000";
      mSecondary = "#006ff1";
      mOnSecondary = "#ffffff";
      mTertiary = "#c57358";
      mOnTertiary = "#e0def4";
      mError = "#ff3092";
      mOnError = "#232136";
      mSurface = "#000000";
      mOnSurface = "#e0e2ef";
      mSurfaceVariant = "#1a1817";
      mOnSurfaceVariant = "#b3b7c2";
      mOutline = "#44415a";
      mShadow = "#232136";
      mHover = "#56526e";
      mOnHover = "#e0def4";
      terminal = {
        normal = {
          black = "#000000";
          red = "#FF3092";
          green = "#11CC40";
          yellow = "#CCBC11";
          blue = "#FFEC15";
          magenta = "#006FF1";
          cyan = "#C57358";
          white = "#E0E2EF";
        };
        bright = {
          black = "#1A1817";
          red = "#FF499F";
          green = "#2CF25E";
          yellow = "#F2E12C";
          blue = "#FFEE2E";
          magenta = "#1983FF";
          cyan = "#EB9B81";
          white = "#FFFFFF";
        };
        foreground = "#E0E2EF";
        background = "#000000";
        selectionFg = "#000000";
        selectionBg = "#FFEC15";
        cursor = "#FFEC15";
        cursorText = "#000000";
      };
    };
    light = {
      mPrimary = "#0055ff";
      mOnPrimary = "#faf4ed";
      mSecondary = "#e6c814";
      mOnSecondary = "#faf4ed";
      mTertiary = "#a36e55";
      mOnTertiary = "#faf4ed";
      mError = "#f52956";
      mOnError = "#faf4ed";
      mSurface = "#fffaf3";
      mOnSurface = "#000000";
      mSurfaceVariant = "#f2e9e1";
      mOnSurfaceVariant = "#353849";
      mOutline = "#dfdad9";
      mShadow = "#faf4ed";
      mHover = "#cecacd";
      mOnHover = "#575279";
      terminal = {
        normal = {
          black = "#FFFAF3";
          red = "#F52956";
          green = "#008C23";
          yellow = "#8C8100";
          blue = "#0055FF";
          magenta = "#E6C814";
          cyan = "#A36E55";
          white = "#000000";
        };
        bright = {
          black = "#F2E9E1";
          red = "#FF446D";
          green = "#13BF3E";
          yellow = "#BFB213";
          blue = "#1966FF";
          magenta = "#FFE130";
          cyan = "#D69F85";
          white = "#333333";
        };
        foreground = "#000000";
        background = "#FFFAF3";
        selectionFg = "#FAF4ED";
        selectionBg = "#0055FF";
        cursor = "#0055FF";
        cursorText = "#FAF4ED";
      };
    };
  };

  # yamadaryou wallpaper
  home.file."Pictures/Wallpapers/yamadaryou.png".source = ../assets/yamadaryou.png;

}
