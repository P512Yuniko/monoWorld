extends Node2D
@onready var blade = preload("res://Screen/Asset/Entity/Bullet/Blade/Cblade.tscn")
@onready var blade2 = preload("res://Screen/Asset/Entity/Bullet/Blade/Cblade2.tscn")
@onready var blade3 = preload("res://Screen/Asset/Entity/Bullet/Blade/BBlade.tscn")
@onready var wave = preload("res://Screen/Asset/Entity/Bullet/Blade/BreakWave.tscn")
@onready var strike = preload("res://Screen/Asset/Entity/Bullet/Blade/Punch.tscn")
@onready var blade6 = preload("res://Screen/Asset/Entity/Bullet/Blade/CbladeThrust.tscn")
@onready var blade7 = preload("res://Screen/Asset/Entity/Bullet/Blade/CbladeRotate.tscn")
@onready var kick = preload("res://Screen/Asset/Entity/Effect/Kick.tscn")
@onready var hawk = preload("res://Screen/Asset/Entity/Bullet/Blade/Spear.tscn")
@onready var clone = preload("res://Screen/Asset/Entity/Bullet/Blade/sprite_r.tscn")
@onready var clone2 = preload("res://Screen/Asset/Entity/Bullet/Blade/sprite_l.tscn")
@onready var portal = preload("res://Screen/Asset/Entity/Bullet/Blade/Portal.tscn")
@onready var domain = preload("res://Screen/Asset/Entity/Bullet/Blade/BreakHack.tscn")
var rotate = 0
var charge = 0.0
var dmg = 50.0
var corruptor = false
func _process(_delta):
	if scale.x == 1:
		rotate = 0
	else:
		rotate = 180
func slash():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.up = false
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_1")
	add_child(ins)
func slash2():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.up = false
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_2")
	add_child(ins)
func slash3():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.up = false
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_2")
	add_child(ins)
func moon():
	var ins = blade7.instantiate()
	ins.global_position = $CBlade.global_position
	ins.rotation = $CBlade.global_rotation
	ins.facing = scale.x
	ins.angular_velocity = -100 * scale.x
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(6000 * scale.x, 0).rotated(0), Vector2())
	get_tree().get_root().add_child(ins)
func break_l():
	var ins = blade3.instantiate()
	ins.position = global_position
	ins.angular_velocity = -30 * scale.x
	ins.dmg = dmg * 4
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(0, 0).rotated(0), Vector2())
	get_tree().get_root().add_child(ins)
func dance1():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_3")
	add_child(ins)
func dance2():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_4")
	add_child(ins)
func dance3():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_5")
	add_child(ins)
func xoay1():
	var ins = blade2.instantiate()
	ins.global_position = $CBlade.global_position
	ins.rotation_degrees = $CBlade.global_rotation_degrees + rotate
	ins.angular_velocity = -160 * scale.x
	ins.facing = scale.x
	ins.dmg = dmg/2
	ins.back = true
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(3000 * scale.x, 1000).rotated(0), Vector2())
	get_tree().get_root().add_child(ins)
func xien1():
	var ins = blade6.instantiate()
	ins.global_position = $CBlade.global_position
	ins.rotation_degrees = $CBlade.global_rotation_degrees + rotate
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(0,-8000 * scale.x).rotated($CBlade.global_rotation), Vector2())
	get_tree().get_root().add_child(ins)
	var ins2 = kick.instantiate()
	ins2.global_position = $CBlade.global_position
	ins2.rotation_degrees = $CBlade.global_rotation_degrees + rotate
	get_tree().get_root().add_child(ins2)
func xien2():
	var ins = blade6.instantiate()
	ins.global_position = $CBlade2.global_position
	ins.rotation_degrees = $CBlade2.global_rotation_degrees + rotate
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(0,-8000 * scale.x).rotated($CBlade2.global_rotation), Vector2())
	get_tree().get_root().add_child(ins)
	var ins2 = kick.instantiate()
	ins2.global_position = $CBlade2.global_position
	ins2.rotation_degrees = $CBlade2.global_rotation_degrees + rotate
	get_tree().get_root().add_child(ins2)
func ground():
	var ins = blade.instantiate()
	ins.get_node("Ani").play("Off")
	ins.global_position.x = $LegL.global_position.x
	ins.global_position.y = $LegL.global_position.y - 200
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(0, 2000).rotated(0), Vector2())
	get_tree().get_root().add_child(ins)
	var ins2 = kick.instantiate()
	ins2.global_position = $LegL.global_position
	ins2.rotation_degrees = $LegL.global_rotation_degrees + rotate
	get_tree().get_root().add_child(ins2)
func kickup():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_8")
	ins.up = true
	ins.up_speed = 800
	ins.knock_back = 4000 * scale.x
	ins.set_collision_layer_value(5,true)
	add_child(ins)
func spear():
	var ins = hawk.instantiate()
	ins.global_position = $HSpear.global_position
	ins.global_rotation = get_parent().spear_rotate
	ins.dmg = dmg * 2
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(8000, 0).rotated(get_parent().spear_rotate), Vector2())
	get_tree().get_root().add_child(ins)
func slash4():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_1")
	add_child(ins)
func slash5():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_2")
	add_child(ins)
func slash6():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_3")
	add_child(ins)
func slash7():
	var ins = blade3.instantiate()
	ins.dmg = dmg * 2
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_4")
	add_child(ins)
func evade1():
	var ins
	if scale.x == 1:
		ins = clone.instantiate()
	else:
		ins = clone2.instantiate()
	ins.position = global_position
	ins.id = get_parent().id
	ins.get_node("Ani").play("Slash1")
	get_tree().get_root().add_child(ins)
func evade2():
	var ins
	if scale.x == 1:
		ins = clone.instantiate()
	else:
		ins = clone2.instantiate()
	ins.position = global_position
	ins.id = get_parent().id
	ins.get_node("Ani").play("Slash2")
	get_tree().get_root().add_child(ins)
func evade3():
	var ins
	if scale.x == 1:
		ins = clone.instantiate()
	else:
		ins = clone2.instantiate()
	ins.position = global_position
	ins.get_node("Ani").play("Slash3")
	ins.id = get_parent().id
	get_tree().get_root().add_child(ins)
func evade4():
	var ins
	if scale.x == 1:
		ins = clone.instantiate()
	else:
		ins = clone2.instantiate()
	ins.position = global_position
	ins.get_node("Ani").play("Slash4")
	ins.id = get_parent().id
	get_tree().get_root().add_child(ins)
func evade5():
	var ins
	if scale.x == 1:
		ins = clone.instantiate()
	else:
		ins = clone2.instantiate()
	ins.position = global_position
	ins.id = get_parent().id
	ins.get_node("Ani").play("Slash5")
	get_tree().get_root().add_child(ins)
func up():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.up = true
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_6")
	add_child(ins)
func up2():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.up = true
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_7")
	add_child(ins)
func riptide():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_5")
	add_child(ins)
	var ins1 = portal.instantiate()
	ins1.position = global_position
	ins1.facing = scale.x
	get_tree().get_root().add_child(ins1)
func slash8():
	var ins = blade3.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_6")
	add_child(ins)
func moon_break():
	var ins = wave.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.apply_impulse(Vector2(5000 * scale.x, 0).rotated(0), Vector2())
	add_child(ins)
func punch():
	var ins = strike.instantiate()
	ins.dmg = dmg * 12
	ins.scale.x = scale.x
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.apply_impulse(Vector2(5000 * scale.x, 0).rotated(0), Vector2())
	ins.position = global_position
	get_tree().get_root().add_child(ins)
func slash9():
	var ins = blade.instantiate()
	ins.dmg = dmg
	ins.id = get_parent().id
	ins.corruptor = corruptor
	ins.get_node("Ani").play("Slash_7")
	add_child(ins)
	var ins1 = blade2.instantiate()
	ins1.global_position = global_position
	ins1.angular_velocity = -160 * scale.x
	ins1.facing = scale.x
	ins1.dmg = dmg/2
	ins1.back = false
	ins1.id = get_parent().id
	ins1.apply_impulse(Vector2(3000 * scale.x,0).rotated(0), Vector2())
	get_tree().get_root().add_child(ins1)
func slash10():
	for i in Operator.taken_prism:
		var ins = domain.instantiate()
		if i < $Target2.get_collision_count():
			ins.position = $Target2.get_collision_point(i)
		else:
			ins.position = global_position + Vector2(randi_range(-500,500),randi_range(-500,500))
		ins.dmg = dmg
		ins.id = get_parent().id
		ins.time = (1 + i) * 0.2/Operator.taken_prism
		ins.rotation = i + randf_range(-1,1)
		get_tree().get_root().add_child(ins)
	Operator.taken_prism = 0
	Operator.prism = 0
