// 撕书动画（canvas_item）——把写日记瞬间的截图当"一页纸"撕成两半。
//
// progress：0 = 完整画面；0~0.08 中缝出现毛边裂缝；0.08~1 两半向两侧撕开，背后全黑；
// progress = 1 时整屏全黑。动画节奏由 TearPage.gd 驱动。
//
// 用法：挂在一个全屏 TextureRect 上，page_tex 传入截图纹理。
shader_type canvas_item;

uniform sampler2D page_tex : source_color, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// 不规则撕边：几组不同频率的正弦叠加出毛边。
float jagged(float y) {
	return sin(y * 46.0) * 0.011 + sin(y * 17.0 + 2.6) * 0.018 + sin(y * 93.0 + 1.3) * 0.005;
}

void fragment() {
	vec2 uv = UV;
	float edge = 0.5 + jagged(uv.y * 6.2832);   // 撕裂线中心（带毛边）
	float half_gap = progress * 0.55;           // 裂缝半宽

	vec4 col = vec4(0.0, 0.0, 0.0, 1.0);        // 撕开后背后是全黑

	// 两半向两侧错开；错开量沿高度有随机差 → 像纸被撕开而不是对称平移。
	float tear_y = jagged(uv.y * 6.2832 + 1.7);
	float left_shift = -(half_gap + progress * 0.02 * sin(uv.y * 4.0 + 1.0)) + tear_y * progress * 0.4;
	float right_shift = half_gap + progress * 0.02 * sin(uv.y * 3.1) - tear_y * progress * 0.4;

	if (uv.x < edge) {
		float su = uv.x - left_shift;
		if (su >= 0.0 && su <= 1.0) {
			col = texture(page_tex, vec2(su, uv.y));
		}
	} else {
		float su = uv.x - right_shift;
		if (su >= 0.0 && su <= 1.0) {
			col = texture(page_tex, vec2(su, uv.y));
		}
	}

	// 撕口毛边：越靠近撕裂线越暗。
	float edge_dist = abs(uv.x - (edge + sign(uv.x - edge) * half_gap));
	col.rgb *= 1.0 - smoothstep(0.03, 0.0, edge_dist) * 0.65;

	COLOR = col;
}
