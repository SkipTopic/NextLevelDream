// 标题页萤火虫（canvas_item）——一群飞来飞去的光点，灯忽明忽暗。
//
// 用法：挂在主菜单一个铺满全屏、mouse_filter = Ignore 的 ColorRect 上。
// 数量（循环上限）、颜色、速度、光晕大小都可在下方调整 / 材质参数里调。
shader_type canvas_item;

// 画面宽高比（1920x1080 → 16:9），决定游荡空间的坐标尺度。
uniform vec2 aspect = vec2(16.0, 9.0);
// 整体飞舞速度倍率。
uniform float speed : hint_range(0.0, 3.0) = 1.0;
// 光点与光晕的大小倍率。
uniform float glow_size : hint_range(0.5, 3.0) = 1.0;
// 萤火虫的灯色。
uniform vec4 firefly_color : source_color = vec4(0.72, 1.0, 0.35, 1.0);

float hash1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

vec2 hash2(float n) {
	return vec2(hash1(n), hash1(n + 7.7));
}

void fragment() {
	vec2 p = UV * aspect;
	vec3 add = vec3(0.0);

	// 18 只萤火虫：每只一个游荡中心 + 两组不同频率的圆周运动叠出"飞来飞去"的路径。
	for (int i = 0; i < 18; i++) {
		float fi = float(i);
		vec2 seed = hash2(fi + 1.0);
		vec2 home = vec2(0.15 + 0.7 * hash1(fi * 3.1), 0.2 + 0.65 * hash1(fi * 5.7)) * aspect;
		vec2 drift = vec2(
			sin((0.25 + seed.x * 0.4) * TIME * speed + seed.y * 6.2832),
			cos((0.21 + seed.y * 0.4) * TIME * speed + seed.x * 6.2832)
		) * (0.9 + seed.x * 1.6);
		drift += vec2(
			sin((1.2 + seed.y) * TIME * speed + fi * 2.1),
			cos((1.05 + seed.x) * TIME * speed + fi * 1.7)
		) * 0.3;
		vec2 pos = home + drift;
		float d = length(p - pos);

		// 灯忽明忽暗：慢呼吸叠加快闪，立方后大多数时间偏暗、偶尔亮起。
		float blink = 0.5 + 0.5 * sin(TIME * (1.2 + seed.x * 2.2) * speed + seed.y * 41.0);
		blink = pow(blink, 3.0) * 0.85 + 0.05;

		float g = glow_size * (0.75 + 0.5 * blink);
		float core = smoothstep(0.035 * g, 0.0, d);
		float halo = smoothstep(0.17 * g, 0.0, d) * 0.32;
		add += firefly_color.rgb * (core * (0.55 + 1.05 * blink) + halo * blink);
	}

	float a = clamp(max(add.r, max(add.g, add.b)) * 1.2, 0.0, 1.0);
	COLOR = vec4(add, a);
}
