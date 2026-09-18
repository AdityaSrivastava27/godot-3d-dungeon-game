extends CanvasLayer

## Reads the player's health, key ring and the live enemy count each frame and
## updates the on-screen bar/labels. show_death() flashes the death overlay on
## respawn; notify_locked() briefly shows a "locked door" hint.

var _lock_timer := 0.0


func notify_locked() -> void:
	_lock_timer = 0.25


func _process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player")
	var fill := get_node_or_null("Root/HealthBg/HealthFill") as ColorRect
	var hp_label := get_node_or_null("Root/HPLabel") as Label
	var enemy_label := get_node_or_null("Root/EnemyLabel") as Label
	var key_label := get_node_or_null("Root/KeyLabel") as Label
	var lock_label := get_node_or_null("Root/LockLabel") as Label

	if p != null and fill != null:
		var mh: float = float(p.max_health) if "max_health" in p else 100.0
		var h: float = float(p.health) if "health" in p else mh
		if mh <= 0.0:
			mh = 1.0
		var r: float = clampf(h / mh, 0.0, 1.0)
		fill.scale.x = r
		fill.color = Color(0.85, 0.2, 0.2).lerp(Color(0.2, 0.8, 0.3), r)
		if hp_label != null:
			hp_label.text = "HP  %d / %d" % [int(max(h, 0.0)), int(mh)]

	if enemy_label != null:
		var n := get_tree().get_nodes_in_group("enemies").size()
		enemy_label.text = ("Enemies left: %d" % n) if n > 0 else "Dungeon cleared!"

	if key_label != null:
		var ids: Array = []
		if p != null and p.has_method("get_key_ids"):
			ids = p.get_key_ids()
		key_label.text = "Keys: %s" % (", ".join(ids) if ids.size() > 0 else "none")

	if lock_label != null:
		_lock_timer = maxf(0.0, _lock_timer - delta)
		lock_label.visible = _lock_timer > 0.0


func show_death() -> void:
	var dp := get_node_or_null("Root/DeathPanel") as Control
	if dp == null:
		return
	dp.visible = true
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(dp):
		dp.visible = false
