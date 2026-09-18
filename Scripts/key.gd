extends Area3D

## A key dropped by a defeated enemy. When the player walks over it, the key is
## added to the player's key ring and the pickup disappears. The matching locked
## door can then be opened. Its collision mask only includes the player (layer 2).

@export var key_id: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(delta * 2.5)   # slow spin so it reads as a collectible


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("add_key"):
		body.add_key(key_id)
		queue_free()
