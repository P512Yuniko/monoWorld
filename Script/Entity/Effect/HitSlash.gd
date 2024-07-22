extends GPUParticles2D

@export var time = 0.0
func _ready():
	restart()
	await get_tree().create_timer(time).timeout
	queue_free()

