// 海水着色器（canvas_item）——第四层梦境的海洋。
//
// 效果：上浅下深的水色 + 两层错速横向流动的波浪亮纹 + 远处涌浪的明暗呼吸 + 微光闪烁。
// 全部参数都在材质检查器里可调；改完保存即时生效。
//
// 用法：挂在一个铺满场景的 ColorRect 上（材质 → ShaderMaterial → 本着色器）。
shader_type canvas_item;

// 波浪流动速度倍率。
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;
// 深水色（画面下方）。
uniform vec4 deep_color : source_color = vec4(0.05, 0.17, 0.32, 1.0);
// 浅水色（画面上方）。
uniform vec4 shallow_color : source_color = vec4(0.12, 0.33, 0.52, 1.0);
// 浪尖亮纹的颜色。
uniform vec4 crest_color : source_color = vec4(0.62, 0.8, 0.92, 1.0);
// 亮纹的多少（0 = 几乎没有，1 = 很密）。
uniform float crest_density : hint_range(0.0, 1.0) = 0.5;
// 微光闪烁的强度。
uniform float sparkle_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = UV;
	float t = TIME * wave_speed;

	// 基础水色：上浅下深。
	vec4 col = mix(shallow_color, deep_color, clamp(uv.y * 1.15, 0.0, 1.0));

	// 两层错速波浪亮纹：横向缓慢流动，波峰带一点上下起伏。
	float w1 = sin(uv.y * 110.0 + sin(uv.x * 12.0 + t * 1.1) * 2.2 + t * 0.9);
	float w2 = sin(uv.y * 170.0 - sin(uv.x * 9.0 - t * 0.7) * 2.6 - t * 1.5);
	float crest = smoothstep(0.88 - 0.18 * crest_density, 1.0, w1) * 0.45
			+ smoothstep(0.9 - 0.14 * crest_density, 1.0, w2) * 0.3;
	col = mix(col, crest_color, clamp(crest, 0.0, 1.0));

	// 远处涌浪：大范围的缓慢明暗呼吸。
	col.rgb *= 1.0 + 0.05 * sin(t * 0.5 + uv.x * 5.0 + sin(uv.y * 3.0) * 1.2);

	// 微光闪烁：细密的十字正弦交点偶尔亮一下。
	float spark = sin(uv.x * 260.0 + t * 2.0) * sin(uv.y * 190.0 - t * 1.6);
	col = mix(col, crest_color, clamp(spark, 0.0, 1.0) * 0.08 * sparkle_strength);

	COLOR = col;
}
