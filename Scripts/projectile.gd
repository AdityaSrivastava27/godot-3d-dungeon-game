extends Area3D

## Thing an enemy throws. Each frame it raycasts along its travel segment so it
## is stopped by whatever it meets first: dungeon walls/floors/ceilings (physics
## layer 1) block it, and the player (layer 2) takes damage. Enemies (layer 3)
## are excluded, so a fireball never hits the thrower or passes friendly fire —
## and, crucially, it can no longer travel through walls to hit the player.

const WORLD_LAYER := 1
const PLAYER_LAYER := 2

var _velocity := Vector3.ZERO
var damage := 8
var _life := 4.0


func setup(dir: Vector3, speed: float, dmg: int) -> void:
	_velocity = dir * speed
	damage = dmg


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return

	var from := global_position
	var to := from + _velocity * delta

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = WORLD_LAYER | PLAYER_LAYER
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)

	if hit:
		var collider = hit.get("collider")
		if collider != null and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage)
		# Hit a wall or the player: the fireball is spent either way.
		queue_free()
		return

	global_position = to
