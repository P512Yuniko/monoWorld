extends Node2D

var bright_count = 0
var cont_count = 0
var loading = false
var progress = []
var screen : String = "res://Screen/Debugging/test.tscn"
func _process(delta):
	$Camera2D.position.x = 940 + get_global_mouse_position().x/48
	$Camera2D.position.y = 520 + get_global_mouse_position().y/27
	if bright_count > 0:
		bright_count -= 1
		if bright_count < 60 and !$Timer.time_left > 0:
			$WorldEnvironment.environment.adjustment_brightness = lerpf($WorldEnvironment.environment.adjustment_brightness,randf_range(1,1.2),0.05)
		else:
			$WorldEnvironment.environment.adjustment_brightness = lerpf($WorldEnvironment.environment.adjustment_brightness,1,0.05)
	else:
		bright_count = randi_range(60,120)
	if cont_count > 0:
		cont_count -= 1
		if cont_count < 60 and !$Timer.time_left > 0:
			$WorldEnvironment.environment.adjustment_contrast = lerpf($WorldEnvironment.environment.adjustment_contrast,randf_range(1,1.2),0.05)
		else:
			$WorldEnvironment.environment.adjustment_contrast = lerpf($WorldEnvironment.environment.adjustment_contrast,1,0.05)
	else:
		cont_count = randi_range(60,120)
	if $Control/VBoxContainer/Deploy.is_hovered() and !loading:
		$Control/VBoxContainer/Deploy.modulate.a = 1
		$Control/VBoxContainer/Deploy/Sprite2D.frame = 1
	elif loading:
		$Control/VBoxContainer/Deploy.modulate.a = 0.7
		$Control/VBoxContainer/Deploy/Sprite2D.frame = 1
	else:
		$Control/VBoxContainer/Deploy.modulate.a = 0.44
		$Control/VBoxContainer/Deploy/Sprite2D.frame = 0
	if $Control/VBoxContainer/Deploy.button_pressed and !loading:
		ResourceLoader.load_threaded_request(screen)
		loading = true
	if loading and !$Timer.time_left > 0:
		$AnimationPlayer.play("Load")
		if ResourceLoader.load_threaded_get_status(screen,progress) == ResourceLoader.THREAD_LOAD_LOADED and !$Timer.time_left > 0:
			$Timer.start(1.5)
	elif $Timer.time_left > 0:
		$AnimationPlayer.play("Start")
	else:
		$AnimationPlayer.play("Idle")
func _on_timer_timeout():
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(screen))
