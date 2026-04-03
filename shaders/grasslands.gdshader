shader_type spatial;

uniform sampler2D grass_tex;
uniform sampler2D rock_tex;
uniform float min_rock_slope = 0.5; // Steepness threshold
uniform float max_grass_slope = 0.9; // Smoothness threshold

varying float normalY;

uniform float uv_scale = 15.0;

void vertex() {
    // Pass the normal Y to fragment shader
    normalY = NORMAL.y;
}

void fragment() {
    // Smoothly blend based on steepness
    float weight = smoothstep(min_rock_slope, max_grass_slope, normalY);
    vec2 scaled_uv = UV * uv_scale;
    vec4 grass = texture(grass_tex, scaled_uv);
    vec4 rock = texture(rock_tex, scaled_uv);
    
    // Mix textures: 1.0 (flat) = grass, 0.0 (steep) = rock
    ALBEDO = mix(rock.rgb, grass.rgb, weight);
}
