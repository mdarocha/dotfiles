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
 * This plugin only defines a loader (no auth methods). The built-in
 * CopilotAuthPlugin handles login/device-flow. A companion patch
 * (opencode-merge-plugin-auth-hooks.patch) fixes the upstream
 * Record.fromEntries last-wins bug so this plugin's loader augments
 * — rather than shadows — the built-in auth hook.
 */

/**
 * Fetch the list of models available to the authenticated user from Copilot API.
 *
 * Uses the OAuth token (info.refresh / info.access — same value for built-in
 * CopilotAuthPlugin) directly as a Bearer token against api.githubcopilot.com.
 *
 * Returns a Map keyed by model ID for efficient lookup.
 *
 * @param {string} oauthToken - GitHub OAuth access token
 * @returns {Promise<Map<string, any> | null>}
 */
async function fetchCopilotModels(oauthToken) {
    try {
        const res = await fetch("https://api.githubcopilot.com/models", {
            headers: {
                Authorization: `Bearer ${oauthToken}`,
                Accept: "application/json",
                "User-Agent": "opencode-copilot-fix-models",
                // Required to get the billing field (including multiplier) in the response.
                // Without this header the API returns a legacy schema that omits billing entirely.
                "X-GitHub-Api-Version": "2025-10-01",
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
             * Auth loader — runs after the built-in CopilotAuthPlugin's loader.
             *
             * The built-in CopilotAuthPlugin already handles:
             *  - Zeroing model costs (Copilot is free-at-point-of-use)
             *  - Setting api.npm = "@ai-sdk/github-copilot"
             *  - Returning { fetch, apiKey, baseURL } for request signing
             *
             * We augment by:
             *  - Querying the live Copilot /models endpoint
             *  - Removing models not available for this user/org
             *  - Updating context/input/output limits from live data
             *  - Appending premium request multiplier to model names
             *
             * Returns {} to avoid overriding the built-in's fetch/apiKey/baseURL.
             */
            async loader(getAuth, provider) {
                const info = await getAuth();
                if (!info || info.type !== "oauth") return {};

                const copilotModels = await fetchCopilotModels(info.refresh);
                if (!copilotModels || copilotModels.size === 0) return {};

                if (provider?.models) {
                    for (const [modelID, model] of Object.entries(provider.models)) {
                        const apiID = model.api?.id || modelID;
                        const live = copilotModels.get(apiID) || copilotModels.get(modelID);

                        // Remove models not in the user's Copilot plan
                        if (!live || live.model_picker_enabled === false || live.policy?.state === "disabled") {
                            delete provider.models[modelID];
                            continue;
                        }

                        // Patch limits from live API data
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

                        // Append premium request multiplier to model name
                        const billing = live.billing;
                        if (billing?.multiplier > 0) {
                            const baseName = model.name || live.name || modelID;
                            model.name = `${baseName} [×${billing.multiplier}]`;
                        }
                    }
                }

                return {};
            },
        },
    };
}
