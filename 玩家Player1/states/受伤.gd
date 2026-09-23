extends Node
## 受伤状态：扣血、击退、无敌、硬直，然后回到移动。

const 本脚本路径 := "res://玩家Player1/states/受伤.gd"
const 移动路径 := "res://玩家Player1/states/移动.gd"

@export var stun_time: float = 0.25
@export var invincible_time: float = 0.6
@export var knockback_force: float = 220.0
@export var knockback_up: float = -120.0

var _timer: float = 0.0


## 外部入口（敌人等）：preload 本脚本后调用 应用(角色, 伤害, 击退方向)
static func 应用(角色: CharacterBody2D, 伤害: int = 1, 击退方向: float = 0.0) -> void:
	if 角色 == null:
		return
	if bool(角色.get("无敌")) or int(角色.get("hp")) <= 0:
		return
	角色.set("hp", maxi(int(角色.get("hp")) - 伤害, 0))
	if 角色.has_signal("hurt"):
		角色.hurt.emit(伤害)
	if int(角色.get("hp")) <= 0 and 角色.has_signal("died"):
		角色.died.emit()
	角色.状态改变(load(本脚本路径))
	if not is_zero_approx(击退方向):
		# 与下方 @export 默认值一致（static 入口在实例化前调用）
		角色.velocity.x = signf(击退方向) * 220.0
		角色.velocity.y = minf(角色.velocity.y, -120.0)


func 开始时() -> void:
	_timer = stun_time
	var 角色 := _角色()
	if 角色 == null:
		return
	角色.无敌 = true
	var t: float = invincible_time
	var 树 := 角色.get_tree()
	if 树 != null:
		树.create_timer(t).timeout.connect(
			func() -> void:
				if is_instance_valid(角色):
					角色.无敌 = false,
			CONNECT_ONE_SHOT
		)


func 结束时() -> void:
	pass


func _physics_process(delta: float) -> void:
	var 角色 := _角色()
	if 角色 == null:
		return
	if not 角色.is_on_floor():
		角色.velocity += 角色.get_gravity() * delta
	角色.velocity.x = move_toward(角色.velocity.x, 0.0, 1200.0 * delta)
	角色.move_and_slide()
	_timer -= delta
	if _timer <= 0.0:
		角色.状态改变(load(移动路径))


func _角色() -> CharacterBody2D:
	var n: Node = get_parent()
	while n != null and not (n is CharacterBody2D):
		n = n.get_parent()
	return n as CharacterBody2D
