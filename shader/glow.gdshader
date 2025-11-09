shader_type canvas_item;

uniform vec4 display_color : source_color;

void fragment() {
    COLOR = display_color;
}
