class_name DGCCoinBalance
extends HBoxContainer

## CoinBalance - gold coin counter shown in info bars and shop headers.
## Displays: glyph [amount] coins

signal amount_changed(new_amount: int)

@export var amount: int = 0:
	set(value):
		amount = value
		if _amount_label:
			_amount_label.text = _format_amount(value)
		amount_changed.emit(value)

@export var compact: bool = false:
	set(value):
		compact = value
		_apply_sizing()

var _glyph_label: Label
var _amount_label: Label
var _coins_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER

	# Glyph
	_glyph_label = Label.new()
	_glyph_label.text = "\U0001fa99"  # coin emoji
	_apply_font(_glyph_label, true)
	add_child(_glyph_label)

	# Amount
	_amount_label = Label.new()
	_amount_label.text = _format_amount(amount)
	_apply_font(_amount_label, true)
	add_child(_amount_label)

	# "coins" word
	_coins_label = Label.new()
	_coins_label.text = "coins"
	_apply_font(_coins_label, false)
	add_child(_coins_label)

	_apply_sizing()

func _apply_font(label: Label, bold: bool) -> void:
	var font = DesignTokens.font_display_bold if DesignTokens.font_display_bold else null
	if not bold:
		font = DesignTokens.font_body_semibold if DesignTokens.font_body_semibold else null
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", DesignTokens.GOLD)

func _apply_sizing() -> void:
	var fs = DesignTokens.FS_H3 if compact else DesignTokens.FS_H2
	for label in [_glyph_label, _amount_label, _coins_label]:
		if label:
			label.add_theme_font_size_override("font_size", fs)

func _format_amount(val: int) -> String:
	# Add thousands separators
	var s = str(abs(val))
	var result = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	if val < 0:
		result = "-" + result
	return result
