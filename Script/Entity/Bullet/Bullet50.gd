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
	$Effect.restart()
	if type == 1:
		dmg = dmg * 1.5
func _physics_process(_delta):
	if sup:
		modulate = Color8(1,1,1,20)
	else:
		modulate = Color8(255,255,255,255)
	if $Cast.is_colliding():
		dmg -= 20
	if dmg > 0:
		dmg -= 0.1
	else:
		$Collision.disabled = true
		freeze = true
		var tween = create_tween()
		tween.tween_property($Trail, "modulate", Color(1,1,1,0), 1)
		tween.play()
		tween.tween_callback(queue_free)
func _on_body_entered(_body):
	if !_body.is_in_group("fire") and !(_body.is_in_group("Conqueror") and _body.id == id):
		var ins
		match type:
			2: 
				ins = fire.instantiate()
				ins.dmg = 2.0
				ins.time = 60
				ins.id = id
				dmg = 0
			3:
				ins = boom.instantiate()
				ins.dmg = dmg
				ins.id = id
				dmg = 0
			_: 
				ins = hit.instantiate()
				ins.position = Vector2(-speed/50,0)
		add_child(ins)
		ins.reparent(get_tree().get_root())
	
