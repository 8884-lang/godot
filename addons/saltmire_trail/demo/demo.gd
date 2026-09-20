extends Node2D
## Self-playing showcase: each mode below is a SINGLE call to Trail.
## Click or press Space to jump to the next demo.

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $UI/Effect
var _i := 0
var _skip := false
var _t := 0.0

const MODES := [
	"attach() — continuous",
	"attach() — cyan speed",
	"dash() — burst",
	"attach() — shrinking ghosts",
]


func _ready() -> void:
	_loop()


func _loop() -> void:
	while true:
		var name: String = MODES[_i % MODES.size()]
		label.text = "Trail." + name
		Trail.detach(sprite)
		Trail.clear()
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(0.4, 0.4)
		match name:
			"attach() — continuous":
				Trail.attach(sprite)
				await _run(3.0)
			"attach() — cyan speed":
				Trail.attach(sprite, {"color": Color(0.4, 0.85, 1.0, 0.6), "interval": 0.025})
				await _run(3.0)
			"dash() — burst":
				for n in 4:
					Trail.dash(sprite, 8, {"color": Color(1.0, 0.8, 0.4, 0.7)})
					await _pause(0.7)
			"attach() — shrinking ghosts":
				Trail.attach(sprite, {"scale_end": 0.4, "lifetime": 0.5, "color": Color(0.9, 0.5, 1.0, 0.6)})
				await _run(3.0)
		Trail.detach(sprite)
		await _pause(0.5)
		_i += 1


func _run(seconds: float) -> void:
	# figure-8 motion so the trail is always visible
	var t := 0.0
	var cx := 640.0
	var cy := 360.0
	while t < seconds and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()
		sprite.position = Vector2(
			cx + sin(t * 2.4) * 340.0,
			cy + sin(t * 4.8) * 170.0)
	_skip = false
	sprite.position = Vector2(cx, cy)


func _pause(seconds: float) -> void:
	var t := 0.0
	while t < seconds and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()
	_skip = false


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_skip = true
