extends RigidBody2D
var time = 400
var trigged = false
var count = 0
@onready var level = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
func _process(_delta):
	if trigged:
		$NadeTrigger.hide()
	if count > 120:
		contact_monitor = false
		await get_tree().create_timer(1).timeout
		queue_free()
	if $Delay.time_left > 0:
		$AnimationPlayer.play("fire")
	else:
		$AnimationPlayer.play("idle")
func _on_body_entered(_body):
	if !trigged:
		trigged = true
		var ins = level.instantiate()
		ins.position = global_position
		ins.apply_impulse(Vector2(0,-500).rotated(global_rotation), Vector2())
		get_tree().get_root().call_deferred("add_child",ins)
	if !$Delay.time_left > 0:
		$Fire.play()
		$Delay.start(0.05)
		$Flash.restart()
		$Flash/Flash2.restart()
		$Gas.restart()
	apply_impulse(Vector2(0,randi_range(-500,-100)).rotated(global_rotation),Vector2())
	count += 1
	
