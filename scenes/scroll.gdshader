shader_type canvas_item;

// Wartość od 0.0 do 1.0 kontrolowana ze skryptu
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 shifted_uv = UV;
    // fract sprawia, że gdy UV wyjdzie poza 1.0, wraca automatycznie do 0.0 (pętla)
    shifted_uv.x = fract(UV.x + progress);
    
    COLOR = texture(TEXTURE, shifted_uv);
}