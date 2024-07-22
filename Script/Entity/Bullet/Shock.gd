extends RigidBody2D

func _ready():
	$Particles.restart()
	$Particles2.restart()
	$Collision.scale = Vector2(0,0)
	$AnimationPlayer.play("Process")
	$Timer.start(1)

func _on_timer_timeout():
	queue_free()
