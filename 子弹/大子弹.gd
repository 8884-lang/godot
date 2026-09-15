extends CharacterBody2D

@export var damage := 1
@export var speed := 200.0

var direction := Vector2.ZERO

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed

func _physics_process(delta: float) -> void:
	var collision_info := move_and_collide(velocity * delta)
	if collision_info == null:
		return

	var collider := collision_info.get_collider()

	if collider is Node and collider.is_in_group("player"):
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
		queue_free()
		return

	# 撞墙等：不反弹，直接消失
	queue_free()
