extends Node
## 状态基类：约定接口 + 跨状态工具（面向等）。
class_name PlayerState


func 开始时() -> void:
	pass


func 结束时() -> void:
	pass


func _角色() -> CharacterBody2D:
	var n: Node = get_parent()
	while n != null and not (n is CharacterBody2D):
		n = n.get_parent()
	return n as CharacterBody2D


## 面向逻辑在状态侧；根脚本只保留 facing 数据。
static func 设置面向(角色: CharacterBody2D, dir: float) -> void:
	if 角色 == null or is_zero_approx(dir):
		return
	角色.set("facing", 1 if dir > 0.0 else -1)
	var sx := float(角色.get("facing"))
	var body: Sprite2D = 角色.get("body_sprite") as Sprite2D
	var atk: AnimatedSprite2D = 角色.get("attack_anim") as AnimatedSprite2D
	if body != null:
		body.scale.x = absf(body.scale.x) * sx
	if atk != null:
		atk.scale.x = absf(atk.scale.x) * sx
