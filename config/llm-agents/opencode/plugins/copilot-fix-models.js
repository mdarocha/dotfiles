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
 * DEPENDENCY: This plugin requires the `opencode-copilot-auth` plugin to
 * be loaded alongside it. That plugin provides the "Login with GitHub
 * Copilot" interactive device flow (client ID Ov23li8tweQw6odWQebz, scope
 * read:user). This plugin only augments the auth loader — it does NOT
 * provide its own auth methods.
 *
 * See: https://github.com/anomalyco/opencode/issues/7299
 *
 * NOTE: Previously this plugin provided a "Login with GitHub CLI" method
 * using `gh auth token`. This was removed because the gh CLI's OAuth token
 * (gho_*) is created by gh's own OAuth app with scopes gist/read:org/repo,
 * which only grants access to a small subset of Copilot models. The
 * opencode-copilot-auth device flow creates a token via the Copilot-specific
 * OAuth app, granting access to all models the user's plan allows.
 */

/**
 * Fetch the list of models available to the authenticated user from Copilot API.
 * Uses the Copilot API directly with the OAuth token from the built-in device
 * flow — no session token exchange required.
 *
 * Returns a Map keyed by model ID for efficient lookup.
 *
 * @param {string} oauthToken - GitHub OAuth access token (from OpenCode's device flow)
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
    return {
        auth: {
            provider: "github-copilot",

            /**
             * Auth loader — runs after the opencode-copilot-auth plugin's loader.
             *
             * opencode-copilot-auth already handles:
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
                // The OAuth token from the built-in device flow (client ID
                // Ov23li8tweQw6odWQebz) works as a Bearer token against
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
                        const live = copilotModels.get(apiID) || copilotModels.get(modelID);

                        // Remove models that aren't in the user's Copilot plan,
                        // are hidden from the model picker, or are explicitly
                        // disabled by org policy.
                        if (!live || live.model_picker_enabled === false || live.policy?.state === "disabled") {
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

            // No `methods` — we rely on the opencode-copilot-auth plugin for
            // the "Login with GitHub Copilot" device flow. That plugin must be
            // loaded alongside this one (see issue #7299). Previously this
            // plugin provided "Login with GitHub CLI" but that used gh's own
            // OAuth app which only grants access to a subset of Copilot models.
        },
    };
}
