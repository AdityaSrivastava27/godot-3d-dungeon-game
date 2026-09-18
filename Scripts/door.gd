extends Node3D

## Auto-swinging door. The leaf is a child of this hinge node; the hinge is placed
## at the door's edge so rotating it about Y swings the leaf open.
##
## If required_key is set, the door is LOCKED: it only opens when the player is
## near AND holds that key (dropped by the enemy guarding the way). With no
## required_key it behaves as a normal proximity door. Set open_angle negative in
## the scene to swing the other way.

@export var open_angle: float = 95.0
@export var open_distance: float = 3.5
@export var speed: float = 5.0
@export var required_key: String = ""   # blank = unlocked; otherwise needs this key

var _closed_y: float = 0.0
var _player: Node3D = null
var _hud: Node = null


func _ready() -> void:
	_closed_y = rotation.y
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().get_first_node_in_group("hud")


func _process(delta: float) -> void:
	var want_open := false

	if _player != null and global_position.distance_to(_player.global_position) < open_distance:
		if required_key == "":
			want_open = true
		elif _player.has_method("has_key") and _player.has_key(required_key):
			want_open = true
		else:
			# Player is at a locked door without the key: keep it shut and hint.
			if _hud == null:
				_hud = get_tree().get_first_node_in_group("hud")
			if _hud and _hud.has_method("notify_locked"):
				_hud.notify_locked(required_key)

	var target := _closed_y + deg_to_rad(open_angle) if want_open else _closed_y
	rotation.y = lerp_angle(rotation.y, target, speed * delta)
