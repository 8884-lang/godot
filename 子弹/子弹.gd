extends CharacterBody2D

@export var damage := 1
@export var speed := 100.0
@export var bounce_modifier := 1.0
@export var num := 0
@export var arm_time := 2.0
var can_hit_boss := false

## 发射前由外部赋值，不再默认向右
var direction := Vector2.ZERO

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_mask = 3          # 先不碰 Boss
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
	_arm()
func _arm() -> void:
	await get_tree().create_timer(arm_time).timeout
	if not is_inside_tree():
		return
	collision_mask = 3 | 8      # 2 秒后才能撞 Boss
	can_hit_boss = true

func _physics_process(delta: float) -> void:
	var collision_info := move_and_collide(velocity * delta)
	if collision_info == null:
		return
	var collider := collision_info.get_collider()
	if collider == null:
		return

	if collider.is_in_group("player"):
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
		queue_free()
		return

	if collider.is_in_group("boss"):
		if can_hit_boss:
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
		return  # 未满 2 秒：不伤、不销毁（见下条）

	# 只有墙等才反弹计数
	# 只有墙等才反弹
	num += 1
	if num > 3:
		queue_free()
		return
	velocity = velocity.bounce(collision_info.get_normal())
	velocity *= bounce_modifier
	velocity = velocity.normalized() * speed
