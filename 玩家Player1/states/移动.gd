extends Node
## 移动状态：变量与平台跳跃逻辑都在这里。
## 可挂在「状态机」上，也可作为攻击状态下的子节点被启用。
## 角色 = 向上找到的 CharacterBody2D。

@export var speed: float = 150.0
@export var jump_velocity: float = -350.0
@export var acceleration: float = 1000.0
@export var friction: float = 1500.0

@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
@export var dash_end_speed: float = 150.0

@export var wall_slide_gravity: float = 100.0
@export var wall_jump_pushback: float = 260.0
@export var wall_jump_velocity: float = -450.0
@export var wall_jump_lock_time: float = 0.12
@export var wall_coyote_time: float = 0.12
@export var ledge_check_height: float = 80.0
@export var ledge_check_distance: float = 60.0
@export var ledge_assist_speed: float = 50.0

@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15

## 被攻击状态作为子节点启用时设为 false，避免攻击中再次切攻击
var 允许切入攻击: bool = true

const 攻击路径 := "res://玩家Player1/states/攻击.gd"

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_coyote_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0
var has_wall_jumped: bool = false
var last_wall_jump_side: int = 0
var wall_coyote_side: int = 0
var was_touching_wall: bool = false

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1


func 开始时() -> void:
	pass


func _角色() -> CharacterBody2D:
	var n: Node = get_parent()
	while n != null and not (n is CharacterBody2D):
		n = n.get_parent()
	return n as CharacterBody2D


func _physics_process(delta: float) -> void:
	var 角色: CharacterBody2D = _角色()
	if 角色 == null:
		return
	var direction: float = Input.get_axis("move_left", "move_right")

	if 允许切入攻击 and Input.is_action_just_pressed("attack"):
		角色.状态改变(load(攻击路径))
		return

	_更新计时(角色, delta, direction)
	_处理冲刺(角色, delta, direction)
	_处理重力与墙滑(角色, delta, direction)
	_处理跳跃(角色)
	_处理水平(角色, delta, direction)

	角色.move_and_slide()


func _ray_left(角色: CharacterBody2D) -> RayCast2D:
	return 角色.get_node("RayCastLeft") as RayCast2D


func _ray_right(角色: CharacterBody2D) -> RayCast2D:
	return 角色.get_node("RayCastRight") as RayCast2D


func _trail(角色: CharacterBody2D) -> Sprite2D:
	return 角色.get_node("TrailSprite") as Sprite2D


func _更新计时(角色: CharacterBody2D, delta: float, direction: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if 角色.is_on_floor():
		coyote_timer = coyote_time
		has_wall_jumped = false
		last_wall_jump_side = 0
		wall_jump_lock_timer = 0.0
	else:
		coyote_timer -= delta

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	if Input.is_action_just_pressed("move_up"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	var touch_left: bool = _ray_left(角色).is_colliding()
	var touch_right: bool = _ray_right(角色).is_colliding()
	var touching_wall: bool = touch_left or touch_right
	if touching_wall:
		wall_coyote_timer = wall_coyote_time
		if touch_left and touch_right:
			if wall_coyote_side == 0:
				wall_coyote_side = -1 if direction <= 0.0 else 1
		elif touch_left:
			wall_coyote_side = -1
		else:
			wall_coyote_side = 1
	else:
		wall_coyote_timer -= delta

	if touching_wall and not was_touching_wall and not 角色.is_on_floor():
		var current_side: int = -1 if touch_left else 1
		if last_wall_jump_side != 0 and current_side != last_wall_jump_side:
			has_wall_jumped = false
	was_touching_wall = touching_wall


func _处理冲刺(角色: CharacterBody2D, delta: float, direction: float) -> void:
	if (
		Input.is_action_just_pressed("move_dash")
		and dash_cooldown_timer <= 0.0
		and not is_dashing
	):
		var dash_dir: float = direction
		if is_zero_approx(dash_dir):
			dash_dir = signf(角色.velocity.x) if not is_zero_approx(角色.velocity.x) else 1.0
		dash_direction = 1 if dash_dir >= 0.0 else -1
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		角色.velocity.y = 0.0

	if not is_dashing:
		return

	Trail.dash(_trail(角色), 8, {"lifetime": 0.15})
	角色.velocity.x = dash_direction * dash_speed
	角色.velocity.y = 0.0
	dash_timer -= delta
	if dash_timer <= 0.0:
		is_dashing = false
		角色.velocity.x = dash_direction * dash_end_speed
		wall_jump_lock_timer = 0.0


func _处理重力与墙滑(角色: CharacterBody2D, delta: float, direction: float) -> void:
	if is_dashing or 角色.is_on_floor():
		return

	var touch_left: bool = _ray_left(角色).is_colliding()
	var touch_right: bool = _ray_right(角色).is_colliding()
	var on_wall: bool = (touch_left and direction < 0.0) or (touch_right and direction > 0.0)

	角色.velocity += 角色.get_gravity() * delta
	if on_wall and 角色.velocity.y > 0.0 and wall_jump_lock_timer <= 0.0:
		角色.velocity.y = min(角色.velocity.y, wall_slide_gravity)


func _处理跳跃(角色: CharacterBody2D) -> void:
	if jump_buffer_timer <= 0.0 or is_dashing:
		return

	if coyote_timer > 0.0:
		角色.velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return

	var touch_left: bool = _ray_left(角色).is_colliding()
	var touch_right: bool = _ray_right(角色).is_colliding()
	var touching_wall: bool = touch_left or touch_right
	var on_left: bool = touch_left or (wall_coyote_timer > 0.0 and wall_coyote_side < 0)
	var on_right: bool = touch_right or (wall_coyote_timer > 0.0 and wall_coyote_side > 0)
	if has_wall_jumped or not (on_left or on_right):
		return

	var from_left: bool = on_left
	if on_left and on_right:
		from_left = wall_coyote_side <= 0
	elif on_right:
		from_left = false

	var near_ledge: bool = false
	if touching_wall:
		near_ledge = _墙顶空档(角色, from_left)

	jump_buffer_timer = 0.0
	if near_ledge:
		角色.velocity.y = jump_velocity
		角色.velocity.x = ledge_assist_speed if from_left else -ledge_assist_speed
	else:
		角色.velocity.y = wall_jump_velocity
		角色.velocity.x = wall_jump_pushback if from_left else -wall_jump_pushback
		has_wall_jumped = true
		last_wall_jump_side = -1 if from_left else 1
		wall_coyote_side = last_wall_jump_side
		wall_jump_lock_timer = wall_jump_lock_time
		wall_coyote_timer = 0.0


func _墙顶空档(角色: CharacterBody2D, toward_left: bool) -> bool:
	var space := 角色.get_world_2d().direct_space_state
	var local_from := Vector2(0.0, -ledge_check_height)
	var local_to := local_from + Vector2(
		-ledge_check_distance if toward_left else ledge_check_distance, 0.0
	)
	var query := PhysicsRayQueryParameters2D.create(
		角色.to_global(local_from), 角色.to_global(local_to)
	)
	query.exclude = [角色]
	var ray: RayCast2D = _ray_left(角色) if toward_left else _ray_right(角色)
	query.collision_mask = ray.collision_mask
	return space.intersect_ray(query).is_empty()


func _处理水平(角色: CharacterBody2D, delta: float, direction: float) -> void:
	if wall_jump_lock_timer <= 0.0 and not is_dashing:
		if Input.is_action_just_released("move_up") and 角色.velocity.y < 0.0:
			角色.velocity.y *= 0.5

	if is_dashing or wall_jump_lock_timer > 0.0:
		return
	if direction != 0.0:
		角色.velocity.x = move_toward(角色.velocity.x, direction * speed, acceleration * delta)
	else:
		角色.velocity.x = move_toward(角色.velocity.x, 0.0, friction * delta)
