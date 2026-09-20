extends CharacterBody2D
## 敌人：受击闪红 + 击退（暂无死亡）。

@export var knockback_force: float = 280.0
@export var knockback_up: float = -160.0
@export var flash_duration: float = 0.12
@export var friction: float = 800.0

var _flash_tween: Tween


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()


func 受到攻击(击退方向: float) -> void:
	var dir: float = signf(击退方向)
	if is_zero_approx(dir):
		dir = 1.0
	velocity.x = dir * knockback_force
	velocity.y = knockback_up
	_闪红()


func _闪红() -> void:
	var sprite: CanvasItem = get_node_or_null("0") as CanvasItem
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	mat.set_shader_parameter("flash_amount", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, flash_duration)
