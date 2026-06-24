shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// Fur parameters
uniform vec4 fur_color : source_color = vec4(0.65, 0.45, 0.25, 1.0);
uniform vec4 fur_tip_color : source_color = vec4(0.85, 0.7, 0.45, 1.0);
uniform float fur_length : hint_range(0.0, 0.15) = 0.04;
uniform float fur_density : hint_range(1.0, 80.0) = 40.0;
uniform int shell_index = 0;
uniform int shell_count = 6;

// Grooming state
uniform float groomed_amount : hint_range(0.0, 1.0) = 0.0;

// Highlight state
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 highlight_color : source_color = vec4(0.3, 0.7, 1.0, 0.4);

// Guide overlay
uniform float guide_overlay_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 guide_color : source_color = vec4(1.0, 0.0, 0.0, 0.5);

// Hash function for procedural noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	float shell_frac = float(shell_index) / float(max(shell_count - 1, 1));
	// Reduce extrusion when groomed
	float effective_length = fur_length * (1.0 - groomed_amount * 0.6);
	VERTEX += NORMAL * effective_length * shell_frac;
}

void fragment() {
	float shell_frac = float(shell_index) / float(max(shell_count - 1, 1));

	// UV-based noise for fur strand pattern
	vec2 scaled_uv = UV * fur_density;
	vec2 cell = floor(scaled_uv);
	float noise_val = hash(cell);

	// Threshold increases with shell layer — outer shells have more transparency
	float threshold = shell_frac * shell_frac;
	// Density adjustment when groomed: fur appears neater
	float density_mod = 1.0 - groomed_amount * 0.3;
	float alpha = step(threshold, noise_val * density_mod);

	// Discard transparent pixels (base shell always solid)
	if (shell_index > 0 && alpha < 0.5) {
		discard;
	}

	// Color gradient from root to tip
	vec3 base_col = mix(fur_color.rgb, fur_tip_color.rgb, shell_frac);

	// Simple AO — darker at root
	float ao = mix(0.4, 1.0, shell_frac);
	base_col *= ao;

	// Apply highlight (hover state)
	base_col = mix(base_col, highlight_color.rgb, highlight_strength * 0.3);

	// Apply guide overlay
	base_col = mix(base_col, guide_color.rgb, guide_overlay_strength * 0.5);

	ALBEDO = base_col;
	ROUGHNESS = 0.8;
	SPECULAR = 0.1;

	// Slight transparency on outer shells for softness
	if (shell_index > 0) {
		ALPHA = mix(1.0, 0.7, shell_frac * 0.5);
	} else {
		ALPHA = 1.0;
	}
}
