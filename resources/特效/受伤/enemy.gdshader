shader_type canvas_item;

// 闪烁的颜色，默认红色。可以在检查器里改成白色或其他颜色
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

// 闪烁强度，0.0 是原色，1.0 是全红。代码控制这个变量
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // 获取原本的颜色（包含贴图和 modulate 属性）
    vec4 base_color = COLOR;
    
    // 混合原色和闪烁颜色。flash_amount 为 1 时完全变成红色
    COLOR.rgb = mix(base_color.rgb, flash_color.rgb, flash_amount);
    
    // 保持原有的透明度，防止变红时把透明背景也显示出来
    COLOR.a = base_color.a;
}
