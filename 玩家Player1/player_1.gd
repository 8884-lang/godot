extends CharacterBody2D
## 角色：只负责状态切换。

const 移动路径 := "res://玩家Player1/states/移动.gd"
const 攻击路径 := "res://玩家Player1/states/攻击.gd"

@onready var 状态机: Node = $状态机


func _ready() -> void:
	状态改变(load(移动路径))


func 状态改变(新状态: Script) -> void:
	for c in 状态机.get_children():
		状态机.remove_child(c)
		c.free()
	状态机.set_script(新状态)
	状态机.set_physics_process(true)
	if 状态机.has_method("开始时"):
		状态机.开始时()
