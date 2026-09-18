extends Area3D

## A world pickup that drops an item into the player's inventory, then disappears.
## Configure it per instance (a health potion by default). Collision mask only
## includes the player (layer 2).

@export var item_id := "health_potion"
@export var item_name := "Health Potion"
@export var item_type := "health"     # "health" | "key" | "misc"
@export var heal_amount := 40
@export var amount := 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(delta * 2.0)   # gentle spin so it reads as a collectible


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("add_item"):
		body.add_item(item_id, item_name, item_type, amount, heal_amount)
		queue_free()
