extends Area3D

## Thing an enemy throws. Flies in a straight line, damages the player on contact,
## and despawns after a short life. Its collision mask only includes the player
## layer, so it never reacts to walls or to other enemies.

var _velocity := Vector3.ZERO
var damage := 8
var _life := 4.0


func setup(dir: Vector3, speed: float, dmg: int) -> void:
	_velocity = dir * speed
	damage = dmg


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
