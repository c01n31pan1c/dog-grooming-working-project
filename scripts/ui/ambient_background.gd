class_name AmbientBackground
extends CanvasLayer
## Animated ambient background with sky, clouds, spherical hill, lamp post,
## and dog walkers that traverse the curved pavement.  Renders behind all UI
## on CanvasLayer -1.  Does NOT appear during the Grooming Arena.

# ---- Exports ----
enum TimeOfDay { DAY, GOLDEN, DUSK }

@export_range(0, 3) var walker_count: int = 2
@export_range(0.3, 2.5) var walker_speed: float = 1.0
@export var show_clouds: bool = true
@export var show_lamp_post: bool = true
@export var time_of_day: TimeOfDay = TimeOfDay.DAY

# ---- Design-scale constants (from the 406px-wide JSX reference) ----
# The Godot viewport is 1080x1920.  Scale factor = 1080 / 406 ~ 2.66.
const DESIGN_W := 406.0
const VIEWPORT_W := 1080.0
const VIEWPORT_H := 1920.0
const SCALE := VIEWPORT_W / DESIGN_W  # ~2.66

# Hill / pavement geometry (design-space, scaled at use-site)
const HILL_D := 1240.0
const CREST := 500.0
const PATH_W := 30.0
const PAVE_D := HILL_D - 26.0
const PAVE_R := PAVE_D / 2.0
const CX := DESIGN_W / 2.0
const CY := (CREST + 13.0) + PAVE_R

# Walker constants (design-space)
const MARGIN := 96.0
const WALKER_W := 80.0
const WALKER_H := 58.0
const GAP := 300.0
const SPAN := DESIGN_W + 2.0 * MARGIN
const LOOP := SPAN + GAP
const BASE_V := 40.0  # px/sec in design coords

# ---- Sky presets ----
const SKY_PRESETS := {
	TimeOfDay.DAY: {
		"top": Color("#c2e2f7"),
		"mid": Color("#d9eefb"),
		"bot": Color("#e9f5fc"),
		"sun_color": Color(1.0, 0.878, 0.4, 0.60),
		"sun_pos": Vector2(920.0, 133.0),  # upper-right, partially offscreen
	},
	TimeOfDay.GOLDEN: {
		"top": Color("#fbe4c2"),
		"mid": Color("#fbeede"),
		"bot": Color("#eef6fb"),
		"sun_color": Color(1.0, 0.769, 0.361, 0.70),
		"sun_pos": Vector2(894.0, 266.0),  # right side, lower than day
	},
	TimeOfDay.DUSK: {
		"top": Color("#9fb4e6"),
		"mid": Color("#c9bfe4"),
		"bot": Color("#e7dcf0"),
		"sun_color": Color(1.0, 0.588, 0.588, 0.55),
		"sun_pos": Vector2(160.0, 319.0),  # left side, cool purple glow
	},
}

# Walker roster (design-space, matching the JSX ROSTER)
const ROSTER := [
	{
		"dir": "right", "start": 40.0,
		"shirt": Color("#7fb5e6"), "pants": Color("#46617c"),
		"hair": Color("#5b4636"), "skin": Color("#f0c9a0"),
		"coat": Color("#f4ecdd"), "accent": Color("#e4d6bd"),
	},
	{
		"dir": "left", "start": 560.0,
		"shirt": Color("#ff8c7c"), "pants": Color("#3d3d5c"),
		"hair": Color("#2c2c3a"), "skin": Color("#e8b98c"),
		"coat": Color("#cd9b6a"), "accent": Color("#b9874f"),
	},
	{
		"dir": "right", "start": 980.0,
		"shirt": Color("#b5ead7"), "pants": Color("#344960"),
		"hair": Color("#7a5a3a"), "skin": Color("#f0c9a0"),
		"coat": Color("#d8d2ea"), "accent": Color("#c2b9dc"),
	},
]

# Cloud definitions: top_frac, cloud_scale, duration, delay, opacity
const CLOUD_DEFS := [
	{"top_frac": 0.06, "cloud_scale": 1.1,  "duration": 64.0,  "delay": -10.0, "opacity": 0.95},
	{"top_frac": 0.15, "cloud_scale": 0.7,  "duration": 92.0,  "delay": -48.0, "opacity": 0.80},
	{"top_frac": 0.03, "cloud_scale": 0.85, "duration": 78.0,  "delay": -30.0, "opacity": 0.70},
	{"top_frac": 0.24, "cloud_scale": 0.55, "duration": 110.0, "delay": -70.0, "opacity": 0.60},
]

# ---- Internal state ----
var _elapsed: float = 0.0
var _sky_rect: ColorRect
var _sun_node: Node2D
var _cloud_layer: Node2D
var _hill_layer: Node2D
var _lamp_node: Node2D
var _walker_layer: Node2D
var _clouds: Array[Dictionary] = []  # {node, def}
var _walkers: Array[Dictionary] = []  # {node, cfg}

# ---- Surface math (design-space) ----
static func _surface_y(x: float) -> float:
	var dx := x - CX
	var val := maxf(0.0, PAVE_R * PAVE_R - dx * dx)
	return CY - sqrt(val)

static func _slope_deg(x: float) -> float:
	var dx := x - CX
	var denom := sqrt(maxf(1.0, PAVE_R * PAVE_R - dx * dx))
	return atan2(dx, denom) * (180.0 / PI)


func _ready() -> void:
	layer = -1
	_build_scene()
	# Auto-hide during grooming arena
	if SceneManager:
		SceneManager.scene_loaded.connect(_on_scene_loaded)


func _on_scene_loaded(scene_path: String) -> void:
	# Hide the ambient background during the grooming arena
	var is_arena := scene_path.contains("grooming_arena")
	visible = not is_arena


func _process(delta: float) -> void:
	_elapsed += delta
	_update_clouds()
	_update_walkers()


# ===========================================================================
# BUILD
# ===========================================================================

func _build_scene() -> void:
	# Root Control that fills the viewport and ignores mouse
	var root := Control.new()
	root.name = "BG_Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true
	add_child(root)

	# Sky gradient
	_sky_rect = ColorRect.new()
	_sky_rect.name = "Sky"
	_sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = _create_sky_shader()
	_sky_rect.material = sky_mat
	_apply_sky_colors()
	root.add_child(_sky_rect)

	# Sun glow — drawn as a Node2D inside SubViewportContainer? No, just use
	# a TextureRect with a radial gradient texture.
	var sun_container := Control.new()
	sun_container.name = "SunContainer"
	sun_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sun_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sun_container)
	_sun_node = _build_sun()
	sun_container.add_child(_sun_node)

	# Cloud layer (Node2D-based for easy transform)
	var cloud_control := Control.new()
	cloud_control.name = "CloudControl"
	cloud_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	cloud_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cloud_control)
	_cloud_layer = Node2D.new()
	_cloud_layer.name = "Clouds"
	cloud_control.add_child(_cloud_layer)
	_build_clouds()

	# Hill layer
	var hill_control := Control.new()
	hill_control.name = "HillControl"
	hill_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	hill_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hill_control)
	_hill_layer = Node2D.new()
	_hill_layer.name = "Hill"
	hill_control.add_child(_hill_layer)
	_build_hill()

	# Lamp post
	var lamp_control := Control.new()
	lamp_control.name = "LampControl"
	lamp_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	lamp_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lamp_control)
	_lamp_node = _build_lamp()
	lamp_control.add_child(_lamp_node)
	_lamp_node.visible = show_lamp_post

	# Walker layer
	var walker_control := Control.new()
	walker_control.name = "WalkerControl"
	walker_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	walker_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(walker_control)
	_walker_layer = Node2D.new()
	_walker_layer.name = "Walkers"
	walker_control.add_child(_walker_layer)
	_build_walkers()


# ---- SKY ----

func _create_sky_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.761, 0.886, 0.969, 1.0);
uniform vec4 color_mid : source_color = vec4(0.851, 0.933, 0.984, 1.0);
uniform vec4 color_bot : source_color = vec4(0.914, 0.961, 0.988, 1.0);
uniform float mid_stop : hint_range(0.0, 1.0) = 0.42;
uniform float bot_stop : hint_range(0.0, 1.0) = 0.60;

void fragment() {
	float t = UV.y;
	vec4 c;
	if (t < mid_stop) {
		c = mix(color_top, color_mid, t / mid_stop);
	} else if (t < bot_stop) {
		c = mix(color_mid, color_bot, (t - mid_stop) / (bot_stop - mid_stop));
	} else {
		c = color_bot;
	}
	COLOR = c;
}
"""
	return shader


func _apply_sky_colors() -> void:
	var preset: Dictionary = SKY_PRESETS.get(time_of_day, SKY_PRESETS[TimeOfDay.DAY])
	var mat: ShaderMaterial = _sky_rect.material
	mat.set_shader_parameter("color_top", preset["top"])
	mat.set_shader_parameter("color_mid", preset["mid"])
	mat.set_shader_parameter("color_bot", preset["bot"])


# ---- SUN ----

func _build_sun() -> Node2D:
	var preset: Dictionary = SKY_PRESETS.get(time_of_day, SKY_PRESETS[TimeOfDay.DAY])
	var sun := _SunGlow.new()
	sun.glow_color = preset["sun_color"]
	sun.radius = 90.0 * SCALE  # 180px diameter in design → 90 radius, scaled
	sun.position = preset["sun_pos"]
	return sun


# ---- CLOUDS ----

func _build_clouds() -> void:
	_clouds.clear()
	for cdef in CLOUD_DEFS:
		var cloud := _CloudNode.new()
		cloud.cloud_scale = cdef["cloud_scale"]
		cloud.modulate.a = cdef["opacity"]
		_cloud_layer.add_child(cloud)
		_clouds.append({"node": cloud, "def": cdef})
	_cloud_layer.visible = show_clouds


func _update_clouds() -> void:
	if not show_clouds:
		_cloud_layer.visible = false
		return
	_cloud_layer.visible = true
	var vw := VIEWPORT_W
	for entry in _clouds:
		var cdef: Dictionary = entry["def"]
		var node: Node2D = entry["node"]
		var duration: float = cdef["duration"]
		var delay: float = cdef["delay"]
		# Cloud width in viewport coords
		var cw: float = 120.0 * cdef["cloud_scale"] * SCALE
		var total_span: float = vw + cw
		# Effective time (wrapping)
		var t: float = fmod((_elapsed + delay), duration)
		if t < 0:
			t += duration
		var frac: float = t / duration
		var x: float = -cw + frac * total_span
		var y: float = cdef["top_frac"] * VIEWPORT_H
		node.position = Vector2(x, y)
		node.scale = Vector2(SCALE * cdef["cloud_scale"], SCALE * cdef["cloud_scale"])


# ---- HILL ----

func _build_hill() -> void:
	var hill := _HillDrawer.new()
	hill.bg_scale = SCALE
	_hill_layer.add_child(hill)


# ---- LAMP ----

func _build_lamp() -> Node2D:
	var lamp := _LampDrawer.new()
	# Position: design x=36, surface_y at x=49
	var lx := 36.0 * SCALE
	var ly := _surface_y(49.0) * SCALE - 69.0 * SCALE
	lamp.position = Vector2(lx, ly)
	lamp.lamp_scale = SCALE
	return lamp


# ---- WALKERS ----

func _build_walkers() -> void:
	_walkers.clear()
	for i in range(ROSTER.size()):
		var cfg: Dictionary = ROSTER[i]
		var w := _WalkerDrawer.new()
		w.cfg = cfg
		w.draw_scale = SCALE
		_walker_layer.add_child(w)
		_walkers.append({"node": w, "cfg": cfg})
	_apply_walker_visibility()


func _apply_walker_visibility() -> void:
	for i in range(_walkers.size()):
		_walkers[i]["node"].visible = i < walker_count


func _update_walkers() -> void:
	var v: float = BASE_V * walker_speed
	for i in range(mini(_walkers.size(), walker_count)):
		var entry: Dictionary = _walkers[i]
		var node: _WalkerDrawer = entry["node"]
		var cfg: Dictionary = entry["cfg"]
		node.visible = true
		# Progress along the loop (design-space)
		var s := fmod(cfg["start"] + v * _elapsed, LOOP)
		if s < 0:
			s += LOOP
		var on_path: bool = s <= SPAN
		if not on_path:
			node.visible = false
			continue
		var x: float
		if cfg["dir"] == "right":
			x = -MARGIN + s
		else:
			x = DESIGN_W + MARGIN - s
		var y: float = _surface_y(x) + 13.0  # sit IN the road band
		var lean: float = _slope_deg(x) * 0.9
		# Convert to viewport coords
		node.position = Vector2((x - WALKER_W / 2.0) * SCALE, (y - WALKER_H) * SCALE)
		node.rotation_degrees = lean
		node.flip_h = (cfg["dir"] == "left")
		node.step_time = _elapsed
		node.queue_redraw()
	# Hide extras
	for i in range(walker_count, _walkers.size()):
		_walkers[i]["node"].visible = false


# ---- TIME-OF-DAY SWITCHING ----
func set_time(tod: TimeOfDay) -> void:
	time_of_day = tod
	_apply_sky_colors()
	# Update sun
	if _sun_node:
		var preset: Dictionary = SKY_PRESETS.get(time_of_day, SKY_PRESETS[TimeOfDay.DAY])
		(_sun_node as _SunGlow).glow_color = preset["sun_color"]
		_sun_node.position = preset["sun_pos"]
		_sun_node.queue_redraw()


# ===========================================================================
# INNER DRAW CLASSES
# ===========================================================================

# ---- Sun glow (radial gradient circle) ----
class _SunGlow extends Node2D:
	var glow_color: Color = Color(1, 0.878, 0.4, 0.6)
	var radius: float = 240.0

	func _draw() -> void:
		# Draw concentric circles with decreasing alpha for a soft radial glow
		var steps := 24
		for i in range(steps, -1, -1):
			var frac: float = float(i) / float(steps)
			var r: float = radius * frac
			# Alpha falls off from center; at edge it's 0
			var alpha: float = glow_color.a * (1.0 - frac) * (1.0 - frac)
			var c := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
			draw_circle(Vector2.ZERO, maxf(r, 1.0), c)


# ---- Cloud puff cluster ----
class _CloudNode extends Node2D:
	var cloud_scale: float = 1.0
	# Each cloud is 4 overlapping circles (no scaling here, parent scales)
	func _draw() -> void:
		var col := Color.WHITE
		var shadow_col := Color(0.47, 0.59, 0.69, 0.16)
		# Puffs in local design-unit coords (unscaled, parent does scaling)
		# Puff 1: 70x70 at (24, -18)
		_draw_puff(Vector2(24 + 35, -18 + 35), 35.0, col, shadow_col)
		# Puff 2: 50x50 at (0, 2)
		_draw_puff(Vector2(0 + 25, 2 + 25), 25.0, col, shadow_col)
		# Puff 3: 56x56 at (64, -2)
		_draw_puff(Vector2(64 + 28, -2 + 28), 28.0, col, shadow_col)
		# Base: 120x30 capsule at (0, 16) — approximate as ellipse / wide circle
		_draw_puff(Vector2(60, 16 + 15), 15.0, col, shadow_col, 4.0)

	func _draw_puff(center: Vector2, radius: float, col: Color, shadow: Color, x_stretch: float = 1.0) -> void:
		if x_stretch != 1.0:
			# Draw stretched circle via transform
			draw_set_transform(center, 0.0, Vector2(x_stretch, 1.0))
			draw_circle(Vector2.ZERO, radius, col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(center, radius, col)


# ---- Hill (three concentric circles) ----
class _HillDrawer extends Node2D:
	var bg_scale: float = 1.0

	func _draw() -> void:
		var s := bg_scale
		# Outer grass circle
		var hill_r := AmbientBackground.HILL_D / 2.0 * s
		var hill_cx := AmbientBackground.CX * s
		var hill_cy := (AmbientBackground.CREST + AmbientBackground.HILL_D / 2.0) * s
		draw_circle(Vector2(hill_cx, hill_cy), hill_r, Color("#a3dcbb"))
		# Slight lighter top half via a second smaller circle overlay?
		# Just use the gradient color for outer.  The JSX has a gradient;
		# we approximate with a solid + a lighter overlay at top.
		# Actually, let's draw the top half as a lighter green.
		# For simplicity we draw the full circle then overlay circles.

		# Pavement circle
		var pave_r := AmbientBackground.PAVE_D / 2.0 * s
		var pave_cy := (AmbientBackground.CREST + 13.0 + AmbientBackground.PAVE_D / 2.0) * s
		draw_circle(Vector2(hill_cx, pave_cy), pave_r, Color("#d6e2ec"))

		# Inner grass circle (inside pavement)
		var inner_d := AmbientBackground.PAVE_D - AmbientBackground.PATH_W * 2.0
		var inner_r := inner_d / 2.0 * s
		var inner_cy := (AmbientBackground.CREST + 13.0 + AmbientBackground.PATH_W + inner_d / 2.0) * s
		draw_circle(Vector2(hill_cx, inner_cy), inner_r, Color("#8fd0aa"))


# ---- Lamp post ----
class _LampDrawer extends Node2D:
	var lamp_scale: float = 1.0

	func _draw() -> void:
		var s := lamp_scale
		# Draw from top down, origin at top-left of lamp head
		# Lamp head housing: 22x15 rounded rect
		var head_w := 22.0 * s
		var head_h := 15.0 * s
		var head_rect := Rect2(-head_w / 2.0, 0, head_w, head_h)
		draw_rect(head_rect, Color("#2c3e50"))

		# Warm glow behind lamp head
		var glow_r := 30.0 * s
		draw_circle(Vector2(0, head_h * 0.5), glow_r, Color(1.0, 0.878, 0.4, 0.25))

		# Bulb: 13x6
		var bulb_w := 13.0 * s
		var bulb_h := 6.0 * s
		var bulb_rect := Rect2(-bulb_w / 2.0, head_h - bulb_h * 0.3, bulb_w, bulb_h)
		draw_rect(bulb_rect, Color("#ffe066"))

		# Post: 5x56
		var post_w := 5.0 * s
		var post_h := 56.0 * s
		var post_rect := Rect2(-post_w / 2.0, head_h, post_w, post_h)
		draw_rect(post_rect, Color("#344960"))

		# Base: 26x6
		var base_w := 26.0 * s
		var base_h := 6.0 * s
		var base_rect := Rect2(-base_w / 2.0, head_h + post_h, base_w, base_h)
		draw_rect(base_rect, Color("#2c3e50"))


# ---- Walker (person + dog + leash) ----
class _WalkerDrawer extends Node2D:
	var cfg: Dictionary = {}
	var draw_scale: float = 1.0
	var flip_h: bool = false
	var step_time: float = 0.0

	func _draw() -> void:
		if cfg.is_empty():
			return
		var s := draw_scale
		# The walker group origin is bottom-center of the person's feet.
		# Person is 26w x 58h in design space; dog extends to the right.
		# We draw everything relative to the person's bottom-center.

		var flip_sign := -1.0 if flip_h else 1.0

		# Walking animation: leg swing
		var step_cycle := fmod(step_time, 0.5) / 0.5  # 0..1 over 0.5s
		var leg_a_angle := sin(step_cycle * TAU) * 18.0  # degrees
		var leg_b_angle := sin(step_cycle * TAU + PI) * 18.0

		# Bob animation (subtle vertical bounce)
		var bob := abs(sin(step_cycle * TAU)) * 2.0 * s

		# Colors
		var shirt_col: Color = cfg.get("shirt", Color("#7fb5e6"))
		var pants_col: Color = cfg.get("pants", Color("#46617c"))
		var hair_col: Color = cfg.get("hair", Color("#5b4636"))
		var skin_col: Color = cfg.get("skin", Color("#f0c9a0"))
		var coat_col: Color = cfg.get("coat", Color("#f4ecdd"))
		var accent_col: Color = cfg.get("accent", Color("#e4d6bd"))

		# Drop shadow
		draw_circle(Vector2(0, 0), 10.0 * s, Color(0.173, 0.243, 0.314, 0.10))

		# -- Person (drawn left-to-right in design, flipped if needed) --
		# Person base: x from -13 to +13 (26 wide), y from -58 to 0 (bottom)
		var px := -13.0 * s * flip_sign  # person left offset
		var person_left := px if not flip_h else -px - 26.0 * s

		# Back leg (pants) — behind body
		_draw_leg(Vector2(flip_sign * (9.0 - 13.0) * s, -bob), 7.0 * s, 22.0 * s, pants_col, leg_b_angle)
		# Front leg
		_draw_leg(Vector2(flip_sign * (12.0 - 13.0) * s, -bob), 7.0 * s, 22.0 * s, pants_col, leg_a_angle)

		# Torso (shirt): bottom at -18 from ground, 16w x 26h
		var torso_x := flip_sign * (6.0 - 13.0) * s
		var torso_y := -18.0 * s - 26.0 * s - bob
		var torso_w := 16.0 * s
		var torso_h := 26.0 * s
		if flip_h:
			draw_rect(Rect2(torso_x - torso_w, torso_y, torso_w, torso_h), shirt_col)
		else:
			draw_rect(Rect2(torso_x, torso_y, torso_w, torso_h), shirt_col)

		# Arm (shirt) — swinging
		var arm_x := flip_sign * (9.0 - 13.0) * s
		_draw_arm(Vector2(arm_x, -42.0 * s - bob), 6.0 * s, 20.0 * s, shirt_col, leg_a_angle * 0.7)

		# Extended arm holding leash
		var leash_hand_x := flip_sign * (16.0 - 13.0) * s
		var leash_hand_y := -40.0 * s - bob
		if flip_h:
			_draw_arm_static(Vector2(leash_hand_x - 6.0 * s, leash_hand_y), 6.0 * s, 18.0 * s, skin_col, -28.0)
		else:
			_draw_arm_static(Vector2(leash_hand_x, leash_hand_y), 6.0 * s, 18.0 * s, skin_col, 28.0)

		# Head (circle): at person top
		var head_x := flip_sign * (7.0 + 8.0 - 13.0) * s
		var head_y := -58.0 * s + 8.0 * s - bob
		draw_circle(Vector2(head_x, head_y), 8.0 * s, skin_col)

		# Hair (half circle on top)
		var hair_x := flip_sign * (6.0 + 9.0 - 13.0) * s
		var hair_y := -60.0 * s + 5.5 * s - bob
		if flip_h:
			draw_rect(Rect2(hair_x - 18.0 * s, hair_y - 5.5 * s, 18.0 * s, 11.0 * s), hair_col)
		else:
			draw_rect(Rect2(hair_x - 9.0 * s, hair_y - 5.5 * s, 18.0 * s, 11.0 * s), hair_col)

		# -- Leash --
		var leash_start := Vector2(leash_hand_x, leash_hand_y + 8.0 * s)
		var dog_offset := flip_sign * 30.0 * s
		var leash_end := Vector2(dog_offset, -24.0 * s - bob)
		draw_line(leash_start, leash_end, Color(0.173, 0.243, 0.314, 0.5), 2.0 * s)

		# -- Dog (poodle shape) --
		# Dog is 44w x 34h in design, positioned to the right of person
		var dog_base_x := flip_sign * 17.0 * s  # gap between person and dog
		var dog_y := -bob

		# Dog legs (4 legs with walking animation)
		_draw_dog_leg(Vector2(dog_base_x + flip_sign * 8.0 * s, dog_y), 5.0 * s, 13.0 * s, accent_col, leg_a_angle)
		_draw_dog_leg(Vector2(dog_base_x + flip_sign * 14.0 * s, dog_y), 5.0 * s, 13.0 * s, accent_col, leg_b_angle)
		_draw_dog_leg(Vector2(dog_base_x + flip_sign * 28.0 * s, dog_y), 5.0 * s, 13.0 * s, accent_col, leg_b_angle)
		_draw_dog_leg(Vector2(dog_base_x + flip_sign * 34.0 * s, dog_y), 5.0 * s, 13.0 * s, accent_col, leg_a_angle)

		# Dog body (main puff)
		var body_cx := dog_base_x + flip_sign * 23.0 * s
		var body_cy := -20.0 * s - bob
		draw_circle(Vector2(body_cx, body_cy), 12.0 * s, coat_col)

		# Rear puff
		var rear_cx := dog_base_x + flip_sign * 6.0 * s
		draw_circle(Vector2(rear_cx, -22.0 * s - bob), 6.0 * s, coat_col)

		# Chest puff
		var chest_cx := dog_base_x + flip_sign * 37.0 * s
		draw_circle(Vector2(chest_cx, -20.0 * s - bob), 8.0 * s, coat_col)

		# Head puff
		var head_dog_cx := dog_base_x + flip_sign * 40.0 * s
		draw_circle(Vector2(head_dog_cx, -27.0 * s - bob), 7.5 * s, coat_col)

		# Top head puff
		var top_cx := dog_base_x + flip_sign * 40.0 * s
		draw_circle(Vector2(top_cx, -34.0 * s - bob), 5.0 * s, coat_col)

		# Snout
		var snout_cx := dog_base_x + flip_sign * 47.0 * s
		draw_circle(Vector2(snout_cx, -24.0 * s - bob), 4.0 * s, accent_col)

		# Eye
		var eye_cx := dog_base_x + flip_sign * 49.0 * s
		draw_circle(Vector2(eye_cx, -28.0 * s - bob), 1.5 * s, Color("#2c3e50"))


	func _draw_leg(pos: Vector2, w: float, h: float, col: Color, angle_deg: float) -> void:
		var angle := deg_to_rad(angle_deg)
		draw_set_transform(pos, angle, Vector2.ONE)
		draw_rect(Rect2(-w / 2.0, -h, w, h), col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_arm(pos: Vector2, w: float, h: float, col: Color, angle_deg: float) -> void:
		var angle := deg_to_rad(angle_deg)
		draw_set_transform(pos, angle, Vector2.ONE)
		draw_rect(Rect2(-w / 2.0, 0, w, h), col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_arm_static(pos: Vector2, w: float, h: float, col: Color, angle_deg: float) -> void:
		var angle := deg_to_rad(angle_deg)
		draw_set_transform(pos, angle, Vector2.ONE)
		draw_rect(Rect2(-w / 2.0, 0, w, h), col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_dog_leg(pos: Vector2, w: float, h: float, col: Color, angle_deg: float) -> void:
		var angle := deg_to_rad(angle_deg)
		draw_set_transform(pos, angle, Vector2.ONE)
		draw_rect(Rect2(-w / 2.0, -h, w, h), col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
