extends Node
## =============================================================================
## 攻击状态
## -----------------------------------------------------------------------------
## 进入时：定面向、播攻击动画、打开 HitBox、挂一个「移动」子节点（可边打边移动，
##         但 允许切入攻击=false，防止攻击中再切攻击）。
## 结束时：关 HitBox、藏动画、拆掉移动子节点，并由动画结束切回移动状态。
## =============================================================================

const 移动路径 := "res://玩家Player1/states/移动.gd"
const 移动节点名 := "移动启用"

var _已命中: Array[Node] = [] ## 本次攻击已打到的敌人，避免同一帧多次结算


func 开始时() -> void:
	_已命中.clear()
	var 角色: CharacterBody2D = get_parent()
	var atk: AnimatedSprite2D = _attack(角色)
	var hitbox: Area2D = _hitbox(角色)

	# 优先按键方向，否则用当前速度决定朝向
	var face: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(face):
		face = signf(角色.velocity.x) if not is_zero_approx(角色.velocity.x) else 1.0
	PlayerState.设置面向(角色, face)

	atk.visible = true
	atk.play("attack")
	hitbox.monitoring = true # 开始检测碰到的敌人
	if not hitbox.body_entered.is_connected(_命中身体):
		hitbox.body_entered.connect(_命中身体)
	# 若攻击开始时已经叠在敌人身上，补一次重叠检测
	call_deferred("_扫描重叠")

	if not atk.animation_finished.is_connected(_攻击结束):
		atk.animation_finished.connect(_攻击结束)

	_启用移动()


func 结束时() -> void:
	# 离开攻击状态时务必收尾，防止 HitBox 一直开着
	var 角色: CharacterBody2D = get_parent()
	var atk: AnimatedSprite2D = _attack(角色)
	var hitbox: Area2D = _hitbox(角色)
	if atk != null and atk.animation_finished.is_connected(_攻击结束):
		atk.animation_finished.disconnect(_攻击结束)
	if hitbox != null:
		if hitbox.body_entered.is_connected(_命中身体):
			hitbox.body_entered.disconnect(_命中身体)
		hitbox.monitoring = false
	if atk != null:
		atk.stop()
		atk.visible = false
	_停用移动()
	_已命中.clear()


## 在攻击状态下挂一份移动逻辑（子节点），复用跑跳/冲刺代码
func _启用移动() -> void:
	_停用移动()
	var 移动节点 := Node.new()
	移动节点.name = 移动节点名
	add_child(移动节点)
	移动节点.set_script(load(移动路径))
	移动节点.set("允许切入攻击", false) # 攻击中禁止再切攻击
	移动节点.set_physics_process(true)
	if 移动节点.has_method("开始时"):
		移动节点.开始时()


func _停用移动() -> void:
	var 旧: Node = get_node_or_null(移动节点名)
	if 旧 != null:
		if 旧.has_method("结束时"):
			旧.结束时()
		remove_child(旧)
		旧.free()


func _扫描重叠() -> void:
	var hitbox: Area2D = _hitbox(get_parent())
	if hitbox == null:
		return
	for body in hitbox.get_overlapping_bodies():
		_命中身体(body)


## HitBox 碰到敌人：调用敌人.受到攻击(方向)
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
	# 清理工作由 状态改变 → 结束时() 统一做，这里只负责切回移动
	get_parent().状态改变(load(移动路径))


func _attack(角色: CharacterBody2D) -> AnimatedSprite2D:
	if "attack_anim" in 角色:
		return 角色.attack_anim as AnimatedSprite2D
	return 角色.get_node("Visual/AttackAnim") as AnimatedSprite2D


func _hitbox(角色: CharacterBody2D) -> Area2D:
	if "hit_box" in 角色:
		return 角色.hit_box as Area2D
	return 角色.get_node("Visual/AttackAnim/HitBox") as Area2D
