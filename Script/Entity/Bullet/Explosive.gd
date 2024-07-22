extends RigidBody2D
var time = 180
var dmg = 0.0
var power = 0.0
@export var dmg_range = 0
var id = 0
func _ready():
	linear_velocity.y = -16000
	power = dmg
	if dmg > 100:
		Operator.emit_signal("shake")
	$Audio.volume_db = (dmg - 240)/10
	$Audio.play()
	$ShockWave.modulate.a = dmg/200
	$PointLight2D.scale = Vector2(1,1)
	$Collision.scale = Vector2(0,0)
	$Area2D/Collision.scale = Vector2(0,0)
	$Particles.amount = dmg
	$Particles2.amount = dmg * 2
	$Particles.scale_amount_max = dmg/500
	$Particles2.scale_amount_max = dmg/20
	$Particles.initial_velocity_max = dmg * 10
	$Particles2.initial_velocity_max = dmg * 10
	$Particles3.initial_velocity_max = dmg * 10
	$Particles3.gravity.y = dmg * 2
	$Particles.restart()
	$Particles2.restart()
	$Particles3.restart()
func _physics_process(_delta):
	$Collision.scale = Vector2(dmg_range * power/20,dmg_range * power/20)
	$Area2D/Collision.scale = $Collision.scale
	$Effect.scale = Vector2(0.01 * power,0.01 * power)
	$ShockWave.scale = Vector2(0.05 * power,0.05 * power)
	if time > 0:
		time -= 1
		dmg = move_toward(dmg,0,2)
	else:
		queue_free()
	if dmg < 0:
		dmg = 0
	$PointLight2D.scale.x = lerpf($PointLight2D.scale.x,0,0.5)
	$PointLight2D.scale.y = $PointLight2D.scale.x
	$AnimationPlayer.play("Process")
