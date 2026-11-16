// 梦层跃迁的马赛克转场（canvas_item）。
//
// progress：0 = 原画面；0~1 马赛克块从 1 像素逐渐长到 max_blocks（画面逐步打码）；
// 1 = 完全马赛克。高 progress 时轻微去饱和 + 压暗，像沉入更深的梦。
//
// 用法：挂在全屏 TextureRect 上，screen_tex 传入截图纹理，progress 由 DreamTransition 驱动。
shader_type canvas_item;

uniform sampler2D screen_tex : source_color, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// 画面的设计尺寸（与 project.godot 的视口一致）。
uniform vec2 screen_size = vec2(1920.0, 1080.0);
// 完全马赛克时单个色块的尺寸（像素）——数值越大块越大。
uniform vec2 max_block_px = vec2(60.0, 60.0);
// 高 progress 时轻微去饱和 + 压暗，像沉入更深的梦。
uniform float fade_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = UV;
	// 马赛克块的"边长"随 progress 从 1px 线性长到 max_block_px——
	// 按块尺寸插值，打码过程全程均匀可感知。
	vec2 block_px = mix(vec2(1.0), max_block_px, progress);
	vec2 blocks = max(floor(screen_size / block_px), vec2(1.0));
	vec2 block_uv = (floor(uv * blocks) + 0.5) / blocks;
	vec4 col = texture(screen_tex, clamp(block_uv, vec2(0.001), vec2(0.999)));

	// 高 progress：轻微去饱和 + 压暗。
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(gray), progress * fade_strength);
	col.rgb *= 1.0 - progress * 0.15 * fade_strength;

	COLOR = col;
}
