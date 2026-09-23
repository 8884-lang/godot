extends CharacterBody2D
## 根脚本：共享数据 + 状态切换。表现 / 物理 / 判定节点由此引用。
## 面向 → PlayerState.设置面向；受伤 → 受伤.gd.应用

signal hurt(amount: int)
signal died

const 移动路径 := "res://玩家Player1/states/移动.gd"

@export var max_hp: int = 3

var hp: int = 3
var facing: int = 1
var 无敌: bool = false

@onready var 状态机: Node = $状态机
@onready var visual: Node2D = $Visual
@onready var body_sprite: Sprite2D = $Visual/Body
@onready var attack_anim: AnimatedSprite2D = $Visual/AttackAnim
@onready var hit_box: Area2D = $Visual/AttackAnim/HitBox
@onready var trail_sprite: Sprite2D = $Visual/TrailSprite
@onready var ray_left: RayCast2D = $RayCastLeft
@onready var ray_right: RayCast2D = $RayCastRight
@onready var hurt_box: Area2D = $HurtBox


func _ready() -> void:
	hp = max_hp
	hit_box.monitoring = false
	状态改变(load(移动路径))


func 状态改变(新状态: Script) -> void:
	if 状态机.has_method("结束时"):
		状态机.结束时()
	for c in 状态机.get_children():
		状态机.remove_child(c)
		c.free()
	状态机.set_script(新状态)
	状态机.set_physics_process(true)
	if 状态机.has_method("开始时"):
		状态机.开始时()
