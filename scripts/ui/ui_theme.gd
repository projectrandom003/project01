class_name UITheme
extends RefCounted
## Central palette and Theme factory for the whole interface.
##
## The look is deliberately cohesive: deep indigo glass panels, warm gold for
## progression and summoning, teal for the living magic of Greenward. All UI is
## built from code so it scales cleanly between 16:9 desktop and landscape
## mobile without shipping a pile of hand-authored scene files.

const BG := Color("#080b16")
const BG_SOFT := Color("#0d1222")
const PANEL := Color("#121a2e")
const PANEL_LIGHT := Color("#1a2440")
const PANEL_DEEP := Color("#0a0f1d")
const BORDER := Color("#2a3554")
const BORDER_SOFT := Color("#1d2740")
const TEXT := Color("#e9eef9")
const TEXT_DIM := Color("#9aa8c2")
const TEXT_FAINT := Color("#6d7b96")
const GOLD := Color("#e8c27a")
const GOLD_BRIGHT := Color("#ffe6a8")
const TEAL := Color("#7fe3e0")
const TEAL_DIM := Color("#3f8f96")
const GREEN := Color("#8fe3a0")
const DANGER := Color("#ff7a8a")
const VIOLET := Color("#b78bff")

const RARITY := {
	"common": Color("#9aa8c2"),
	"rare": Color("#6fa8ff"),
	"epic": Color("#c07bff"),
	"legendary": Color("#ffc95e"),
	"mythic": Color("#ff6fae"),
}

const ELEMENT := {
	"neutral": Color("#9aa8c2"),
	"fire": Color("#ff8a5c"),
	"wind": Color("#8fe3a0"),
	"earth": Color("#c9a86a"),
	"water": Color("#6fc8ff"),
	"light": Color("#ffe6a8"),
	"dark": Color("#b78bff"),
}


static func rarity_color(rarity: String) -> Color:
	return RARITY.get(rarity, TEXT_DIM)


static func element_color(element: String) -> Color:
	return ELEMENT.get(element, TEXT_DIM)


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "RichTextLabel", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_stylebox("panel", "PanelContainer", style(PANEL, BORDER, 12, 1, 12))
	theme.set_stylebox("panel", "Panel", style(PANEL, BORDER, 12, 1, 12))
	theme.set_stylebox("normal", "Button", style(PANEL_LIGHT, BORDER, 8, 1, 10))
	theme.set_stylebox("hover", "Button", style(Color("#243252"), GOLD, 8, 1, 10))
	theme.set_stylebox("pressed", "Button", style(Color("#0e1628"), GOLD, 8, 1, 10))
	theme.set_stylebox("disabled", "Button", style(Color("#111827"), Color("#1d2740"), 8, 1, 10))
	theme.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), GOLD, 8, 2, 10))
	theme.set_stylebox("normal", "OptionButton", style(PANEL_LIGHT, BORDER, 8, 1, 8))
	theme.set_stylebox("hover", "OptionButton", style(Color("#243252"), GOLD, 8, 1, 8))
	theme.set_stylebox("pressed", "OptionButton", style(Color("#0e1628"), GOLD, 8, 1, 8))
	theme.set_stylebox("focus", "OptionButton", style(Color(0, 0, 0, 0), GOLD, 8, 2, 8))
	theme.set_stylebox("panel", "PopupMenu", style(PANEL_DEEP, BORDER, 8, 1, 6))
	theme.set_stylebox("hover", "PopupMenu", style(Color("#243252"), GOLD, 4, 1, 4))
	theme.set_stylebox("separator", "HSeparator", line_style(BORDER_SOFT))
	theme.set_stylebox("separator", "VSeparator", line_style(BORDER_SOFT))
	theme.set_stylebox("background", "ProgressBar", style(Color("#0a1020"), BORDER_SOFT, 4, 1, 0))
	theme.set_stylebox("fill", "ProgressBar", style(TEAL_DIM, TEAL_DIM, 4, 0, 0))
	return theme


static func style(
	bg: Color,
	border: Color = BORDER,
	radius: int = 10,
	border_width: int = 1,
	padding: int = 12,
	shadow: bool = false
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	box.anti_aliasing = true
	if shadow:
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 4)
	return box


static func line_style(color: Color) -> StyleBoxLine:
	var box := StyleBoxLine.new()
	box.color = color
	box.thickness = 1
	return box


# -------------------------------------------------- Phase 5 rarity presentation
# Additive-only data: the original RARITY / ELEMENT / build() / style() /
# line_style() above are untouched. These describe *presentation* only; they do
# NOT imply any final character artwork exists. ZERO final portraits exist today
# and the procedural PortraitView fallback is the active rendering path.

# The "glow" for each tier IS the existing RARITY colour (same hex), so the
# presentation stays keyed to the canonical palette. Legendary / Mythic are
# distinguished by a stronger aura, wider border, unique sparkle / frame and
# the "premium" tier flag — not by an invented colour.
const RARITY_EFFECTS := {
	"common": {
		"glow": Color("#9aa8c2"),
		"border_width": 1,
		"aura": 0.0,
		"sparkle": "none",
		"frame": "plain brushed edge",
		"tier": "standard",
	},
	"rare": {
		"glow": Color("#6fa8ff"),
		"border_width": 1,
		"aura": 0.12,
		"sparkle": "faint cool glint",
		"frame": "soft bevelled edge",
		"tier": "standard",
	},
	"epic": {
		"glow": Color("#c07bff"),
		"border_width": 2,
		"aura": 0.30,
		"sparkle": "violet arcane motes",
		"frame": "arcanely etched edge",
		"tier": "standard",
	},
	"legendary": {
		"glow": Color("#ffc95e"),
		"border_width": 3,
		"aura": 0.72,
		"sparkle": "radiant gold sunburst shimmer",
		"frame": "engraved sunburst gold frame",
		"tier": "premium",
	},
	"mythic": {
		"glow": Color("#ff6fae"),
		"border_width": 4,
		"aura": 0.95,
		"sparkle": "rose-ember cinders and eclipse flare",
		"frame": "obsidian-and-gold crown frame",
		"tier": "premium",
	},
}


## Presentation effect for a rarity; unknown rarities fall back to a common-like
## default (defensive, never throws). Values are read-only data for callers.
static func rarity_effect(rarity: String) -> Dictionary:
	var effect: Dictionary = RARITY_EFFECTS.get(rarity, RARITY_EFFECTS["common"])
	return effect


## True only for the two premium tiers (legendary / mythic).
static func is_premium_rarity(rarity: String) -> bool:
	return str(rarity_effect(rarity).get("tier", "standard")) == "premium"


static func rarity_glow(rarity: String) -> Color:
	var glow: Color = rarity_effect(rarity).get("glow", RARITY.get(rarity, TEXT_DIM))
	return glow


## Short premium flourish label ("LEGENDARY" / "MYTHIC"); empty for standard
## tiers so callers can add nothing for common/rare/epic.
static func rarity_tier_label(rarity: String) -> String:
	return rarity.to_upper() if is_premium_rarity(rarity) else ""
