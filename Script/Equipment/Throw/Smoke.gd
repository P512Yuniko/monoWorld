extends RigidBody2D
var count = 0
@onready var smoke = preload("res://Screen/Asset/Entity/Bullet/Smoke.tscn")
@onready var level = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
func _on_body_entered(_body):
	$NadeTrigger.hide()
	$Smoke.start(0.01)
	if !$Timer.time_left > 0:
		$Timer.start(11)
		var ins = level.instantiate()
		ins.position = global_position
		ins.apply_impulse(Vector2(0,-500).rotated(global_rotation), Vector2())
		get_tree().get_root().call_deferred("add_child",ins)

func _on_smoke_timeout():
	if $Timer.time_left > 9 and $Timer.time_left < 10:
		for i in 4:
			var ins = smoke.instantiate()
			ins.position = Vector2(randf_range(-1,1),randf_range(-1,1))
			$Sprite2D.call_deferred("add_child",ins)

func _on_timer_timeout():
	for i in $Sprite2D.get_children():
		var tween = create_tween()
		tween.tween_property(i, "modulate", Color(1,1,1,0),randf_range(0.1,1))
		tween.play()
		tween.tween_callback(i.queue_free)
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color(1,1,1,0),2)
	tween2.play()
	tween2.tween_callback(queue_free)
		
