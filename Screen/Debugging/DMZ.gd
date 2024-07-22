extends Node2D
var bright_count = 0
var cont_count = 0
func _ready():
	$Player/Weapon/Camera2D.limit_bottom = 256
	$Player/Weapon/Camera2D.reset_smoothing()
func _process(delta):
	if bright_count > 0:
		bright_count -= 1
		if bright_count < 300:
			$WorldEnvironment.environment.adjustment_brightness = lerpf($WorldEnvironment.environment.adjustment_brightness,randf_range(0.6,1.2),0.05)
		else:
			$WorldEnvironment.environment.adjustment_brightness = lerpf($WorldEnvironment.environment.adjustment_brightness,0.8,0.05)
	else:
		bright_count = randi_range(300,600)
	if cont_count > 0:
		cont_count -= 1
		if cont_count < 300:
			$WorldEnvironment.environment.adjustment_contrast = lerpf($WorldEnvironment.environment.adjustment_contrast,randf_range(1,1.2),0.05)
		else:
			$WorldEnvironment.environment.adjustment_contrast = lerpf($WorldEnvironment.environment.adjustment_contrast,1.1,0.05)
	else:
		cont_count = randi_range(300,600)
