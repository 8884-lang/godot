extends Node
## 攻击状态：播动画 + HitBox；通过子节点启用移动脚本，复用完整跑跳/冲刺。

const 移动路径 := "res://玩家Player1/states/移动.gd"
const 移动节点名 := "移动启用"

var _已命中: Array[Node] = []


func 开始时() -> void:
	_已命中.clear()
	var 角色: CharacterBody2D = get_parent()
	var atk: AnimatedSprite2D = _attack(角色)
	var body: Sprite2D = _body(角色)
	var hitbox: Area2D = _hitbox(角色)

	var face: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(face):
		face = signf(角色.velocity.x) if not is_zero_approx(角色.velocity.x) else 1.0
	var sx: float = 1.0 if face >= 0.0 else -1.0
	atk.scale.x = absf(atk.scale.x) * sx
	body.scale.x = absf(body.scale.x) * sx

	atk.visible = true
	atk.play("attack")
	hitbox.monitoring = true
	if not hitbox.body_entered.is_connected(_命中身体):
		hitbox.body_entered.connect(_命中身体)
	call_deferred("_扫描重叠")

	if not atk.animation_finished.is_connected(_攻击结束):
		atk.animation_finished.connect(_攻击结束)

	_启用移动()


func _启用移动() -> void:
	_停用移动()
	var 移动节点 := Node.new()
	移动节点.name = 移动节点名
	add_child(移动节点)
	移动节点.set_script(load(移动路径))
	移动节点.set("允许切入攻击", false)
	移动节点.set_physics_process(true)
	if 移动节点.has_method("开始时"):
		移动节点.开始时()


func _停用移动() -> void:
	var 旧: Node = get_node_or_null(移动节点名)
	if 旧 != null:
		remove_child(旧)
		旧.free()


func _扫描重叠() -> void:
	var hitbox: Area2D = _hitbox(get_parent())
	for body in hitbox.get_overlapping_bodies():
		_命中身体(body)


func _命中身体(body: Node) -> void:
	if body == null or body in _已命中:
		return
	if not body.is_in_group("enemy"):
		return
	if not body.has_method("受到攻击"):
		return
	_已命中.append(body)
	var face_dir: float = signf(_attack(get_parent()).scale.x)
	if is_zero_approx(face_dir):
		face_dir = 1.0
	body.受到攻击(face_dir)


func _攻击结束() -> void:
	var 角色: CharacterBody2D = get_parent()
	var atk: AnimatedSprite2D = _attack(角色)
	var hitbox: Area2D = _hitbox(角色)

	if atk.animation_finished.is_connected(_攻击结束):
		atk.animation_finished.disconnect(_攻击结束)
	if hitbox.body_entered.is_connected(_命中身体):
		hitbox.body_entered.disconnect(_命中身体)

	hitbox.monitoring = false
	atk.stop()
	atk.visible = false
	_已命中.clear()
	_停用移动()

	角色.状态改变(load(移动路径))


func _attack(角色: CharacterBody2D) -> AnimatedSprite2D:
	return 角色.get_node("attack") as AnimatedSprite2D


func _hitbox(角色: CharacterBody2D) -> Area2D:
	return 角色.get_node("attack/HitBox") as Area2D


func _body(角色: CharacterBody2D) -> Sprite2D:
	return 角色.get_node("5") as Sprite2D
