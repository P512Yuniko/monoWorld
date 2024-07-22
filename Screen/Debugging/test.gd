extends Node2D

@onready var noicom = preload("res://Screen/Asset/Entity/Monster/Ngu/Ngu_1.tscn")
@onready var binhnuoc = preload("res://Screen/Asset/Entity/Monster/Ngu/Ngu_2.tscn")
@onready var banhmi = preload("res://Screen/Asset/Entity/Monster/Ngu/Ngu_3.tscn")
@onready var lovisong= preload("res://Screen/Asset/Entity/Monster/Ngu/Ngu_4.tscn")
var delay
var spawn = Vector2()
var open = false
func _physics_process(_delta):
	if $Door.open:
		fight()
func fight():
	var state = randi_range(1,4)
	spawn.x = randi_range($Spawn1.global_position.x,$Spawn2.global_position.x)
	spawn.y = $Spawn1.global_position.y
	if !delay:
		if state == 1:
			var ins1 = noicom.instantiate()
			ins1.position = spawn
			get_tree().get_root().add_child(ins1)
		elif state == 2:
			var ins2 = binhnuoc.instantiate()
			ins2.position = spawn
			get_tree().get_root().add_child(ins2)
		elif state == 3:
			var ins3 = banhmi.instantiate()
			ins3.position = spawn
			get_tree().get_root().add_child(ins3)
		else:
			var ins4 = lovisong.instantiate()
			ins4.position = spawn
			get_tree().get_root().add_child(ins4)
		delay = true
		await get_tree().create_timer(5).timeout
		delay = false

