// 树木风摆（canvas_item）——挂在深林世界的每一棵树的精灵上。
//
// 效果：树冠（顶部）随风左右摇摆，树干底部完全固定——
// 权重 = (1 - UV.y)^1.8（UV.y = 0 在树顶、1 在树底），摆动幅度越靠下越小。
// 每棵树一个独立的 phase 参数（由场景代码按位置生成），
// 叠加两个不同频率的正弦，摆动更自然、不会整排同步。
shader_type canvas_item;

// 摆动幅度（像素，树顶处最大）。
uniform float sway_strength : hint_range(0.0, 40.0) = 14.0;
// 摆动速度倍率。
uniform float sway_speed : hint_range(0.0, 3.0) = 1.0;
// 每棵树的独立相位（按位置生成，避免整排同摆）。
uniform float phase = 0.0;

void vertex() {
	// 底部固定、顶部摆动：权重 = (1 - UV.y)^1.8。
	float w = pow(1.0 - UV.y, 1.8);
	// 主摆（低频）+ 二级摆（高频小幅度），两层叠加更自然。
	VERTEX.x += sin(TIME * 1.6 * sway_speed + phase + UV.y * 2.0) * sway_strength * w;
	VERTEX.x += sin(TIME * 2.7 * sway_speed + phase * 2.0) * sway_strength * 0.3 * w;
}
