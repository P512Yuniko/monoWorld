extends RigidBody2D
var dmg = 0.0
var life = 60
var trigger = false
var id = 0
@onready var hit = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func _process(_delta):
	$Collision.disabled = trigger
	freeze = trigger
	if trigger:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 1)
		tween.play()
		if life > 0:
			life -= 1
		else:
			queue_free()
	$Fly.autoplay = true
func _on_body_entered(_body):
	if !trigger and !(_body.is_in_group("Conqueror") and _body.id == id):
		var ins = hit.instantiate()
		ins.dmg = 180
		ins.global_position = global_position
		ins.rotation = global_rotation
		ins.id = id
		get_tree().get_root().add_child(ins)
		trigger = !trigger
