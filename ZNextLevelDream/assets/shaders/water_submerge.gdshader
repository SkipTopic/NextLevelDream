// 站在海水里的沉浸效果（canvas_item）——挂在第四层海洋的 Player 精灵上。
//
// 水面（约大腿位置）以下的身体逐渐被水色吞没：越深越透明，
// 脚底几乎完全融进海里；水面线带轻微波动和一道反光亮边。
//
// 注意：Player 的动画帧是图集（AtlasTexture）的子区域，
// shader 里的 UV 跨整张图集——所以要用 frame_region / atlas_size
// 把坐标换算回"当前帧内部"（Dream4Ocean 每次帧变化都会更新这两个参数）。
shader_type canvas_item;

// 海水色（与海洋背景的水色一致）。
uniform vec4 water_color : source_color = vec4(0.07, 0.2, 0.36, 1.0);
// 水面在精灵帧内的位置（0 = 头顶，1 = 脚底）。大腿 ≈ 0.7。
uniform float waterline_v : hint_range(0.0, 1.0) = 0.7;
// 脚底处被水覆盖的程度（1 = 完全融入水中）。
uniform float max_submerge : hint_range(0.0, 1.0) = 0.9;
// 水面线的波浪幅度（帧内 v 值）。
uniform float wave_amp : hint_range(0.0, 0.05) = 0.012;
// 图集尺寸与当前帧区域（由 Dream4Ocean 逐帧更新）。
uniform vec2 atlas_size = vec2(360.0, 720.0);
uniform vec4 frame_region = vec4(0.0, 0.0, 120.0, 180.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// UV（图集坐标）→ 当前帧内部的纵向位置：0 = 头顶，1 = 脚底。
	vec2 local_px = UV * atlas_size - frame_region.xy;
	float local_v = local_px.y / max(frame_region.w, 1.0);

	// 水面线（带轻微波动）。
	float waterline = waterline_v + sin(local_px.x * 0.12 + TIME * 2.2) * wave_amp;

	if (local_v > waterline) {
		float depth = clamp((local_v - waterline) / max(1.0 - waterline, 0.001), 0.0, 1.0);
		float sub = depth * max_submerge;
		// 越深越偏水色、越透明：脚底几乎完全融进海里。
		col.rgb = mix(col.rgb, water_color.rgb, sub);
		col.a *= 1.0 - sub * 0.85;
	}

	// 水面线附近一道反光亮边。
	float line_d = abs(local_v - waterline);
	col.rgb += vec3(0.4, 0.55, 0.65) * smoothstep(0.025, 0.0, line_d) * 0.4;

	COLOR = col;
}
