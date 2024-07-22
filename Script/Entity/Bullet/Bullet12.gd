extends RigidBody2D
var dmg = 0.0
var sup = false
var type = 0
var speed = 0.0
var id = 0
@onready var hit = preload("res://Screen/Asset/Entity/Effect/Hit.tscn")
@onready var fire = preload("res://Screen/Asset/Entity/Bullet/Fire.tscn")
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func _ready():
	$Fire.visible = (type == 2)
func _physics_process(_delta):
	if sup:
		modulate = Color8(1,1,1,20)
	else:
		modulate = Color8(255,255,255,255)
	if $Cast.is_colliding():
		if type == 1:
			dmg -= 20
		else:
			dmg -= 40
	if dmg > 0:
		linear_damp += 0.1
		dmg -= 0.2
	else:
		freeze = true
		$Collision.disabled = true
		if $Cast.is_colliding():
			linear_damp = 25
		else:
			linear_damp = 10
		var tween = create_tween()
		tween.tween_property($Trail, "modulate", Color(1,1,1,0), 0.5)
		tween.play()
		tween.tween_callback(queue_free)
func _on_body_entered(_body):
	if !_body.is_in_group("fire") and !(_body.is_in_group("Conqueror") and _body.id == id):
		var ins
		match type:
			0: ins = hit.instantiate()
			1: ins = hit.instantiate()
			2: 
				ins = fire.instantiate()
				ins.dmg = 1.0
				ins.time = 30
				dmg = 0
			3:
				ins = boom.instantiate()
				ins.dmg = dmg
				dmg = 0
		ins.position = Vector2(-speed/50,0)
		add_child(ins)
		ins.reparent(get_tree().get_root())
