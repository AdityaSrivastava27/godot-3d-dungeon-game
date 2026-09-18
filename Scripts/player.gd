extends CharacterBody3D


const SPEED = 5.0
const ROTATION_SPEED = 10.0
const JUMP_VELOCITY = 4.5

# --- Combat tuning ---
const MAX_HEALTH := 100
const ATTACK_DAMAGE := 25
const ATTACK_RANGE := 2.8       # how far the melee swing reaches
const ATTACK_ARC := 0.2         # min dot(forward, dir_to_enemy) to be "in front"
const ATTACK_COOLDOWN := 0.45
const HURT_COOLDOWN := 0.35     # brief i-frames so several enemies can't insta-kill

var health := MAX_HEALTH
var max_health := MAX_HEALTH

var _attack_cd := 0.0
var _hurt_cd := 0.0
var _spawn_transform: Transform3D
var _hud: Node = null
var _target: Node3D = null      # enemy currently locked for the next swing

# --- Inventory ---
# Each entry is a dictionary: {id, name, type, count, heal}
#   type "health" -> usable, restores `heal` HP
#   type "key"    -> passive, opens the matching locked door
# The player can select a slot (1-5), use it (E) or drop/remove one (Q).
var _inventory: Array = []
var _sel := 0


func _ready() -> void:
	_spawn_transform = global_transform
	_hud = get_tree().get_first_node_in_group("hud")


# Called by enemies (melee) and by enemy projectiles.
func take_damage(amount: int) -> void:
	if _hurt_cd > 0.0:
		return
	health -= amount
	_hurt_cd = HURT_COOLDOWN
	if health <= 0:
		health = 0
		die()


func die() -> void:
	# Respawn at the starting area with full health.
	health = max_health
	velocity = Vector3.ZERO
	global_transform = _spawn_transform
	if _hud == null:
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_death"):
		_hud.show_death()


# ---------------------------------------------------------------- Inventory ---

func _pretty_id(id: String) -> String:
	var words := id.replace("_", " ").split(" ")
	var out := ""
	for w in words:
		if w != "":
			out += w.substr(0, 1).to_upper() + w.substr(1) + " "
	return out.strip_edges()


# Generic pickup entry point. `count` items of the given id are added, stacking
# onto an existing slot of the same id.
func add_item(id: String, item_name := "", type := "misc", count := 1, heal := 0) -> void:
	if id == "" or count <= 0:
		return
	if item_name == "":
		item_name = _pretty_id(id)
	for it in _inventory:
		if it.id == id:
			it.count += count
			return
	_inventory.append({"id": id, "name": item_name, "type": type, "count": count, "heal": heal})


func remove_item(id: String, count := 1) -> void:
	for i in range(_inventory.size()):
		if _inventory[i].id == id:
			_inventory[i].count -= count
			if _inventory[i].count <= 0:
				_inventory.remove_at(i)
			_clamp_sel()
			return


func has_item(id: String) -> bool:
	for it in _inventory:
		if it.id == id and it.count > 0:
			return true
	return false


func get_inventory() -> Array:
	return _inventory


func get_selected_index() -> int:
	return _sel


func _clamp_sel() -> void:
	if _inventory.is_empty():
		_sel = 0
	else:
		_sel = clampi(_sel, 0, _inventory.size() - 1)


func _use_index(i: int) -> void:
	if i < 0 or i >= _inventory.size():
		return
	var it: Dictionary = _inventory[i]
	match it.type:
		"health":
			if health < max_health:
				health = mini(max_health, health + int(it.heal))
				_consume(i)
		_:
			# Keys and misc items aren't consumed by "use" (keys work at doors).
			pass


func _consume(i: int) -> void:
	_inventory[i].count -= 1
	if _inventory[i].count <= 0:
		_inventory.remove_at(i)
	_clamp_sel()


func _use_selected() -> void:
	_use_index(_sel)


# Drop / remove one of the selected item.
func _drop_selected() -> void:
	if _sel < 0 or _sel >= _inventory.size():
		return
	_consume(_sel)


# --------------------------------------------------------------------- Keys ---
# Keys are just inventory items of type "key"; doors call has_key().

func add_key(id: String) -> void:
	if id == "":
		return
	add_item(id, _pretty_id(id), "key", 1)


func has_key(id: String) -> bool:
	return has_item(id)


func get_key_ids() -> Array:
	var ids: Array = []
	for it in _inventory:
		if it.type == "key" and it.count > 0:
			ids.append(it.id)
	return ids


# -------------------------------------------------------------------- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				_sel = event.keycode - KEY_1
				_clamp_sel()
			KEY_E:
				_use_selected()
			KEY_Q:
				_drop_selected()


# ------------------------------------------------------------------- Combat ---

# Pick the nearest enemy inside the swing range and roughly in front, and
# highlight it so the player can see what they will hit (targeting).
func _update_target() -> void:
	var forward := global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	forward = forward.normalized()

	var best: Node3D = null
	var best_dist := ATTACK_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector3 = e.global_position - global_position
		to_e.y = 0.0
		var d := to_e.length()
		if d > best_dist or d < 0.01:
			continue
		if forward.dot(to_e / d) < ATTACK_ARC:
			continue
		best = e
		best_dist = d

	if best != _target:
		if _target != null and is_instance_valid(_target) and _target.has_method("set_targeted"):
			_target.set_targeted(false)
		_target = best
		if _target != null and _target.has_method("set_targeted"):
			_target.set_targeted(true)


func _attack() -> void:
	_attack_cd = ATTACK_COOLDOWN
	_swing()
	if _target != null and is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(ATTACK_DAMAGE)


func _swing() -> void:
	if not has_node("Sword"):
		return
	var s: Node3D = $Sword
	var t := create_tween()
	t.tween_property(s, "rotation:x", -1.4, 0.08)
	t.tween_property(s, "rotation:x", 0.0, 0.16)


func _physics_process(delta: float) -> void:
	if _hurt_cd > 0.0:
		_hurt_cd -= delta
	if _attack_cd > 0.0:
		_attack_cd -= delta

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction.
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	# Get the camera.
	var camera: Camera3D = $CameraPivot/Camera3D

	# Get the camera's forward and right directions.
	var forward: Vector3 = camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x

	# Ignore the camera's vertical direction.
	forward.y = 0
	right.y = 0

	# Normalize the directions.
	forward = forward.normalized()
	right = right.normalized()

	# Calculate movement direction relative to the camera.
	var direction: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# --- Combat ---
	_update_target()
	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_attack()
