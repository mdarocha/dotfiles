{ pkgs, lib, config, ... }:

let
  extensions = {
    "uBlock0@raymondhill.net" =
      "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    "queryamoid@kaply.com" =
      "https://github.com/mkaply/queryamoid/releases/download/v0.2/query_amo_addon_id-0.2-fx.xpi";
    "deArrow@ajay.app" =
      "https://addons.mozilla.org/firefox/downloads/latest/dearrow/latest.xpi";

    "@react-devtools" = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi";
    "extension@redux.devtools" = "https://addons.mozilla.org/firefox/downloads/latest/reduxdevtools/latest.xpi";

    "pl@dictionaries.addons.mozilla.org" =
      "https://addons.mozilla.org/firefox/downloads/latest/polish-spellchecker-dictionary/latest.xpi";
  };

  ublock-settings = {
    userSettings = {
      uiTheme = "dark";
    };
    selectedFilterLists = [
      "user-filters"
      "ublock-filters"
      "ublock-badware"
      "ublock-privacy"
      "ublock-quick-fixes"
      "ublock-unbreak"
      "easylist"
      "adguard-generic"
      "adguard-mobile"
      "easyprivacy"
      "adguard-spyware"
      "adguard-spyware-url"
      "block-lan"
      "urlhaus-1"
      "curben-phishing"
      "plowe-0"
      "fanboy-cookiemonster"
      "ublock-cookies-easylist"
      "adguard-cookies"
      "ublock-cookies-adguard"
      "fanboy-social"
      "adguard-social"
      "easylist-chat"
      "easylist-newsletters"
      "easylist-notifications"
      "easylist-annoyances"
      "adguard-mobile-app-banners"
      "adguard-other-annoyances"
      "adguard-popup-overlays"
      "adguard-widgets"
      "ublock-annoyances"
      "POL-0"
      "POL-2"
    ];
  };

  settings = {
    # theming
    "browser.compactmode.show" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # set languages for webpages
    "intl.accept_languages" = "pl-PL,pl,en-US,en";

    # suspend tabs for better performance
    "dom.suspend_inactive.enabled" = true;

    # more bloat
    "browser.tabs.firefox-view" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.newtabpage.activity-stream.default.sites" = "";
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.system.topsites" = false;
    "browser.urlbar.resultMenu" = false;
    "browser.urlbar.resultMenu.keyboardAccessible" = false;

    # privacy
    "browser.send_pings" = false;
    "dom.event.clipboardevents.enabled" = true; # breaks some sites
    "network.http.referer.trimmingPolicy" = 0;
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.http.referer.defaultPolicy" = 1;
    "network.IDN_show_punycode" = true;
    "accessibility.force_disabled" = 1;
    "network.jar.block-remote-files" = true;
  };

  policies = {
    # extensions
    ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
          blocked_install_message = "Use Nix dotfiles to manage extensions!";
          allowed_types = [ "theme" "locale" "extension" "dictionary" ];
        };
        "langpack-pl@firefox.mozilla.org" = {
            installation_mode = "allowed";
        };
    } // (lib.mapAttrs
      (_: v: {
        installation_mode = "force_installed";
        install_url = v;
      })
      extensions);

    "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = ublock-settings;
    };

    # misc
    Cookies = {
        Behavior = "reject-tracker";
        BehaviorPrivateBrowsing = "reject-tracker-and-partition-foreign";
    };
    DisplayBookmarksToolbar = "never";
    DisplayMenuBar = "never";
    Homepage = {
      URL = "about:blank";
      Locked = true;
      StartPage = "homepage";
    };
    PDFjs = {
      Enabled = true;
      EnablePermissions = false; # ignore pdf permissions crap like block copy
    };
    RequestedLocales = [ "pl" "en-US" ];
    ShowHomeButton = true;

    Preferences = settings;

    # bloat
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    DisableFeedbackCommands = true;
    DisableFirefoxAccounts = true;
    DisableFirefoxScreenshots = true;
    DisableFirefoxStudies = true;
    DisableFormHistory = true;
    DisablePocket = true;
    DisableProfileImport = true;
    DisableProfileRefresh = true;
    DisableSetDesktopBackground = true;
    DisableTelemetry = true;
    NoDefaultBookmarks = true;
    NewTabPage = false;
    OfferToSaveLogins = false;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    PasswordManagerEnabled = false;
    SearchSuggestEnabled = false;
    EnableTrackingProtection.Value = false; # we use ublock
    UseSystemPrintDialog = true;
    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnboarding = true;
      MoreFromMozilla = false;
      FirefoxLabs = false;
      Locked = true;
    };
    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
      Locked = true;
    };
  };

  policyJson = pkgs.writeTextFile {
    name = "policies.json";
    text = builtins.toJSON { inherit policies; };
  };

  policyJsonTargetPath = "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/x86_64/stable/policies/policies.json";

  cfg = config.mdarocha.firefox;
in
{
  options.mdarocha.firefox = {
    enable = lib.mkEnableOption "customized firefox";
  };

  config = lib.mkIf cfg.enable {
    home.activation.firefoxPolicy = ''
      run /usr/bin/sudo mkdir -p $(dirname ${policyJsonTargetPath})
      run /usr/bin/sudo cp ${policyJson} ${policyJsonTargetPath}
    '';
  };
}
