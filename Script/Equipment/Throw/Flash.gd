extends RigidBody2D

var type = 0
var time = 150
var trigged = false
var count = 0
@onready var flash = preload("res://Screen/Asset/Entity/Bullet/Flash.tscn")
@onready var level = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")

func _ready():
	$Light.scale = Vector2(0,0)
func _on_body_entered(_body):
	if !trigged:
		$Delay.start(1)
		var ins = level.instantiate()
		ins.position = global_position
		ins.apply_impulse(Vector2(0,-500).rotated(global_rotation), Vector2())
		get_tree().get_root().call_deferred("add_child",ins)
		trigged = true

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property($Light, "scale", Vector2(0,0), 0.2)
	tween.chain().tween_property(self, "modulate", Color(1,1,1,0), 1)
	tween.play()
	tween.tween_callback(queue_free)

func _on_delay_timeout():
	Operator.emit_signal("shake")
	$Audio.play()
	$Particles.restart()
	$Timer.start(1)
	$Light.scale = Vector2(20,20)
	for i in 6:
		var bullet_ins = flash.instantiate()
		bullet_ins.apply_impulse(Vector2(200, 0).rotated(i), Vector2())
		$Sprite2D.add_child(bullet_ins)
		var tween = create_tween()
		tween.tween_property(bullet_ins.get_node("Collision"), "scale", Vector2(100,100), 0.2)
		tween.play()
	await get_tree().create_timer(0.2).timeout
	for i in $Sprite2D.get_children():
		i.remove_from_group("flash")
