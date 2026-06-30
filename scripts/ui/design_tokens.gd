class_name DesignTokens
extends Node

# === COLORS ===
# Surface system (pastel blue)
const BLUE_SKY = Color("#d4e9f7")
const BLUE_PANEL = Color("#f0f7ff")
const BLUE_GROUND = Color("#e1ebf2")
const BLUE_LINE = Color("#c8d6e4")
const BLUE_TAB_IDLE = Color("#e8eef3")

# Action system (yellow → gold)
const YELLOW = Color("#ffe066")
const YELLOW_BRIGHT = Color("#ffeb8c")
const GOLD = Color("#ffd700")
const GOLD_DEEP = Color("#e6bf00")
const GOLD_PRESS = Color("#e6c700")
const GOLD_PRESS_LINE = Color("#ccb300")

# Accents
const MINT = Color("#b5ead7")
const CORAL = Color("#ff8c7c")
const RED = Color("#ff6666")

# Ink (text)
const INK = Color("#2c3e50")
const INK_TITLE = Color("#3d3d5c")
const INK_SLATE = Color("#344960")
const INK_MUTED = Color("#808c99")

# Overlays
const DIM = Color(0.173, 0.243, 0.314, 0.5)
const LOCK_VEIL = Color(0.827, 0.914, 0.969, 0.85)

# Guard scale (functional)
const GUARD_0 = Color("#e61a1a")
const GUARD_025 = Color("#e68019")
const GUARD_05 = Color("#e6e619")
const GUARD_1 = Color("#1acc1a")
const GUARD_2 = Color("#1a80e6")
const GUARD_4 = Color("#8019e6")
const GUARD_6 = Color("#e61ae6")

# === TYPOGRAPHY ===
const FS_HERO = 52
const FS_H1 = 36
const FS_H2 = 32
const FS_H3 = 28
const FS_BODY = 26
const FS_LABEL = 24
const FS_SMALL = 20

const LH_TIGHT = 1.05
const LH_SNUG = 1.2
const LH_NORMAL = 1.4

const LS_CAPS = 0.04  # em

# Font weights
const FW_REGULAR = 400
const FW_SEMIBOLD = 600
const FW_BOLD = 700
const FW_EXTRABOLD = 800

# === SPACING ===
const SPACE = [0, 4, 8, 12, 16, 20, 24, 30, 40]
const PAD_SCREEN_SM = 20
const PAD_SCREEN_MD = 30
const PAD_SCREEN_LG = 40
const PAD_BUTTON_X = 32
const PAD_BUTTON_Y = 24
const PAD_PANEL = 24
const PAD_TAB_X = 16
const PAD_TAB_Y = 8

# Touch targets
const HIT_SM = 48
const HIT_MD = 64
const HIT_LG = 88
const HIT_XL = 96

# === EFFECTS ===
# Corner radii
const RADIUS_SLIDER = 6
const RADIUS_PROGRESS = 8
const RADIUS_TAB = 8
const RADIUS_PANEL = 16
const RADIUS_BUTTON = 24
const RADIUS_PILL = 999

# Border widths
const BORDER_THIN = 1
const BORDER_THICK = 2
const BORDER_TAB = 3

# === MOTION ===
const DUR_PRESS = 0.08
const DUR_RELEASE = 0.2
const DUR_ENTRANCE = 0.5
const DUR_ENTRANCE_SM = 0.3
const DUR_SCORE = 1.5
const DUR_STAGGER = 0.1
const DUR_PULSE = 0.4

const PRESS_SCALE = 0.95
const TOOL_POP_SCALE = 1.15
const COIN_BUMP = 1.2
const PULSE_SCALE = 1.05

# Easing curves (Godot Tween equivalents)
# EASE_BACK = cubic-bezier(0.34, 1.56, 0.64, 1) -> Tween.TRANS_BACK, EASE_OUT
# EASE_OUT = cubic-bezier(0.22, 0.61, 0.36, 1) -> Tween.TRANS_QUAD, EASE_OUT
# EASE_SINE = cubic-bezier(0.37, 0, 0.63, 1) -> Tween.TRANS_SINE, EASE_IN_OUT

# === FONT RESOURCES ===
# These will be loaded when fonts are available
static var font_display: Font = null  # Baloo 2
static var font_body: Font = null     # Nunito
static var font_emoji: Font = null    # Noto Color Emoji (fallback for emoji glyphs)

static var font_display_bold: Font = null      # Baloo 2 Bold (700)
static var font_display_extrabold: Font = null  # Baloo 2 ExtraBold (800)
static var font_body_regular: Font = null       # Nunito Regular (400)
static var font_body_semibold: Font = null      # Nunito SemiBold (600)
static var font_body_bold: Font = null           # Nunito Bold (700)
static var font_body_extrabold: Font = null      # Nunito ExtraBold (800)

static var _fonts_initialized := false

func _ready():
	_init_fonts()

static func _init_fonts():
	if _fonts_initialized:
		return
	_fonts_initialized = true

	# Load font resources
	var base_path = "res://resources/fonts/"

	# Load emoji font first (used as fallback on all text fonts)
	font_emoji = load(base_path + "NotoColorEmoji-Regular.ttf")

	font_display_bold = load(base_path + "Baloo2-Bold.ttf")
	font_display_extrabold = load(base_path + "Baloo2-ExtraBold.ttf")
	font_body_regular = load(base_path + "Nunito-Regular.ttf")
	font_body_semibold = load(base_path + "Nunito-SemiBold.ttf")
	font_body_bold = load(base_path + "Nunito-Bold.ttf")
	font_body_extrabold = load(base_path + "Nunito-ExtraBold.ttf")

	# Add emoji font as fallback to all text fonts so emoji glyphs render
	if font_emoji:
		var all_fonts: Array[Font] = [
			font_display_bold,
			font_display_extrabold,
			font_body_regular,
			font_body_semibold,
			font_body_bold,
			font_body_extrabold,
		]
		for font in all_fonts:
			if font:
				font.fallbacks = [font_emoji]

	# Default aliases
	font_display = font_display_bold
	font_body = font_body_regular
