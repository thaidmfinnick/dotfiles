/**
 * Context Bar - publishes a progress-bar view of context usage as an
 * extension status, so pi-powerline-footer can show it via `customItems`.
 *
 * Wire it up in ~/.pi/agent/settings.json:
 *
 *   "powerline": {
 *     "customItems": [
 *       { "id": "ctxbar", "statusKey": "context-bar", "position": "right", "selfColorize": true }
 *     ]
 *   }
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "context-bar";

// Mirrors pi-footer's `contextBarMode` presets.
const MODES = {
	default: { width: 32, filled: "█", empty: "░", bracketed: true, showUsage: true },
	medium: { width: 16, filled: "█", empty: "░", bracketed: true, showUsage: true },
	short: { width: 10, filled: "▓", empty: "░", bracketed: false, showUsage: true },
	"short-only": { width: 10, filled: "▓", empty: "░", bracketed: false, showUsage: false },
} as const;

type ModeName = keyof typeof MODES;

// ---- options (edit to taste) ----------------------------------------------
const contextBarMode: ModeName = "medium";
const contextConditionalColors = true;
const hideWhenZero = true;
// ---------------------------------------------------------------------------

function formatTokens(n: number): string {
	if (n < 1000) return `${n}`;
	if (n < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}

function readUsage(ctx: ExtensionContext): { tokens: number; window: number; percent: number } | null {
	const getContextUsage = (ctx as unknown as { getContextUsage?: () => unknown }).getContextUsage;
	if (typeof getContextUsage !== "function") return null;

	const usage = getContextUsage.call(ctx) as
		| { tokens?: number | null; contextWindow?: number; percent?: number }
		| null
		| undefined;
	if (!usage) return null;

	const window = usage.contextWindow;
	if (typeof window !== "number" || !Number.isFinite(window) || window <= 0) return null;

	const tokens = usage.tokens;
	if (typeof tokens !== "number" || !Number.isFinite(tokens)) return null;

	const percent =
		typeof usage.percent === "number" && Number.isFinite(usage.percent)
			? usage.percent
			: (tokens / window) * 100;

	return { tokens, window, percent };
}

function render(ctx: ExtensionContext): string | undefined {
	const usage = readUsage(ctx);
	if (!usage) return undefined;
	if (hideWhenZero && usage.tokens <= 0) return undefined;

	const mode = MODES[contextBarMode];
	const ratio = Math.min(1, Math.max(0, usage.percent / 100));
	const filledCount = Math.round(ratio * mode.width);

	let bar = mode.filled.repeat(filledCount) + mode.empty.repeat(mode.width - filledCount);
	if (mode.bracketed) bar = `[${bar}]`;

	let text = bar;
	if (mode.showUsage) {
		text = `${bar} ${formatTokens(usage.tokens)}/${formatTokens(usage.window)} (${usage.percent.toFixed(1)}%)`;
	}

	if (!contextConditionalColors) return text;

	const tone = usage.percent > 90 ? "error" : usage.percent > 70 ? "warning" : "dim";
	return ctx.ui.theme.fg(tone, text);
}

export default function (pi: ExtensionAPI) {
	const update = (_event: unknown, ctx: ExtensionContext) => {
		ctx.ui.setStatus(STATUS_KEY, render(ctx));
	};

	pi.on("session_start", update);
	pi.on("turn_start", update);
	pi.on("turn_end", update);
	pi.on("message_end", update);
}
