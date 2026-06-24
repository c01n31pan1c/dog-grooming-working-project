## UIAnimations — Shared animation utility for UI juice and feedback.
## Provides reusable Tween-based animations for buttons, labels, panels, etc.
## Autoloaded singleton so any script can call UIAnimations.xxx().
extends Node

# --- Palette constants ---
const COLOR_MINT := Color(0.71, 0.918, 0.843)
const COLOR_CORAL := Color(1.0, 0.549, 0.486)
const COLOR_YELLOW := Color(1.0, 0.878, 0.4)
const COLOR_YELLOW_BRIGHT := Color(1.0, 0.92, 0.55)
const COLOR_GOLD := Color(1.0, 0.843, 0.0)
const COLOR_NAVY := Color(0.173, 0.243, 0.314)

# --- Duration constants ---
const DUR_BUTTON_PRESS := 0.08
const DUR_BUTTON_RELEASE := 0.2
const DUR_ENTRANCE := 0.5
const DUR_ENTRANCE_SHORT := 0.3
const DUR_SCORE_REVEAL := 1.5
const DUR_STAGGER := 0.1


## Button press animation: scale down to 0.95 + brief color flash.
## Call on button_down signal.
static func button_press(button: Control) -> Tween:
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), DUR_BUTTON_PRESS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", COLOR_YELLOW_BRIGHT, DUR_BUTTON_PRESS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Button release animation: bounce back to 1.0 with overshoot.
## Call on button_up or pressed signal.
static func button_release(button: Control) -> Tween:
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, DUR_BUTTON_RELEASE) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "modulate", Color.WHITE, DUR_BUTTON_RELEASE) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Wire up press/release animations on a Button. Sets pivot to center.
static func setup_button_juice(button: Button) -> void:
	_ensure_center_pivot(button)
	button.button_down.connect(func(): button_press(button))
	button.button_up.connect(func(): button_release(button))


## Slide down from above with bounce (for titles).
static func slide_down_bounce(node: Control, distance: float = 80.0, duration: float = DUR_ENTRANCE) -> Tween:
	var target_y := node.position.y
	node.position.y = target_y - distance
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", target_y, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Fade in + slide up (for buttons, cards, etc).
static func fade_slide_up(node: Control, distance: float = 40.0, duration: float = DUR_ENTRANCE_SHORT, delay: float = 0.0) -> Tween:
	var target_y := node.position.y
	node.position.y = target_y + distance
	node.modulate.a = 0.0
	var tween := node.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", target_y, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Fade in from top (for info bars, headers).
static func fade_from_top(node: Control, distance: float = 30.0, duration: float = DUR_ENTRANCE_SHORT) -> Tween:
	var target_y := node.position.y
	node.position.y = target_y - distance
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", target_y, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Slide in from right side.
static func slide_in_from_right(node: Control, distance: float = 300.0, duration: float = DUR_ENTRANCE, delay: float = 0.0) -> Tween:
	var target_x := node.position.x
	node.position.x = target_x + distance
	node.modulate.a = 0.0
	var tween := node.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(node, "position:x", target_x, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Slide in from left side.
static func slide_in_from_left(node: Control, distance: float = 300.0, duration: float = DUR_ENTRANCE, delay: float = 0.0) -> Tween:
	var target_x := node.position.x
	node.position.x = target_x - distance
	node.modulate.a = 0.0
	var tween := node.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(node, "position:x", target_x, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Scale bounce from 0 to 1 (for placement reveals, celebrations).
static func pop_scale(node: Control, duration: float = 0.4, delay: float = 0.0) -> Tween:
	_ensure_center_pivot(node)
	node.scale = Vector2.ZERO
	var tween := node.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "scale", Vector2.ONE, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return tween


## Tool selection bounce (1.0 -> 1.15 -> 1.0).
static func tool_select_bounce(button: Control) -> Tween:
	_ensure_center_pivot(button)
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Tool deselect shrink (1.0 -> 0.95 -> 1.0).
static func tool_deselect(button: Control) -> Tween:
	_ensure_center_pivot(button)
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Number ticker: smoothly counts a label from start_val to end_val.
## label_format should be a format string like "%.1f" or "%d".
static func number_ticker(label: Label, start_val: float, end_val: float, duration: float = DUR_SCORE_REVEAL, label_format: String = "%.1f", delay: float = 0.0) -> Tween:
	var tween := label.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(func(val: float):
		label.text = label_format % val
	, start_val, end_val, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Smooth progress bar fill.
static func smooth_progress(bar: ProgressBar, target_value: float, duration: float = 0.5) -> Tween:
	var tween := bar.create_tween()
	tween.tween_property(bar, "value", target_value, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Timer warning pulse: oscillates scale between 1.0 and 1.05.
static func start_pulse(node: Control) -> Tween:
	_ensure_center_pivot(node)
	var tween := node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", Vector2(1.05, 1.05), 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2.ONE, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tween


## Coin change animation: brief scale bump + number count.
static func coin_change(label: Label, old_val: int, new_val: int) -> Tween:
	_ensure_center_pivot(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	# Scale bump
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Number count
	tween.tween_method(func(val: float):
		label.text = str(int(val))
	, float(old_val), float(new_val), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Scale back
	tween.chain().tween_property(label, "scale", Vector2.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Zone flash: briefly flash a color on a Control, then return to original.
static func zone_flash(node: Control, flash_color: Color, duration: float = 0.3) -> Tween:
	var original := node.modulate
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", flash_color, duration * 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate", original, duration * 0.7) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Spawn a floating indicator (checkmark, star, X) that floats up and fades out.
## Returns the created Label so caller can add it to the scene tree.
static func spawn_float_indicator(parent: Control, text: String, start_pos: Vector2, color: Color, duration: float = 0.8) -> Label:
	var indicator := Label.new()
	indicator.text = text
	indicator.add_theme_font_size_override("font_size", 32)
	indicator.add_theme_color_override("font_color", color)
	indicator.position = start_pos
	indicator.z_index = 100
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(indicator)

	var tween := indicator.create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "position:y", start_pos.y - 60.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(indicator, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(indicator, "scale", Vector2(1.3, 1.3), duration * 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(indicator.queue_free)
	return indicator


## Spawn a "touch effect" circle that scales up and fades out.
## Creates a ColorRect as a cheap circle approximation.
static func spawn_touch_effect(parent: Control, pos: Vector2, color: Color = COLOR_MINT, size: float = 40.0) -> void:
	var effect := ColorRect.new()
	effect.color = color
	effect.color.a = 0.6
	effect.size = Vector2(size, size)
	effect.position = pos - Vector2(size * 0.5, size * 0.5)
	effect.pivot_offset = Vector2(size * 0.5, size * 0.5)
	effect.z_index = 50
	parent.add_child(effect)

	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(2.5, 2.5), 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(effect, "modulate:a", 0.0, 0.4) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(effect.queue_free)


## Celebration effect: spawn multiple stars floating in random directions.
static func celebration(parent: Control, center: Vector2, count: int = 8) -> void:
	for i in count:
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", randi_range(24, 42))
		star.add_theme_color_override("font_color", COLOR_GOLD)
		star.position = center
		star.z_index = 100
		parent.add_child(star)

		var angle := randf() * TAU
		var dist := randf_range(80.0, 200.0)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * dist

		var tween := star.create_tween()
		tween.set_parallel(true)
		tween.tween_property(star, "position", target_pos, 1.0) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(star, "modulate:a", 0.0, 1.0) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(star, "scale", Vector2(0.3, 0.3), 1.0) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		# Add a slight rotation
		tween.tween_property(star, "rotation", randf_range(-PI, PI), 1.0)
		tween.chain().tween_callback(star.queue_free)


## Gold flash effect for rewards.
static func gold_flash(node: Control, duration: float = 0.4) -> Tween:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", Color(1.3, 1.1, 0.7, 1.0), duration * 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.7) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## "NEW" badge pulse (gentle scale oscillation).
static func badge_pulse(node: Control) -> Tween:
	_ensure_center_pivot(node)
	var tween := node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(0.95, 0.95), 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tween


## Scene entrance: slight zoom from 1.02 to 1.0 on a container.
static func scene_entrance_zoom(node: Control, duration: float = 0.3) -> Tween:
	_ensure_center_pivot(node)
	node.scale = Vector2(1.02, 1.02)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return tween


## Ensure a control's pivot_offset is set to its center for scale animations.
static func _ensure_center_pivot(node: Control) -> void:
	if node.size != Vector2.ZERO:
		node.pivot_offset = node.size * 0.5
	else:
		# Deferred pivot setup for nodes that haven't been laid out yet
		node.resized.connect(func(): node.pivot_offset = node.size * 0.5, CONNECT_ONE_SHOT)
