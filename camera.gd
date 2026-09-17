extends Node3D


@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -45.0
@export var max_pitch: float = 45.0


@onready var player: CharacterBody3D = get_parent()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	global_position = player.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		var new_pitch: float = rotation.x - event.relative.y * mouse_sensitivity

		new_pitch = clamp(
			new_pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

		rotation.x = new_pitch
