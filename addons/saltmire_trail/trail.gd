extends Node
## Saltmire Trail — one-call 2D motion trails / afterimages for Godot 4.
##
## Autoloaded as `Trail`. Spawns fading ghost copies of any CanvasItem
## (Sprite2D, AnimatedSprite2D, Polygon2D, etc.) behind it as it moves.
## Self-contained, zero dependencies, MIT.
##
## Quick use:
##   Trail.attach(sprite)                 # continuous trail while it moves
##   Trail.dash(sprite)                   # one quick burst of ghosts (dodge/dash)
##   Trail.attach(sprite, {               # tune it globally or per-call
##       "color": Color(0.4, 0.8, 1.0),
##       "interval": 0.03,
##       "lifetime": 0.35,
##       "min_distance": 6.0,
##   })
##   Trail.detach(sprite)                 # stop trailing (ghosts fade out)
##   Trail.clear()                        # kill every live ghost right now

## Global defaults. Override once here or pass an overrides dict per call.
var cfg := {
	"color": Color(1, 1, 1, 0.55),   # tint of each ghost (alpha = start opacity)
	"interval": 0.035,               # seconds between spawned ghosts
	"lifetime": 0.20,                # seconds each ghost takes to fade out
	"min_distance": 5.0,             # min px moved before a new ghost spawns
	"scale_end": 1.0,                # ghost scale multiplier at end of life
	"modulate_source": true,         # multiply ghost color by the source modulate
	"z_relative": -1,                # ghost z-index relative to source
}

var _tracked := {}   # source instance_id -> tracking state
var _pool: Node2D    # holds all live ghosts


func _ready() -> void:
	_ensure_pool()


func _ensure_pool() -> void:
	if _pool != null and is_instance_valid(_pool):
		return
	_pool = Node2D.new()
	_pool.name = "SaltmireTrailPool"
	add_child(_pool)


func _process(_delta: float) -> void:
	if _tracked.is_empty():
		return
	var dead: Array = []
	for id in _tracked:
		var state: Dictionary = _tracked[id]
		var src: CanvasItem = instance_from_id(id) as CanvasItem
		if src == null or not is_instance_valid(src):
			dead.append(id)
			continue
		var pos: Vector2 = _global_pos(src)
		var moved: float = pos.distance_to(state.last_pos)
		state.accum += _delta
		var opts: Dictionary = state.opts
		if state.accum >= opts.interval and moved >= opts.min_distance:
			state.accum = 0.0
			state.last_pos = pos
			_spawn_ghost(src, opts)
	for id in dead:
		_tracked.erase(id)


## Start a continuous trail behind `node`. Overrides merge over cfg.
func attach(node: CanvasItem, overrides: Dictionary = {}) -> void:
	if node == null or not is_instance_valid(node):
		return
	_tracked[node.get_instance_id()] = {
		"opts": _merge(overrides),
		"last_pos": _global_pos(node),
		"accum": 0.0,
	}


## Stop trailing `node`. Ghosts already spawned keep fading naturally.
func detach(node: CanvasItem) -> void:
	if node == null:
		return
	_tracked.erase(node.get_instance_id())


## One-shot burst of `count` ghosts behind `node` — great for a dash/dodge.
func dash(node: CanvasItem, count: int = 6, overrides: Dictionary = {}) -> void:
	if node == null or not is_instance_valid(node):
		return
	var opts := _merge(overrides)
	for i in count:
		var g := _spawn_ghost(node, opts)
		if g:
			g.modulate.a *= 1.0 - (float(i) / float(count)) * 0.6


## Remove every live ghost immediately.
func clear() -> void:
	for c in _pool.get_children():
		c.queue_free()


# ── internals ───────────────────────────────────────────────────────────────

func _merge(overrides: Dictionary) -> Dictionary:
	var out := cfg.duplicate()
	for k in overrides:
		out[k] = overrides[k]
	return out


func _global_pos(node: CanvasItem) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	if node is Control:
		return (node as Control).global_position
	return Vector2.ZERO


func _spawn_ghost(src: CanvasItem, opts: Dictionary) -> Node2D:
	var tex := _texture_of(src)
	if tex == null:
		return null
	_ensure_pool()
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.centered = true

	if src is Sprite2D:
		var s := src as Sprite2D
		ghost.centered = s.centered
		ghost.offset = s.offset
		ghost.hframes = s.hframes
		ghost.vframes = s.vframes
		ghost.frame = s.frame
		ghost.flip_h = s.flip_h
		ghost.flip_v = s.flip_v

	if src is Node2D:
		var n := src as Node2D
		ghost.global_position = n.global_position
		ghost.global_rotation = n.global_rotation
		ghost.global_scale = n.global_scale

	var col: Color = opts.color
	if opts.modulate_source:
		col = col * src.modulate
	ghost.modulate = col
	ghost.z_index = src.z_index + int(opts.z_relative)

	_pool.add_child(ghost)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, opts.lifetime)
	if opts.scale_end != 1.0:
		tw.tween_property(ghost, "scale", ghost.scale * float(opts.scale_end), opts.lifetime)
	tw.chain().tween_callback(ghost.queue_free)
	return ghost


func _texture_of(src: CanvasItem) -> Texture2D:
	if src is Sprite2D:
		return (src as Sprite2D).texture
	if src is AnimatedSprite2D:
		var a := src as AnimatedSprite2D
		if a.sprite_frames and a.animation != "":
			return a.sprite_frames.get_frame_texture(a.animation, a.frame)
	if src is TextureRect:
		return (src as TextureRect).texture
	return null
