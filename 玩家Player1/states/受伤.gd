extends Node
## =============================================================================
## 受伤状态
## -----------------------------------------------------------------------------
## 外部造成伤害请调用（不要依赖角色.受伤，逻辑都在本文件）：
##   preload("res://玩家Player1/states/受伤.gd").应用(玩家, 伤害, 击退方向)
##
## 流程：应用() 扣血/切状态/击退 → 开始时() 开无敌 → 硬直结束 → 回移动
## =============================================================================

const 本脚本路径 := "res://玩家Player1/states/受伤.gd"
const 移动路径 := "res://玩家Player1/states/移动.gd"

@export var stun_time: float = 0.25 ## 硬直多久后才能回移动
@export var invincible_time: float = 0.6 ## 无敌持续时间
@export var knockback_force: float = 220.0 ## 水平击退（检查器备用）
@export var knockback_up: float = -120.0 ## 向上击退（检查器备用）

var _timer: float = 0.0 ## 硬直倒计时


## 受击总入口：判无敌 → 扣血 → 发信号 → 进入本状态 → 施加击退
static func 应用(角色: CharacterBody2D, 伤害: int = 1, 击退方向: float = 0.0) -> void:
	if 角色 == null:
		return
	# 无敌中或已死亡：直接忽略
	if bool(角色.get("无敌")) or int(角色.get("hp")) <= 0:
		return
	角色.set("hp", maxi(int(角色.get("hp")) - 伤害, 0))
	if 角色.has_signal("hurt"):
		角色.hurt.emit(伤害)
	if int(角色.get("hp")) <= 0 and 角色.has_signal("died"):
		角色.died.emit()
	# 切到受伤状态（会触发下面的 开始时）
	角色.状态改变(load(本脚本路径))
	# 击退：static 里用与 export 默认相同的常数
	if not is_zero_approx(击退方向):
		角色.velocity.x = signf(击退方向) * 220.0
		角色.velocity.y = minf(角色.velocity.y, -120.0)


func 开始时() -> void:
	_timer = stun_time
	var 角色 := _角色()
	if 角色 == null:
		return
	# 进入硬直同时开无敌；到时自动关（角色仍有效才写回）
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
	# 硬直中：仍受重力，水平逐渐刹住
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
