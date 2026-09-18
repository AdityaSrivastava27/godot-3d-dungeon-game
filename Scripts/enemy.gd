extends CharacterBody3D

## Melee + ranged enemy. Chases the player when within aggro range, hits them at
## close range, and throws projectiles from mid range. Returns to its home spot
## when the player leaves. Flashes when hit and glows when the player targets it.

@export var max_health := 40
@export var move_speed := 3.0
@export var aggro_range := 17.0
@export var melee_range := 2.2
@export var melee_damage := 10
@export var melee_cooldown := 1.0
@export var throw_range := 15.0
@export var throw_min_range := 3.5
@export var throw_cooldown := 2.2
@export var projectile_speed := 13.0
@export var projectile_damage := 8
@export var projectile_scene: PackedScene

var health := 0
var _home := Vector3.ZERO
var _player: Node3D = null
var _melee_cd := 0.0
var _throw_cd := 0.0
var _flash := 0.0
var _targeted := false
var _mat: StandardMaterial3D = null


func _ready() -> void:
	health = max_health
	_home = global_position
	_player = get_tree().get_first_node_in_group("player")
	# Give each enemy its own material copy so flashing/targeting is per-enemy.
	if has_node("Body"):
		var b: MeshInstance3D = $Body
		if b.material_override != null:
			_mat = b.material_override.duplicate()
			b.material_override = _mat


func set_targeted(v: bool) -> void:
	_targeted = v


func take_damage(amount: int) -> void:
	health -= amount
	_flash = 0.14
	if health <= 0:
		die()


func die() -> void:
	queue_free()


func _throw() -> void:
	if projectile_scene == null or _player == null:
		return
	var proj := projectile_scene.instantiate()
	var muzzle := global_position + Vector3(0, 1.3, 0)
	var target := _player.global_position + Vector3(0, 1.0, 0)
	var dir := (target - muzzle).normalized()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle
	if proj.has_method("setup"):
		proj.setup(dir, projectile_speed, projectile_damage)


func _update_material() -> void:
	if _mat == null:
		return
	if _flash > 0.0:
		_mat.emission_enabled = true
		_mat.emission = Color(1, 1, 1)
		_mat.emission_energy_multiplier = 2.5
	elif _targeted:
		_mat.emission_enabled = true
		_mat.emission = Color(1.0, 0.85, 0.2)
		_mat.emission_energy_multiplier = 1.6
	else:
		_mat.emission_enabled = false


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity += get_gravity() * delta

	if _melee_cd > 0.0:
		_melee_cd -= delta
	if _throw_cd > 0.0:
		_throw_cd -= delta
	if _flash > 0.0:
		_flash -= delta
	_update_material()

	var planar := Vector3.ZERO
	var moving := false

	if _player != null and is_instance_valid(_player):
		var to_p: Vector3 = _player.global_position - global_position
		var dist := to_p.length()
		var flat := Vector3(to_p.x, 0, to_p.z)

		if dist <= aggro_range:
			if flat.length() > 0.05:
				rotation.y = atan2(flat.x, flat.z)
			if dist > melee_range and flat.length() > 0.05:
				planar = flat.normalized() * move_speed
				moving = true
			if dist <= melee_range and _melee_cd <= 0.0:
				if _player.has_method("take_damage"):
					_player.take_damage(melee_damage)
				_melee_cd = melee_cooldown
			if dist <= throw_range and dist >= throw_min_range and _throw_cd <= 0.0:
				_throw()
				_throw_cd = throw_cooldown
		else:
			var to_home: Vector3 = _home - global_position
			to_home.y = 0.0
			if to_home.length() > 1.0:
				planar = to_home.normalized() * move_speed
				moving = true

	if moving:
		velocity.x = planar.x
		velocity.z = planar.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()
