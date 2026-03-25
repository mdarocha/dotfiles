/**
 * OpenCode plugin: copilot-fix-models
 *
 * Fixes two issues with the GitHub Copilot provider:
 *
 * 1. Context window sizes from models.dev are often incorrect/outdated
 *    compared to the live Copilot API (e.g. 128K vs 200K for Claude Opus).
 *    See: https://github.com/anthropics/opencode/issues/16861
 *         https://github.com/anthropics/opencode/issues/18832
 *
 * 2. OpenCode lists all models from models.dev regardless of whether
 *    they're enabled for the user's organization/plan.
 *    See: https://github.com/anthropics/opencode/issues/7256
 *         https://github.com/anthropics/opencode/issues/13470
 *
 * Additionally provides a "Login with GitHub CLI" auth method that uses
 * the active `gh` account (supports multi-account via `gh auth switch`)
 * instead of OpenCode's built-in OAuth device flow.
 */

/**
 * Fetch the list of models available to the authenticated user from Copilot API.
 * Uses the public Copilot API directly with the OAuth token — no session token
 * exchange required. This works with both OpenCode's own OAuth tokens and
 * GitHub CLI (`gho_`) tokens.
 *
 * Returns a Map keyed by model ID for efficient lookup.
 *
 * @param {string} oauthToken - GitHub OAuth access token (from gh auth or device flow)
 * @returns {Promise<Map<string, any> | null>}
 */
async function fetchCopilotModels(oauthToken) {
  try {
    const res = await fetch("https://api.githubcopilot.com/models", {
      headers: {
        Authorization: `Bearer ${oauthToken}`,
        Accept: "application/json",
        "User-Agent": "opencode-copilot-fix-models",
      },
    });
    if (!res.ok) return null;

    const data = await res.json();
    const models = new Map();
    for (const model of data.data || []) {
      models.set(model.id, model);
    }
    return models;
  } catch {
    return null;
  }
}

/**
 * Plugin entry point.
 *
 * @param {import("@opencode-ai/plugin").PluginInput} input
 * @returns {Promise<import("@opencode-ai/plugin").Hooks>}
 */
export default async function copilotFixModels(input) {
  const $ = input.$;

  return {
    auth: {
      provider: "github-copilot",

      /**
       * Auth loader — runs after the built-in CopilotAuthPlugin loader.
       *
       * The built-in already handles:
       *  - Zeroing model costs (Copilot is free-at-point-of-use)
       *  - Setting api.npm = "@ai-sdk/github-copilot"
       *  - Returning { fetch, apiKey, baseURL } for request signing
       *
       * We augment by:
       *  - Querying the live Copilot /models endpoint
       *  - Removing models not available for this user/org
       *  - Updating context/input/output limits from live data
       *
       * Returns {} to avoid overriding the built-in's fetch/apiKey/baseURL.
       */
      async loader(getAuth, provider) {
        const info = await getAuth();
        if (!info || info.type !== "oauth") return {};

        // Fetch the live model list directly from the Copilot API.
        // The OAuth token (whether from OpenCode's device flow or
        // the GitHub CLI) works as a Bearer token against
        // api.githubcopilot.com without needing a session token exchange.
        const copilotModels = await fetchCopilotModels(info.refresh);
        // If the API returned no models, don't touch anything —
        // better to show stale limits than remove all models.
        if (!copilotModels || copilotModels.size === 0) return {};

        if (provider?.models) {
          for (const [modelID, model] of Object.entries(provider.models)) {
            // Match against the API-level model ID first, then the
            // OpenCode model ID (they usually coincide but can differ
            // when models.dev uses a different naming convention).
            const apiID = model.api?.id || modelID;
            const live =
              copilotModels.get(apiID) || copilotModels.get(modelID);

            // Remove models that aren't in the user's Copilot plan,
            // are hidden from the model picker, or are explicitly
            // disabled by org policy.
            if (
              !live ||
              live.model_picker_enabled === false ||
              live.policy?.state === "disabled"
            ) {
              delete provider.models[modelID];
              continue;
            }

            // Patch limits from live API data.
            const limits = live.capabilities?.limits;
            if (limits) {
              if (!model.limit) model.limit = {};
              if (limits.max_context_window_tokens) {
                model.limit.context = limits.max_context_window_tokens;
              }
              if (limits.max_prompt_tokens) {
                model.limit.input = limits.max_prompt_tokens;
              }
              if (limits.max_output_tokens) {
                model.limit.output = limits.max_output_tokens;
              }
            }

            // Append the premium request multiplier to the model name so it
            // is visible in the model picker. Free/included models (multiplier
            // === 0) are left unlabelled; premium models get a "×N" suffix.
            const billing = live.billing;
            if (billing?.multiplier > 0) {
              const baseName = model.name || live.name || modelID;
              model.name = `${baseName} [×${billing.multiplier}]`;
            }
          }
        }

        return {};
      },

      methods: [
        {
          type: "oauth",
          label: "Login with GitHub CLI",
          prompts: [],

          /**
           * Authenticate using the currently selected `gh` CLI account.
           *
           * Uses `gh auth token` which respects multi-account setups:
           * the token returned is always for the active account on the
           * host (switchable via `gh auth switch --user <name>`).
           */
          async authorize() {
            let token;
            try {
              token = (await $`gh auth token`.text()).trim();
            } catch {
              throw new Error(
                "Failed to get token from GitHub CLI. " +
                  "Make sure you are logged in with: gh auth login",
              );
            }
            if (!token) {
              throw new Error(
                "GitHub CLI returned an empty token. " +
                  "Make sure you are logged in with: gh auth login",
              );
            }

            // Resolve the username for the active account so we can
            // display it and store it as accountId.
            let login = "";
            try {
              login = (
                await $`gh api user --jq .login`.text()
              ).trim();
            } catch {
              // Non-fatal — we can still authenticate without the username.
            }

            return {
              url: "https://github.com/settings/copilot",
              instructions: login
                ? `Authenticating as @${login} via GitHub CLI...`
                : "Authenticating via GitHub CLI...",
              method: "auto",
              async callback() {
                return {
                  type: "success",
                  refresh: token,
                  access: token,
                  expires: 0,
                  ...(login ? { accountId: login } : {}),
                };
              },
            };
          },
        },
      ],
    },
  };
}
