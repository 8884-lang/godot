extends Node
## =============================================================================
## 状态约定（可选基类）
## -----------------------------------------------------------------------------
## 每个状态脚本建议实现：
##   开始时()  — 刚切换进来时调用一次（播动画、开 HitBox…）
##   结束时()  — 即将离开时调用一次（关 HitBox、断信号…）
##   _physics_process — 该状态下每物理帧的逻辑
##
## class_name PlayerState 方便其它脚本写：PlayerState.设置面向(...)
## 具体状态也可以不 extends 本文件，只要自己实现同名方法即可。
## =============================================================================
class_name PlayerState


func 开始时() -> void:
	pass


func 结束时() -> void:
	pass


## 从当前节点往上找 CharacterBody2D（玩家根）。
## 状态机挂在玩家下时，parent 就是玩家；攻击里嵌套的「移动启用」则要再往上找。
func _角色() -> CharacterBody2D:
	var n: Node = get_parent()
	while n != null and not (n is CharacterBody2D):
		n = n.get_parent()
	return n as CharacterBody2D


## 根据方向更新 facing，并翻转身体/攻击动画的 scale.x
## dir > 0 朝右，dir < 0 朝左；约为 0 则不改
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
