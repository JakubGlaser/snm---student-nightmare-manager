shader_type canvas_item;

// `progress` is elapsed fraction (0.0 at level start, 1.0 when time runs out).
// The bar is solid black anchored on the RIGHT side. As `progress` grows, the
// leading edge sweeps left -> right, eating the fill from the LEFT. The empty
// portion is transparent so the dark track in the ProgressPanel sprite shows.
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	if (UV.x > progress) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
