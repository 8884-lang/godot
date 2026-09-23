extends CharacterBody2D
## =============================================================================
## Player 根脚本（长期存在）
## -----------------------------------------------------------------------------
## 场景结构（Player1.tscn）：
##   CharacterBody2D          ← 本脚本
##   ├── Visual               ← 表现：身体图、攻击动画、残影
##   ├── CollisionShape2D     ← 物理身体
##   ├── RayCastLeft/Right    ← 贴墙检测
##   ├── HurtBox              ← 受击判定区（预留）
##   ├── Camera2D
##   └── 状态机               ← 临时挂「当前状态」脚本（移动/攻击/受伤）
##
## 分工：
##   - 这里：跨状态共享的数据、节点引用、状态切换
##   - states/*.gd：某一阶段的具体行为
##   - 面向：PlayerState.设置面向()
##   - 受伤：受伤.gd.应用()
## =============================================================================

# ----- 信号：给 UI / 关卡听，不要绑死在某个状态上 -----
signal hurt(amount: int) ## 扣血时发出（参数=本次伤害）
signal died ## 生命降到 0 时发出

# ----- 默认状态 -----
const 移动路径 := "res://玩家Player1/states/移动.gd"

# ----- 共享数据（多个状态都会读/写）-----
@export var max_hp: int = 3 ## 最大生命（检查器可调）

var hp: int = 3 ## 当前生命
var facing: int = 1 ## 朝向：1=右，-1=左
var 无敌: bool = false ## true 时忽略新的受击

# ----- 节点引用：状态里用 角色.xxx，少写长路径字符串 -----
@onready var 状态机: Node = $状态机 ## 当前状态脚本挂在这里
@onready var visual: Node2D = $Visual ## 表现根节点
@onready var body_sprite: Sprite2D = $Visual/Body ## 站立/移动外观
@onready var attack_anim: AnimatedSprite2D = $Visual/AttackAnim ## 攻击动画
@onready var hit_box: Area2D = $Visual/AttackAnim/HitBox ## 打敌人的判定
@onready var trail_sprite: Sprite2D = $Visual/TrailSprite ## 冲刺残影用
@onready var ray_left: RayCast2D = $RayCastLeft ## 左侧墙壁
@onready var ray_right: RayCast2D = $RayCastRight ## 右侧墙壁
@onready var hurt_box: Area2D = $HurtBox ## 被打判定（预留）


func _ready() -> void:
	# 开局满血；平时关掉攻击 HitBox，避免误伤
	hp = max_hp
	hit_box.monitoring = false
	# 进入默认「移动」状态
	状态改变(load(移动路径))


## 切换状态的唯一入口。任意状态里调用：角色.状态改变(load(某路径))
## 流程：旧状态.结束时 → 清子节点 → 换脚本 → 新状态.开始时
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
