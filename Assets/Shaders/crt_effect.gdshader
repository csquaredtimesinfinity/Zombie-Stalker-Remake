shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float scanline_density : hint_range(100.0, 2000.0) = 800.0;

// Custom random function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Horizontal scanlines
    float scan = sin(UV.y * scanline_density + UV.y * TIME * 20.5) * 0.5 + 0.5;
    color.rgb *= mix(1.0, scan, scanline_intensity);

    COLOR = color;
}
