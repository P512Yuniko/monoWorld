extends CharacterBody2D

var id = 493
var ally = []
@onready var operator = $Weapon
@export var can_move = true
@export var animation = true
@export var fight = true

@export var walk_speed = 1200
@export var dash_speed = 2400
@export var aim_speed = 200
@export var crouch_speed = 400
@export var use_speed = 600
@export var jump_speed = 2500
var speed = 0
var accel = 100.0

func _ready():
	Operator.conqueror.append(self)
	Engine.set_physics_ticks_per_second(60)
	Setting.tick = 60.0/Engine.physics_ticks_per_second
	Setting.inverse = Engine.physics_ticks_per_second/60
	Engine.max_fps = 75
func _process(_delta):
	if animation:
		animate()
		emote()
func _physics_process(_delta):
	ui()
	stat()
	part()
	gravity()
	if can_move:
		dash()
		slide()
		movement()
	move_speed()
	move_and_slide()
	velocity.x = clampf(velocity.x ,-speed,speed)
	accel = 100 * Setting.tick
	if fight:
		$Weapon.active()
		melee()
		skill()
	if abs(velocity.x) > 1600 and (dash_left or dash_right) or break_charge > 12 or $Melee/Slash_delay.time_left > 0.2 and (slash_count > 3 and (slash_count < 6 and !corruptor or corruptor) or slash_count == 7 or evading or slash_dash) or (!corruptor and slash and slash_count == 6) or slash_delay and slash_count == 0 and !slash_up or $Weapon/Lethal.time_left > 0 or $Weapon.lethal_hold or $Weapon/Sentry.time_left > 0 or igniting:
		if $Weapon.switch_count > 0:
			$Weapon.switch_count = 0
	else:
		if $Weapon.switch_count == 0 and !$Weapon.bare:
			$Weapon.switch_count += $Weapon.back_count
			$Weapon/Switch.start(0.3)
		elif $Weapon.bare:
			$Weapon.switch_count = 1
func ui():
	$UI.hp = hp
	$UI.armor_plate = armor
	$UI.infantry_armor = infantry_armor
	$UI.infantry_cool = infantry_cool
	$UI.succinct = succinct
	$JumpBar.modulate.a = 1 - $Weapon/Inventory.modulate.a
	$SlideBar.modulate.a = 1 - $Weapon/Inventory.modulate.a
	$Weapon/Inventory/Equipment/Kit/Armor/Label.text = str(Inventory.armor)
	if !$Weapon.bare:
		$UI.current_ammo = $Weapon.current_ammo
		$UI.reverse_ammo = $Weapon.reverse_ammo
		$UI.current_gun = $Weapon.current_gun
		$UI.fire_mode = $Weapon.fire_mode
		$UI.fire_delay = $Weapon.coiling
	if !Inventory.hawk or count_jump > 0:
		$JumpBar.max_value = jump_time
		$JumpBar.value = count_jump
	else:
		$JumpBar.max_value = fly_time
		$JumpBar.value = count_fly
	if dashing:
		$SlideBar.max_value = $DashTimer.wait_time * 100
		$SlideBar.value = $DashTimer.time_left * 100
	else:
		if $DashCool.time_left > 0:
			$SlideBar.max_value = $DashCool.wait_time * 100
			$SlideBar.value = $DashCool.wait_time * 100 - $DashCool.time_left * 200
	$UI.lethal_left = Inventory.lethal.size() + $Weapon.charging_lethal
	$UI.lethal_type = $Weapon.lethal
	$UI.tactical_left = Inventory.tactical.size() + $Weapon.charging_tactical
	$UI.tactical_type = $Weapon.tactical
	
var conscious = 0
var resilience = 0
var recovery = 0
var hp = 100.0
var heal_cool = 0
var healing = false
var heal_time = 0
var flash_time = 0
var hit_position = Vector2()
var hurt_slow = 0
@onready var battery = preload("res://Screen/Asset/Entity/Object/Piece/battery.tscn")
func stat():
	Engine.time_scale = hurt_slow * melee_slow * $Weapon.slow
	heal_cool = move_toward(heal_cool,0,1 * Setting.tick)
	evade = move_toward(evade,0,1 * Setting.tick)
	if !slash and !evade > 0:
		evading = false
	avoiding = move_toward(avoiding,0,1 * Setting.tick)
	if Inventory.medic:
		if hp < 100 and !corruptor and heal_cool < 1:
			hp += Setting.tick + 0.25 * recovery
	if heal_time > 0:
		heal_time -= Setting.tick
		if hp < 100 and heal_cool < 1:
			hp += Setting.tick * (1 + recovery)
	hp = clampf(hp,0,100)
	if Key.tactical_hold and Inventory.tactical.size() > 0 and Inventory.tactical[0] == 6 and hp < 100 and !healing and abs(velocity.x) < 1600 and !$Weapon.throwing and !$Weapon.switching and !$Weapon.mode_changing and !$Weapon.reloading and !$Weapon.fire_delay and !slash and !climb and !armor_using:
		$Weapon/Heal.start(0.5)
		Inventory.tactical.remove_at(0)
	if $Weapon/Heal.time_left > 0:
		healing = true
		$Weapon/Anim.play("Heal")
	else:
		if healing:
			heal_cool = 0
			heal_time += 60
			var ins = battery.instantiate()
			ins.position = $Weapon.global_position
			ins.angular_velocity = 20 * facing
			ins.get_node("Smoke").restart()
			ins.apply_impulse(Vector2(randf_range(220,180) * facing, randf_range(-250,-350)).rotated(0), Vector2())
			get_tree().get_root().call_deferred("add_child",ins)
		healing = false
	immunity = move_toward(immunity,0,1 * Setting.tick)
	flash_time = move_toward(flash_time,0,(1 + conscious) * Setting.tick)
	AudioServer.get_bus_effect(AudioServer.get_bus_index("Sound"),1).set_cutoff(flash_time * 20)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Sound"),1,flash_time > 0)
	$UI/Flash.modulate = Color8(255,255,255,int(flash_time*4))
	$Effect/Hurt.modulate = Color(1,1,1,1-(hp/100))
	if $Hurt.time_left > 1 - (0.1 - 0.025 * conscious):
		if !armor > 0:
			if hp < 50:
				hurt_slow = 0.25
			$UI/Glitch.show()
			$UI/Stat/HP/Anim.play("Hurt")
	elif evade > 0 and !slash:
		hurt_slow = 0.5
	else:
		hurt_slow = lerpf(hurt_slow,1,0.25 * Setting.tick)
		$UI/Glitch.hide()
		if hp < 20:
			$UI/Stat/HP/Anim.play("Low")
		else:
			$UI/Stat/HP/Anim.play("Off")
	if abs(velocity.x) > 1600 or $Weapon.throwing or $Weapon.switching or $Weapon.mode_changing or $Weapon.reloading or $Weapon.fire_delay or $Weapon.aim or slash or climb:
		$Weapon/Armor.stop()
		$Weapon/Heal.stop()
		$Weapon/Shield/Anim.play("Off")
		armor_using = false
		healing = false

var perk_type_1 = 0
var perk_type_2 = 0
var perk_type_4 = 0

var phantom = 0
var alert = 0
var corruptor = false
var corruptor_cool = 0
var overload = 0
var overclock = 0
func skill():
	if Inventory.enginner:
		trojan()
		sentry()
	if Inventory.infantry:
		chaser()
		ignitor()
	else:
		$Weapon/Igniter.scale = Vector2(0,0)
		$Weapon/Igniter/Collision.disabled = true
	contigency()
	if Inventory.breaker and Key.skill_mode and corruptor_cool == 0:
		corruptor = !corruptor
		$Effect/Transform.restart()
		$UI/Mask/Ani.play("Deploy")
		corruptor_cool = 120
	corruptor_cool = move_toward(corruptor_cool,0,1 * Setting.tick)
	$Effect/Corruptor.emitting = corruptor
	$UI/Skill/CD.value = 120 - corruptor_cool
	$UI/Skill/Atkskill/CD.max_value = 400
	if Inventory.breaker:
		riptide()
	if Inventory.defender:
		shield()
	spectre()
	if corruptor:
		$UI/Skill/Atkskill.frame = 7
		$UI/Skill/Atkskill/Class.frame = 5
		$UI/Skill/Atkskill/CD.value = ignite_time
		$UI/Skill/Tacskill.frame = 9
		$UI/Skill/Tacskill/Class.frame = 1
		$UI/Skill/Tacskill/CD.value = crash_cool
		$UI/Skill/Tacskill/CD.max_value = 400
		invisible = false
	else:
		$UI/Skill/Atkskill.frame = 5
		$UI/Skill/Atkskill/Class.frame = 5
		$UI/Skill/Atkskill/CD.value = chaser_time
		$UI/Skill/Tacskill.frame = 8
		$UI/Skill/Tacskill/Class.frame = 0
		$UI/Skill/Tacskill/CD.value = invisible_time
		$UI/Skill/Tacskill/CD.max_value = 200 + 50 * overclock
		igniting = false
var invisible = false
var invisible_time = 200
var invisible_cool = 0
var spectre_color = Color()
func spectre():
	if Key.tactical_skill and !invisible_cool > 0 and !corruptor:
		invisible = !invisible
		if invisible:
			invisible_cool = 100
	$SpriteR.modulate = spectre_color
	$SpriteL.modulate = spectre_color
	$Melee/CBlade.self_modulate = spectre_color
	$Melee/CBlade2.self_modulate = spectre_color
	if !$Weapon.bare:
		$Weapon.gun.modulate = spectre_color
	if invisible_cool > 0:
		invisible_cool -= Setting.tick
	if invisible:
		if invisible_time > 0:
			invisible_time -= Setting.tick
		else:
			invisible = false
		$UI/Skill/Tacskill.self_modulate = Color(1,1,1)
	else:
		if invisible_time < 200 + 50 * overclock:
			invisible_time += (1 + 0.25 * overload) * Setting.tick
		if invisible_cool > 0:
			$UI/Skill/Tacskill.self_modulate = Color(0.44,0.44,0.44)
		else:
			$UI/Skill/Tacskill.self_modulate = Color(0.7,0.7,0.7)
		spectre_color = Color(1,1,1,melee_modulate)
	if invisible:
		$HitBox.set_collision_layer_value(1,false)
		spectre_color = Color(0,0,0,0.02)
	elif evade > 20:
		$HitBox.set_collision_layer_value(1,false)
		spectre_color = Color(0,0,0,0)
	else:
		$HitBox.set_collision_layer_value(1,true)
var shield_time = 200
var shield_cool = 0
func shield():
	if $Weapon.aim and !corruptor:
		if shield_time > 0:
			shield_time -= Setting.tick
		shield_cool = 50
	else:
		if shield_cool < 1 and shield_time < 200 + 50 * overclock:
			shield_time += (1 + 0.25 * overload) * Setting.tick
	if $Weapon.aim and shield_time > 0 and !corruptor:
		$Weapon/Rotation/Recoil/Body/ArmL/Shield.scale.y = lerpf($Weapon/Rotation/Recoil/Body/ArmL/Shield.scale.y,1,0.2 * Setting.tick)
		$Weapon/Rotation/Recoil/Body/ArmL/Shield/CollisionShape2D.disabled = false
		$UI/Skill/Defskill.self_modulate = Color(1,1,1)
	else:
		$Weapon/Rotation/Recoil/Body/ArmL/Shield.scale.y = lerpf($Weapon/Rotation/Recoil/Body/ArmL/Shield.scale.y,0,0.5 * Setting.tick)
		$Weapon/Rotation/Recoil/Body/ArmL/Shield/CollisionShape2D.disabled = true
		if shield_cool > 0:
			shield_cool -= Setting.tick
		if shield_time == 0:
			$UI/Skill/Defskill.self_modulate = Color(0.44,0.44,0.44)
		else:
			$UI/Skill/Defskill.self_modulate = Color(0.7,0.7,0.7)
	$UI/Skill/Defskill.frame = 10
	$UI/Skill/Defskill/Class.frame = 2
	$UI/Skill/Defskill/CD.value = shield_time
	$UI/Skill/Defskill/CD.max_value = 200 + 50 * overclock

var shocker = load("res://Screen/Asset/Entity/Bullet/Shock.tscn")
func earthquake():
	var ins = shocker.instantiate()
	ins.position = global_position
	get_tree().get_root().call_deferred("add_child",ins)

var chaser_drone = load("res://Screen/Asset/Entity/Ally/Drone.tscn")
var chaser_time = 400
func chaser():
	if Key.lethal_skill and chaser_time >= 400 and !corruptor:
		$Weapon/Chaser.start(0.5)
		var ins = chaser_drone.instantiate()
		ins.position = $Weapon/ArmL.global_position
		ins.rotation = $Weapon/Rotation/Recoil.global_rotation
		ins.facing = facing
		ins.apply_impulse(Vector2(1000,-1000 * facing).rotated($Weapon/Rotation/Recoil.global_rotation), Vector2())
		get_tree().get_root().add_child(ins)
		var tween = create_tween().set_loops(2)
		tween.tween_property($UI/Skill/Atkskill,"self_modulate", Color(1,1,1), 0.1)
		tween.chain().tween_property($UI/Skill/Atkskill,"self_modulate", Color(0.7,0.7,0.7), 0.1)
		tween.play()
		chaser_time = 0
	if chaser_time < 400:
		chaser_time += (1 + 0.25 * overload) * Setting.tick
		if !corruptor:
			$UI/Skill/Atkskill.self_modulate = Color(0.44,0.44,0.44)
	else:
		if !corruptor:
			$UI/Skill/Atkskill.self_modulate = Color(0.7,0.7,0.7)
var armor = 0
var armor_using = false
var infantry_armor = 0
var infantry_cool = 0
var armor_break = false
var current_armor = 0
var armor_left = 0
var succinct = 0
func contigency():
	if (Key.armor or $Weapon/Inventory/Equipment/Kit/Armor.is_hovered() and Key.fired) and (Inventory.armor > 0 or !infantry_cool > 0) and (armor < 150 or infantry_armor < 50 and succinct == 0 or infantry_armor < 75 and succinct > 0) and !armor_using and abs(velocity.x) < 1600 and !$Weapon.throwing and !$Weapon.switching and !$Weapon.mode_changing and !$Weapon.reloading and !$Weapon.fire_delay and !$Weapon.aim and !slash and !climb and !$Weapon/Heal.time_left > 0:
		$Weapon/Armor.start(0.5)
		$UI.armor_use = true
	armor = clampi(armor,0,150)
	if succinct > 0:
		infantry_armor = clampi(infantry_armor,0,75)
		if armor >= 75:
			armor_left = 150 - armor
		else:
			armor_left = 75 - armor
		if armor > 75:
			current_armor = armor - 75
		else:
			current_armor = armor
	else:
		infantry_armor = clampi(infantry_armor,0,50)
		if armor >= 50:
			if armor >= 100:
				armor_left = 150 - armor
			else:
				armor_left = 100 - armor
		else:
			armor_left = 50 - armor
		if armor > 50:
			if armor > 100:
				current_armor = armor - 100
			else:
				current_armor = armor - 50
		else:
			current_armor = armor
	if $Weapon/Armor.time_left > 0:
		$Weapon/Anim.play("Armor")
		armor_using = true
		var tween = create_tween()
		tween.tween_property($Weapon/Shield, "modulate", Color(1,1,1,1), 0)
		tween.chain().tween_property($Weapon/Shield, "modulate", Color(1,1,1,0), 0.5)
		tween.play()
		if armor < 50 and succinct == 0 or armor < 75 and succinct > 0:
			$Weapon/Shield/Anim.play("Fill1")
		else:
			if armor < 100 and succinct == 0 or armor < 150 and succinct > 0:
				$Weapon/Shield/Anim.play("Fill2")
			else:
				$Weapon/Shield/Anim.play("Fill3")
	else:
		if armor_using:
			if (!infantry_cool > 0 or Inventory.armor == 0 and !infantry_cool > 0 or armor > 100 and infantry_armor > 0) and Inventory.infantry:
				if succinct > 0:
					infantry_armor = 75
				else:
					infantry_armor = 50
				armor += armor_left
				infantry_cool = 300
			else:
				if (armor > 75 and succinct > 0 or armor > 100 and succinct == 0) and infantry_cool > 0 and Inventory.infantry:
					infantry_armor = 0
				if succinct > 0:
					armor += 75
				else:
					armor += 50
				Inventory.armor -= 1
			$UI.current_plate = Inventory.armor
		armor_using = false
	if infantry_cool > 0 and Inventory.infantry:
		infantry_cool -= (1 + 0.25 * overload) * Setting.tick
	if armor < 0:
		armor = 0
	if infantry_armor < 0:
		infantry_armor = 0
	if $Hurt.time_left > 0.9 and armor_break:
		if armor > 0:
			if armor > 50 and succinct == 0 or armor > 75 and succinct > 0:
				$Weapon/Shield/Anim.play("Break3")
			else:
				$Weapon/Shield/Anim.play("Break2")
		else:
			$Weapon/Shield/Anim.play("Break1")
		var tween = create_tween()
		tween.tween_property($Weapon/Shield, "modulate", Color(1,1,1,1), 0)
		tween.chain().tween_property($Weapon/Shield, "modulate", Color(1,1,1,0), 0.5)
		tween.play()
	else:
		armor_break = false

var ignite_time = 400
var ignite_cool = 0
var igniting = false
func ignitor():
	if Key.lethal_skill and !ignite_cool > 0 and corruptor:
		if igniting:
			ignite_cool = 200
			ignite_time = 0
			igniting = !igniting
		else:
			if ignite_time >= 400:
				igniting = !igniting
				$Weapon/Ignitor.start(0.5)
	if $Weapon.switching or $Weapon/Armor.time_left > 0 or $Weapon/Heal.time_left > 0 or $Weapon.throwing or $Weapon/Sentry.time_left > 0:
		igniting = false
	if ignite_cool > 0:
		ignite_cool -= Setting.tick
	$Weapon/Igniter.scale.y = $Weapon/Igniter.scale.x
	if igniting:
		$Weapon/Igniter.scale.x = lerpf($Weapon/Igniter.scale.x,1,0.2 * Setting.tick)
		$Weapon/Igniter.modulate.a = lerpf($Weapon/Igniter.modulate.a,1,0.2 * Setting.tick)
		if !$Weapon/Igniter/Burndelay.time_left > 0:
			$Weapon/Igniter/Collision.disabled = !$Weapon/Igniter/Collision.disabled
			$Weapon/Igniter/Burndelay.start(0.05)
			$Weapon/Camera2D.shake(2,5)
			if hp > 0:
				hp -= Setting.tick
		if corruptor:
			$UI/Skill/Atkskill.self_modulate = Color(1,1,1)
	else:
		$Weapon/Igniter/Collision.disabled = true
		$Weapon/Igniter.scale.x = lerpf($Weapon/Igniter.scale.x,0,0.2 * Setting.tick)
		$Weapon/Igniter.modulate.a = lerpf($Weapon/Igniter.modulate.a,0,0.2 * Setting.tick)
	if ignite_time < 400:
		if corruptor:
			$UI/Skill/Atkskill.self_modulate = Color(0.44,0.44,0.44)
	else:
		if corruptor:
			$UI/Skill/Atkskill.self_modulate = Color(0.7,0.7,0.7)
			
var crashing = false
var crash_cool = 400
func riptide():
	if Key.tactical_skill and corruptor and (crash_cool >= 400 or Operator.portal_placed):
		slash_delay_time = 0.2
		slash_count = 1
		$Melee/Slash_delay.start(slash_time)
		crashing = true
		melee_slow = 0.95
		if !Operator.portal_placed:
			crash_cool = 0
@onready var turret = preload("res://Screen/Asset/Weapon/Lethal/Sentry.tscn")
var sentry_cool = 0
func sentry():
	if Key.sentry and !sentry_cool > 0:
		var ins = turret.instantiate()
		ins.global_position = global_position
		ins.facing = -facing
		ins.apply_impulse(Vector2(1000 + velocity.x * facing,velocity.y * facing).rotated($Weapon/Rotation/Recoil.global_rotation - 0.2 * facing), Vector2())
		get_tree().get_root().add_child(ins)
		$Weapon/Sentry.start(0.3)
		sentry_cool = 1800
		var tween = create_tween().set_loops(2)
		tween.tween_property($UI/Weapon/Sentry,"self_modulate", Color(1,1,1), 0.1)
		tween.chain().tween_property($UI/Weapon/Sentry,"self_modulate", Color(0.7,0.7,0.7), 0.1)
		tween.play()
	if sentry_cool > 0:
		sentry_cool -= (1 + 0.25 * overload) * Setting.tick
		$UI/Weapon/Sentry.self_modulate = Color(0.44,0.44,0.44)
	else:
		$UI/Weapon/Sentry.self_modulate = Color(0.7,0.7,0.7)
	$UI/Weapon/Sentry/CD.value = 1800 - sentry_cool
	$UI/Weapon/Sentry/CD.max_value = 1800
var hold = 0
var hacking = false
func trojan():
	if $Weapon/PickRange.is_colliding() and $Weapon/PickRange.get_collider(0) != null:
		if Key.using and hold <= 20:
			hold += Setting.tick
		if hold == 20:
			hold = 0
	
var slash = false
var slash_time = 0.0
var slash_count = 0
var slash_delay = false
var slash_delay_time = 0.0
@export var melee_dash = false
var melee_dash_boost = 0
var target_dash = 0
var break_cool = 600
var break_charge = 0
var spear_rotate = 0
var melee_slow = 1
var evading = false
var slash_up = false
var slash_dash = false
var target_behind = false
@export var melee_modulate = 0
@export var domain_slow = 0.0
var berserk = 0
var slash_buffer = 0
var kick = false
func melee():
	slash_time = 0.8
	$Melee.scale.x = facing
	$Melee.dmg = 50 + 12.5 * berserk
	$Melee.corruptor = corruptor
	$AniMelee.speed_scale = Engine.time_scale
	$Melee/CBlade.z_index = $Melee/HandL.z_index * facing
	$Melee/CBlade2.z_index = $Melee/HandR.z_index * facing - 2
	$Melee/BSword.z_index = $Melee/HandL.z_index * facing - 1
	$Melee/BSword2.z_index = $Melee/HandL.z_index * facing - 1
	$Melee/HSpear.global_rotation = spear_rotate
	if break_cool < 600:
		if !corruptor:
			break_cool += (1 + 0.25 * overload) * Setting.tick
	if Key.attack_charge and (corruptor and Operator.prism > 0 or !corruptor and Inventory.hawk) and !slash_delay and break_cool >= 600 and break_charge <= 30 and abs(velocity.x) < 1600 and velocity.y > -1600 and slash_count == 0 and !crouching and !sliding and !evading and !igniting and !slash_up:
		break_charge += Setting.tick
		if break_charge > 0:
			if break_charge < 12:
				spear_rotate = $Weapon/Rotation.global_rotation
			else:
				Operator.emit_signal("break_charge")
		$Melee.charge = break_charge
	else:
		if break_charge < 30:
			break_charge = 0
	if slash_count < 2 and slash_buffer > 0 and Key.jump and $Grounded.is_colliding() and !$Ouch.is_colliding():
		slash_up = true
	if $Melee/Slash_delay.time_left > slash_time - slash_delay_time or $Melee/Kick.time_left > 0.1:
		slash_delay = true
	else:
		slash_delay = false
		melee_dash = false
		slash_dash = false
		if slash_up:
			slash_count = 0
			slash_up = false
	$Weapon.melee = slash_delay
	if Key.attack and (break_cool < 600 or !corruptor and !Inventory.hawk) or Key.attacked and (break_charge < 30 and break_cool >= 600 and (!corruptor and Inventory.hawk or corruptor) or $Weapon.echo > 0):
		slash_buffer = 8
	if slash_buffer > 0:
		slash_buffer -= Setting.tick
	if $Grounded.is_colliding() or !$Grounded.is_colliding() and slash_count < 6 and !sliding:
		if slash_buffer > 0 and !slash_delay and !crouching and !igniting and (evade == 0 or evade > 30) or break_charge >= 30:
			$Melee/Slash_delay.start(slash_time)
			if evade > 30 and clone.size() > 0:
				evading = true
				slash_dash = false
				for i in clone:
					if i != null:
						i.attack()
			if !evading and !evade > 0 and (dash_right or dash_left):
				slash_dash = true
				dash_right = false
				dash_left = false
			if !break_charge > 0:
				if (!$Weapon.bare and (corruptor and slash_count < 6 or !corruptor and slash_count < 8)) or ($Weapon.bare and slash_count < 6):
					if $Weapon.bare and slash_count == 0:
						slash_count += 4
					else:
						if !(sliding and slash_count > 0):
							if corruptor:
								if !slash_count == 0 and slash_count < 4 and !slash_dash or slash_dash and slash_count < 1 or evading:
									slash_count += 3
								else:
									slash_count += 1
							else:
								if slash_dash or evading:
									slash_count += 3
								else:
									slash_count += 1
				else:
					if $Weapon.bare:
						slash_count -= 2
					else:
						if corruptor:
							slash_count -= 2
						else:
							slash_count -= 4
			match slash_count:
				0:
					if corruptor and !slash_up:
						slash_delay_time = 0.6
					else:
						slash_delay_time = 0.2
						melee_dash_boost = -2000
				1:
					slash_delay_time = 0.2
					melee_dash_boost = 2000
				2:
					slash_delay_time = 0.2
					melee_dash_boost = 0
				3:
					if evading or slash_dash:
						slash_delay_time = 0.4
						melee_dash_boost = 4000
					else:
						slash_delay_time = 0.2
						melee_dash_boost = 0
				4:
					slash_delay_time = 0.2
					if corruptor:
						melee_dash_boost = 4000
					else:
						melee_dash_boost = 2000
				5:
					slash_delay_time = 0.2
					if corruptor:
						melee_dash_boost = -4000
					else:
						melee_dash_boost = 2000
				6:
					if corruptor:
						slash_delay_time = 0.3
						if $Grounded.is_colliding():
							melee_dash_boost = 8000
						else:
							melee_dash_boost = 16000
					else:
						slash_delay_time = 0.4
						melee_dash_boost = 0
				7:
					slash_delay_time = 0.6
					melee_dash_boost = 0
				8:
					slash_delay_time = 0.4
					melee_dash_boost = 8000
			melee_slow = 0.95
		else:
			melee_slow = lerpf(melee_slow,1,0.25 * Setting.tick)
	if $Melee/Slash_delay.time_left > 0 and !slash_up or break_charge > 0 or $Melee/Kick.time_left > 0:
		slash = true
		if $Weapon.bare:
			melee_idle = true
			if abs(velocity.x) > 800 and !melee_dash:
				if !$Melee/Slash_delay.time_left > 0.4:
					slash = false
					$AniMelee.play("Off")
					$Melee/Slash_delay.stop()
		else:
			melee_idle = false
	else:
		slash = false
		crashing = false
	if melee_idle and abs(velocity.x) > 100 or abs(velocity.y) > 200:
		melee_idle = false
	if slash_delay:
		if break_charge > 12 and !slash_up:
			if corruptor:
				$AniMelee.play("Sword_B3")
			else:
				$AniMelee.play("Spear_2")
			break_cool = 0
			break_charge = 0
			slash_count = 0
		else:
			match slash_count:
				1:
					if corruptor:
						if crashing:
							$AniMelee.play("Sword_E")
						elif slash_up:
							$AniMelee.play("Sword_U")
						elif $Melee/Kick.time_left > 0:
							$AniMelee.play("Kick")
						else:
							$AniMelee.play("Sword_Q")
					else:
						if sliding:
							$AniMelee.play("Quick_S")
						elif slash_up:
							$AniMelee.play("Quick_Up")
						elif $Melee/Kick.time_left > 0:
							$AniMelee.play("Kick")
						else:
							$AniMelee.play("Quick_1")
				2: $AniMelee.play("Quick_2")
				3: 
					if corruptor:
						if slash_dash:
							$AniMelee.play("Sword_D")
						elif evading:
							$AniMelee.play("Punch")
					else:
						if evading:
							$AniMelee.play("Blade_6")
						elif slash_dash:
							$AniMelee.play("Blade_D")
						else:
							$AniMelee.play("Quick_3")
				4:
					if corruptor:
						$AniMelee.play("Sword_1")
					else:
						if $Weapon.bare:
							$AniMelee.play("Bare_1")
						else:
							$AniMelee.play("Blade_1")
				5:
					if corruptor:
						$AniMelee.play("Sword_2")
					else:
						if $Weapon.bare:
							$AniMelee.play("Bare_2")
						else:
							$AniMelee.play("Blade_2")
				6:
					if corruptor:
						$AniMelee.play("Sword_3")
					else:
						if $Weapon.bare:
							$AniMelee.play("Bare_3")
						else:
							$AniMelee.play("Blade_3")
				7: $AniMelee.play("Blade_4")
				8: $AniMelee.play("Blade_5")
		if !corruptor:
			$Melee/HandR.global_position = $Melee/HSpear/HandR.global_position
			$Melee/HandL.global_position = $Melee/HSpear/HandL.global_position
	elif break_charge > 0:
		if corruptor:
			$AniMelee.play("Sword_B1")
		else:
			$AniMelee.play("Spear_1")
			$Melee/HandR.global_position = $Melee/HSpear/HandR.global_position
			$Melee/HandL.global_position = $Melee/HSpear/HandL.global_position
	else:
		if !$Melee/Slash_delay.time_left > 0:
			if !break_charge > 0 and !melee_idle and !crashing:
				$AniMelee.play("Off")
			if $Grounded.is_colliding():
				slash_count = 0
	if $Melee/Target.is_colliding() and $Melee/Target.get_collider(0) != null and $Melee/Target.get_collider(0).get_parent().is_in_group("target") and !slash_dash and !evading and slash_count != 0:
		target_dash = ($Melee/Target.get_collision_point(0).x - global_position.x) * 15
	else:
		target_dash = 0
		target_behind = false
	if melee_dash:
		if slash_count == 6 and corruptor and $Grounded.is_colliding() or evading and !slash_dash:
			velocity = Vector2(facing,0.2).normalized() * (melee_dash_boost + abs(target_dash))
		elif slash_count == 6 and corruptor and !$Grounded.is_colliding():
			velocity = Vector2(facing,1).normalized() * (melee_dash_boost + abs(target_dash))
		else:
			velocity = Vector2(facing,0).normalized() * (melee_dash_boost + abs(target_dash))
	if Key.kick and $Grounded.is_colliding() and !slash_delay:
		$Melee/Kick.start(1.1)
		slash_count = 1
		melee_dash_boost = 1000
	$UI/Skill/Meleeskill/CD.value = break_cool
	$UI/Skill/Meleeskill/CD.max_value = 600
	if break_cool < 600:
		$UI/Skill/Meleeskill.frame = 0
		$UI/Skill/Meleeskill/Class.frame = 0
		if slash_delay:
			$UI/Skill/Meleeskill.self_modulate = Color(1,1,1)
		else:
			$UI/Skill/Meleeskill.self_modulate = Color(0.7,0.7,0.7)
	else:
		if corruptor:
			$UI/Skill/Meleeskill.frame = 1
			$UI/Skill/Meleeskill/Class.frame = 1
		else:
			$UI/Skill/Meleeskill.frame = 4
			$UI/Skill/Meleeskill/Class.frame = 4
		if break_charge > 0:
			$UI/Skill/Meleeskill.self_modulate = Color(1,1,1)
		else:
			$UI/Skill/Meleeskill.self_modulate = Color(0.7,0.7,0.7)
var jump_buffer = 0
func movement():
	if !break_charge > 0 and !sliding and !(slash_delay and slash_count > 3 or slash and !$Grounded.is_colliding() or evading) and !$Sit.is_colliding() and !$GroundTimer.time_left > 0.5:
		if (Key.lefting or $UI/Control/Left.is_pressed()) and !Key.righting and !($BlockL.is_colliding() and $Grounded.is_colliding()):
			if $Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding()):
				if swim:
					velocity.x -= accel/2
				else:
					velocity.x = lerpf(velocity.x,0,0.05 * Setting.tick)
			else:
				if velocity.x > 0 or (Setting.fast_step and velocity.x < 800 and !$Weapon.aim):
					velocity.x -= accel * 4
				else:
					velocity.x -= accel
		elif (Key.righting or $UI/Control/Right.is_pressed()) and !Key.lefting and !($BlockR.is_colliding() and $Grounded.is_colliding()):
			if $Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding()):
				if swim:
					velocity.x += accel/2
				else:
					velocity.x = lerpf(velocity.x,0,0.05 * Setting.tick)
			else:
				if velocity.x < 0 or (Setting.fast_step and velocity.x > -800 and !$Weapon.aim):
					velocity.x += accel * 4
				else:
					velocity.x += accel
		else:
			if $Grounded.is_colliding() or $Blub.is_colliding():
				velocity.x = lerpf(velocity.x,0,0.2 * Setting.tick)
			else:
				if abs(velocity.x) < 800:
					velocity.x = lerpf(velocity.x,0,0.1 * Setting.tick)
				elif abs(velocity.x) > 800 and abs(velocity.x) < 1600:
					velocity.x = lerpf(velocity.x,0,0.01 * Setting.tick)
				else:
					velocity.x = lerpf(velocity.x,0,0.005 * Setting.tick)
	elif sliding:
		velocity.x = clampf(slide_boost,-speed,speed)
	else:
		velocity.x = lerpf(velocity.x,0,0.2 * Setting.tick)
	if $Grounded.is_colliding() and abs(velocity.x) < 800 and Key.crouch and !Setting.crouch_hold and !$Blub.is_colliding() and !slash:
		crouching = !crouching
	elif abs(velocity.x) < 1600 and !sliding and $Grounded.is_colliding() and $Ouch.is_colliding() or Key.crouching and Setting.crouch_hold and $Grounded.is_colliding() and abs(velocity.x) < 800 and !$Blub.is_colliding() and !slash:
		crouching = true
	elif (Key.crouch and !Setting.crouch_hold or !Key.crouching and Setting.crouch_hold) and crouching and !$Ouch.is_colliding() or crouching and dashing or crouching and Key.jump and !$Ouch.is_colliding():
		crouching = false
	elif crouching and !$Grounded.is_colliding():
		await get_tree().create_timer(0.1).timeout
		if !$Grounded.is_colliding():
			crouching = false
		else:
			crouching = true
	if shifter == 1:
		jump_time = 3
	else:
		jump_time = 2
	if $Grounded.is_colliding() and !sliding and velocity.y >= 0:
		count_jump = jump_time
		if count_fly < fly_time:
			count_fly += 2 * Setting.tick
	elif $Grounded.is_colliding() and sliding:
		count_jump = jump_time - 1
	if Key.jump and count_jump < 1:
		jump_buffer = 16
	if jump_buffer > 0:
		jump_buffer -= Setting.tick
	if (Key.jump or jump_buffer > 0) and (count_jump > 0 or climb) and !($Ouch.is_colliding() and $Grounded.is_colliding()) and !slash_delay and !(sliding and slash) and !igniting and !($Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding())):
		normal_jump()
		dashing = false
		$DashTimer.stop()
		if $Grounded.is_colliding():
			$Effect.jump()
		if climb:
			$ClimbTimer.start(0.5)
		else:
			count_jump -= 1
	if Inventory.hawk:
		if count_jump < 1 and Key.fly and count_fly > 0:
			dashing = false
			$DashTimer.stop()
			velocity.y -= accel * 2
			count_fly -= Setting.tick
			$Effect/JetR.one_shot = false
			$Effect/JetL.one_shot = false
			$Effect/JetR.emitting = true
			$Effect/JetL.emitting = true
			fly = true
		else:
			$Effect/JetR.one_shot = true
			$Effect/JetL.one_shot = true
			fly = false
	if !$Grounded.is_colliding() and count_jump > jump_time - 1:
		await get_tree().create_timer(0.2).timeout
		count_jump = jump_time - 1
	if !$Grounded.is_colliding() and $Weapon.get_child(0).get_class() == "Node2D" and $Weapon.current_gun == 40 and $Weapon.coiling:
		$Weapon/Knockback.global_position = $Weapon/Rotation/Recoil/Body.global_position
		velocity.x += $Weapon/Knockback.position.x/ 5 * 200
		velocity.y += $Weapon/Knockback.position.x/ -5 * 50
var walk_delay = 0
var sprint_delay = 0
func move_speed():
	if ($Weapon.reloading or $Weapon.switching or $Weapon.fire_delay or $Weapon.throwing or Key.up or Key.down or $Weapon.current_gun == 31 and $Weapon.gun.charge > 0 or $Weapon.mode_changing or armor_using or healing) and !slash and !sliding and !dashing:
		walk_delay = 8
		sprint_delay = 0
	if walk_delay > 0:
		walk_delay -= Setting.tick
	if walking and !$Weapon.buffer > 0:
		sprint_delay = 8 - 20 * $Weapon.aim_speed
	if sprint_delay > 0:
		sprint_delay -= Setting.tick
	if $Weapon.aim or igniting:
		if $Grounded.is_colliding() and !sliding:
			if crouching:
				speed = lerpf(speed,aim_speed,0.5 * Setting.tick)
			else:
				speed = lerpf(speed,aim_speed * (1 + $Weapon.aim_speed),0.5 * Setting.tick)
		else:
			speed = lerpf(speed,walk_speed,0.01 * Setting.tick)
	elif !$Weapon.aim and crouching:
		speed = lerpf(speed,crouch_speed,0.5 * Setting.tick)
	elif walk_delay > 0 or $Weapon.buffer > 0:
		walking = false
		if $Grounded.is_colliding():
			speed = lerpf(speed,use_speed,0.5 * Setting.tick)
		else:
			if abs(velocity.x) > 1600:
				speed = lerpf(speed,use_speed,0.01 * Setting.tick)
			else:
				speed = lerpf(speed,use_speed,0.1 * Setting.tick)
	elif dashing or sliding:
		if $DashTimer.time_left > dash_time - 0.125:
			speed = lerpf(speed,(dash_boost + dash_boost/4 * sonic),0.5 * Setting.tick)
		else:
			speed = lerpf(speed,dash_speed,0.2 * Setting.tick)
	elif (dash_right or dash_left) and !dashing:
		speed = dash_speed
	elif melee_dash:
		speed = dash_speed * 4
	elif slash and !melee_dash and !(!slash_delay and $Weapon.bare):
		if slash_count < 4 and !$Melee/Kick.time_left > 0:
			speed = lerpf(speed,use_speed,0.5 * Setting.tick)
		else:
			speed = lerpf(speed,0,0.5 * Setting.tick)
	else:
		if $Grounded.is_colliding() or $Blub.is_colliding():
			speed = lerpf(speed,walk_speed,0.2 * Setting.tick)
		else:
			speed = lerpf(speed,walk_speed,0.05 * Setting.tick)
	if $Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding()):
		if !$SwimTimer.time_left > 0:
			if Key.righting and !Key.lefting or Key.lefting and !Key.righting or Key.fly and !Key.dive or !Key.fly and Key.dive:
				swim_time = 0.4
			else:
				if swim:
					swim_time = 0.8
				else:
					swim_time = 0.4
			$SwimTimer.start(swim_time)
			swim = !swim
		if Key.right and !Key.lefting or Key.left and !Key.righting or Key.jump and !Key.dive or Key.crouch and !Key.fly:
			$SwimTimer.start(0.4)
			swim = true
var dash_timer_right = 0
var dash_timer_left = 0
var dash_time = 0.3
var dashing_right = true
var dashing = false
var dash_cancel = 0
@export var dash_boost = 3000.0
var dash_right
var dash_left
var sonic = 0
func dash():
	if !$DashCool.time_left > 0:
		if Key.left:
			if dash_timer_left < 10 and Setting.dash_mode < 3:
				dash_timer_left = 20
			dash_timer_right = 0
		elif Key.right:
			if dash_timer_right < 10 and Setting.dash_mode < 3:
				dash_timer_right = 20
			dash_timer_left = 0
		if !$Weapon.aim and !$Weapon.fire_delay and !slash and !Key.up and !Key.down and !igniting and !$BlockL.is_colliding() and !$Ouch.is_colliding():
			if Key.left and dash_timer_left > 0 and dash_timer_left < 18 and Setting.dash_mode == 2 or Key.dash and !facing_right and Setting.sprint_mode == 2:
				dash_left = true
				dash_timer_left = 0
				dash_timer_right = 0
				dashing_right = false
			if Key.left and dash_timer_left > 0 and dash_timer_left < 18 and Setting.dash_mode < 2 or Key.dash and !facing_right and Setting.sprint_mode < 2:
				dashing_right = false
				dash_left = true
				$DashTimer.start(dash_time)
				$DashCool.start(dash_time * 2)
				$Effect/JetR.restart()
				$Effect/JetL.restart()
				$Weapon/Camera2D.shake(5,10)
				dash_cancel = 10
		if !$Weapon.aim and !$Weapon.fire_delay and !slash and !Key.up and !Key.down and !igniting and !$BlockR.is_colliding() and !$Ouch.is_colliding():
			if Key.right and dash_timer_right > 0 and dash_timer_right < 18 and Setting.dash_mode == 2 or Key.dash and facing_right and Setting.sprint_mode == 2:
				dash_right = true
				dash_timer_left = 0
				dash_timer_right = 0
				dashing_right = true
			if Key.right and dash_timer_right > 0 and dash_timer_right < 18 and Setting.dash_mode < 2 or Key.dash and facing_right and Setting.sprint_mode < 2:
				dashing_right = true
				dash_right = true
				$DashTimer.start(dash_time)
				$DashCool.start(dash_time * 2)
				$Effect/JetR.restart()
				$Effect/JetL.restart()
				$Weapon/Camera2D.shake(5,10)
				dash_cancel = 10
	if $DashTimer.time_left > 0 and !melee_dash and !evade > 30:
		velocity = Vector2(1 * facing,0.05).normalized() * (dash_boost + dash_boost/4 * sonic)
		if abs(velocity.x) > 1600:
			dashing = true
			sliding = false
			$SlideTimer.stop()
	else:
		dashing = false
		dash_timer_left = move_toward(dash_timer_left,0,1 * Setting.tick)
		dash_timer_right = move_toward(dash_timer_right,0,1 * Setting.tick)
		dash_cancel = move_toward(dash_cancel,0,1 * Setting.tick)
		if (Setting.dash_mode == 1 or Setting.sprint_mode == 1):
			if dash_timer_right > 0 and Setting.dash_mode == 1:
				dash_right = false
			if dash_timer_left > 0 and Setting.dash_mode == 1:
				dash_left = false
			if dash_cancel > 0 and Setting.sprint_mode == 1:
				dash_right = false
			if dash_cancel > 0 and Setting.sprint_mode == 1:
				dash_left = false
	if abs(velocity.x) < 200 or Key.scroll_up or Key.scroll_down or dash_right and (Key.left or $BlockR.is_colliding()) or dash_left and (Key.right or $BlockL.is_colliding()) or Key.up or Key.down or $Weapon.aim:
		dashing = false
		dash_right = false
		dash_left = false
		$DashTimer.stop()
	if !dash_left and !dash_right:
		dashing = false
	$Effect/Dash.emitting = dashing
	
@export var jump_time = 2
@export var fly_time = 50
var count_jump = 0
var count_fly = 0
var climb = false
var fly = false
var shifter = 0
func normal_jump():
	if $Weapon.aim and $Grounded.is_colliding() or climb:
		velocity.y = -jump_speed * 3.0/4
	else:
		velocity.y = -jump_speed
	if count_jump < jump_time and !climb:
		$Effect/Boost.play()
		$Weapon/Camera2D.shake(5,10)
		$Effect/JetR.restart()
		$Effect/JetL.restart()
	break_charge = 0
var max_fall_speed = 3000.0
var fall_time = 0
var falling_speed = 0
var pre_slide_fall = 0
var swim = false
var swim_time = 0
func gravity():
	if $Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding()):
		if swim or $Breath.is_colliding() and !$Dive.is_colliding():
			if Key.dive and !Key.fly:
				velocity.y += accel/4
			elif Key.fly and !Key.dive:
				velocity.y -= accel/2
			else:
				if Key.righting and !Key.lefting and !Key.dive or Key.lefting and !Key.righting and !Key.dive:
					velocity.y -= accel/16
				else:
					velocity.y -= accel/8
				velocity.y = lerpf(velocity.y,0,0.1 * Setting.tick)
		else:
			if Key.dive and !Key.fly:
				velocity.y += accel/8
			else:
				velocity.y += accel/16
			velocity.y = lerpf(velocity.y,0,0.1 * Setting.tick)
	else:
		velocity.y += accel
		swim = false
	if climb:
		velocity.y = clampf(velocity.y,-jump_speed,0)
	elif $Melee/Slash_delay.time_left > slash_time - 0.4 and slash_count > 0 and !$Grounded.is_colliding() and !(corruptor and slash_count == 6 and melee_dash) or break_charge > 0:
		velocity.y = clampf(velocity.y,-jump_speed,max_fall_speed/50)
	else:
		velocity.y = clampf(velocity.y,-jump_speed,max_fall_speed)
	$Grounded.enabled = velocity.y > -400
	climb = !$Grounded.is_colliding() and !$CantClimb.is_colliding() and $Climb.is_colliding()
	floor_stop_on_slope = !sliding
	$Effect.ground = $Grounded.is_colliding() and !$Blub.is_colliding()
	if $Breath.is_colliding():
		AudioServer.get_bus_effect(AudioServer.get_bus_index("Sound"),0).set_cutoff(500)
	else:
		AudioServer.get_bus_effect(AudioServer.get_bus_index("Sound"),0).set_cutoff(20500)
	if velocity.y > 1600 and fall_time < 10:
		fall_time += 0.5 * Setting.tick
	if is_on_floor() and fall_time > 0:
		$Weapon/Camera2D.shake(fall_time,5)
		$GroundTimer.start(fall_time/20)
		fall_time = 0
	if sliding and velocity.y > 800:
		$GroundTimer.start(0.1)
var can_slide = true
var sliding = false
var slide_boost = 2000
var slide_time = 1.0
var slide_des = 0
func slide():
	can_slide = abs(velocity.x) > 800 and !$LegCollision/Slide.is_colliding() and !$Blub.is_colliding()
	if Key.crouch and !sliding and can_slide and !dashing:
		sliding = true
	if $Grounded.is_colliding():
		if velocity.y > 200:
			slide_des = -25
		elif velocity.y <= 200 and velocity.y > -2400:
			slide_des = 25
		else:
			slide_des = 50
	else:
		slide_des = 0
	if sliding:
		if abs(slide_boost) > 0 and $Grounded.is_colliding():
			slide_boost -= ((1 + abs(velocity.x))/slide_boost) * slide_des * Setting.tick
		if get_slide_collision_count() > 0 and rad_to_deg(abs(get_slide_collision(0).get_normal().angle() - (rotation - PI * 0.5) - 3)) > 135:
			$SpriteR.rotation = rotation + get_slide_collision(0).get_normal().angle() - (rotation - PI * 0.5)
			$SpriteL.rotation = rotation + get_slide_collision(0).get_normal().angle() - (rotation - PI * 0.5)
			$Weapon.rotation = rotation + get_slide_collision(0).get_normal().angle() - (rotation - PI * 0.5)
	else:
		if $Grounded.is_colliding():
			if abs(velocity.x) > 1600:
				slide_boost = velocity.x * 1.5
			else:
				slide_boost = velocity.x * 2
		else:
			slide_boost = velocity.x
		$SpriteR.rotation = lerpf($SpriteR.rotation,0,0.2 * Setting.tick)
		$SpriteL.rotation = lerpf($SpriteL.rotation,0,0.2 * Setting.tick)
		$Weapon.rotation = lerpf($Weapon.rotation,0,0.2 * Setting.tick)
	$Effect/Slide.emitting = sliding and $Grounded.is_colliding() and abs(velocity.x) > 1600
	$Effect/Slide.global_position.y = $LegCollision.global_position.y + 42
	$Effect/Slide.direction.x = - velocity.x/abs(velocity.x)
	if sliding:
		dashing = false
		dash_right = false
		dash_left = false
		if !$Grounded.is_colliding() and velocity.y > 1600:
			falling_speed = -velocity.y/4
		else:
			if falling_speed < 0 and is_on_floor():
				velocity.y = falling_speed
				falling_speed = 0
		$LegCollision/Slide.target_position.x = 50 * velocity.x/abs(velocity.x)
	else:
		$LegCollision/Slide.target_position.x = 50 * facing
	if abs(velocity.x) < 600 or $BlockR.is_colliding() or $BlockL.is_colliding() or $LegCollision/Slide.is_colliding() or velocity.y < -1600 and !$Grounded.is_colliding() or $Blub.is_colliding():
		sliding = false
var facing_right = true
var facing = 0
var walking = false
var melee_idle
var crouching = false
var foot_stuck
var foot_distance = 0.0
var foot_position_r = 0
var foot_position_l = 0
var wait_count = 0
func animate():
	$SpriteR/Skeleton/Body/Cloth2.global_position = $SpriteR/Skeleton/Body/UpperArmL/LowerArmL.global_position
	$SpriteL/Skeleton/Body/Cloth2.global_position = $SpriteL/Skeleton/Body/UpperArmR/LowerArmR.global_position
	$SpriteR/Skeleton/Dress2.global_position = $SpriteR/Skeleton/Body/UpperLegL/LowerLegL.global_position
	$SpriteL/Skeleton/Dress2.global_position = $SpriteL/Skeleton/Body/UpperLegL/LowerLegL.global_position
	$SpriteL/Skeleton/Body/Head/Mask.visible = corruptor
	$SpriteL/Skeleton/Body/Head/Mask2.visible = !corruptor
	$SpriteR/Skeleton/Body/Head/Face/Mask.visible = corruptor
	$SpriteR/Skeleton/Body/Head/Face/Mask2.visible = !corruptor
	$SpriteR/Skeleton/Body/Head/Face2/Mask.visible = corruptor
	$SpriteR/Skeleton/Body/Head/Face2/Mask2.visible = !corruptor
	$SpriteL/Skeleton/Body/BodySprite/BSword.visible = corruptor
	$SpriteL/Skeleton/Body/BodySprite2/BSword.visible = corruptor
	$SpriteR/Skeleton/Body/BodySprite/BSword.visible = corruptor
	$SpriteR/Skeleton/Body/BodySprite2/BSword.visible = corruptor
	$SpriteL/Skeleton/Body/BodySprite/CBlade.visible = !corruptor
	$SpriteR/Skeleton/Body/BodySprite/CBlade.visible = !corruptor
	$SpriteL/Skeleton/Body/BodySprite2/CBlade.visible = !corruptor
	$SpriteR/Skeleton/Body/BodySprite2/CBlade.visible = !corruptor
	if walking and !sliding:
		$SpriteR/Skeleton/Body/UpperLegR.position.x = 0
		$SpriteR/Skeleton/Body/UpperLegL.position.x = 0
		$SpriteL/Skeleton/Body/UpperLegR.position.x = 0
		$SpriteL/Skeleton/Body/UpperLegL.position.x = 0
		$SpriteR/Skeleton/Body/UpperArmR.position.x = 0
		$SpriteR/Skeleton/Body/UpperArmL.position.x = 0
		$SpriteL/Skeleton/Body/UpperArmR.position.x = 0
		$SpriteL/Skeleton/Body/UpperArmL.position.x = 0
		$SpriteR/Skeleton/Body/BodySprite.hide()
		$SpriteR/Skeleton/Body/BodySprite2.show()
		$SpriteL/Skeleton/Body/BodySprite.hide()
		$SpriteL/Skeleton/Body/BodySprite2.show()
		$SpriteR/Skeleton/Body/Head/Face.hide()
		$SpriteR/Skeleton/Body/Head/Face2.show()
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor6.frame = 23
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor7.frame = 23
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor8.frame = 23
		$SpriteR/Skeleton/Body/UpperArmR/Armor.frame = 21
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2.frame = 26
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2/Armor3.hide()
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 50
		$SpriteL/Skeleton/Body/UpperLegR/LegR.frame = 51
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor6.frame = 23
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor7.frame = 23
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor8.frame = 23
	else:
		$SpriteR/Skeleton/Body/UpperLegR.position.x = -18
		$SpriteR/Skeleton/Body/UpperLegL.position.x = 19
		$SpriteL/Skeleton/Body/UpperLegR.position.x = 19
		$SpriteL/Skeleton/Body/UpperLegL.position.x = -18
		$SpriteR/Skeleton/Body/UpperArmR.position.x = -25
		$SpriteR/Skeleton/Body/UpperArmL.position.x = 23
		$SpriteL/Skeleton/Body/UpperArmR.position.x = -31
		$SpriteL/Skeleton/Body/UpperArmL.position.x = 22
		$SpriteR/Skeleton/Body/BodySprite.show()
		$SpriteR/Skeleton/Body/BodySprite2.hide()
		$SpriteL/Skeleton/Body/BodySprite.show()
		$SpriteL/Skeleton/Body/BodySprite2.hide()
		$SpriteR/Skeleton/Body/Head/Face.show()
		$SpriteR/Skeleton/Body/Head/Face2.hide()
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor6.frame = 22
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor7.frame = 22
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor8.frame = 22
		$SpriteR/Skeleton/Body/UpperArmR/Armor.frame = 20
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2.frame = 24
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2/Armor3.show()
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 48
		$SpriteL/Skeleton/Body/UpperLegR/LegR.frame = 49
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor6.frame = 22
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor7.frame = 22
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor8.frame = 22
	$Weapon.walk = walking
	facing_right = $Weapon.facing_right
	facing = $Weapon.facing
	if facing_right:
		$SpriteR.show()
		$SpriteL.hide()
		$CakeCollision.scale.x = 1
	else:
		$SpriteR.hide()
		$SpriteL.show()
		$CakeCollision.scale.x = -1
	if $AniLeg.current_animation == "AimMove":
		$AniLeg.speed_scale = 1 + $Weapon.aim_speed
	else:
		$AniLeg.speed_scale = 1
	if $Grounded.is_colliding() and !sliding and !(slash and slash_count > 3 or evading or slash_dash or $Melee/Kick.time_left > 0) and !($Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding())):
		$AniLeg.playback_default_blend_time = 0.25 * Setting.inverse
		if $Weapon.switch_count == 0 or $Weapon.bare:
			$AniArm.playback_default_blend_time = 0.25 * Setting.inverse
		else:
			$AniArm.play("Void")
			$AniArm.playback_default_blend_time = 0
		if crouching:
			walking = false
			if abs(velocity.x) > 100:
				$AniBody.play("CrouchMove")
			if velocity.x > 300:
				$AniLeg.play("CrouchMove")
			elif velocity.x < -300:
				$AniLeg.play_backwards("CrouchMove")
			if velocity.x > 100 and velocity.x < 300:
				$AniLeg.play("CrouchAim")
			elif velocity.x < -100 and velocity.x > -300:
				$AniLeg.play_backwards("CrouchAim")
			if igniting:
				if abs(velocity.x) > 100:
					$AniArm.play("HurtCrouchMove")
				else:
					$AniArm.play("HurtCrouch")
		else:
			if Key.righting and !Key.lefting and !dashing:
				if $GroundTimer.time_left > 0.3 and velocity.x < 200:
					$AniLeg.play("Ground")
				elif velocity.x > 1600 and dash_right:
					$AniArm.play("Run")
					$AniBody.play("Run")
					$AniLeg.play("Run")
					walking = true
				elif velocity.x > 800 and velocity.x < 1600:
					walking = true
					$AniLeg.play("Walk")
					$AniBody.play("Walk")
					if $Weapon.bare:
						$AniArm.play("Walk")
				else:
					walking = false
					if $Weapon.bare:
						$AniBody.play("Stand")
						if melee_idle:
							$AniArm.play("Void")
						else:
							$AniArm.play("Stand")
					if slash:
						$AniBody.play("Void")
						$AniArm.play("Void")
						$AniBody.playback_default_blend_time = 0
					else:
						if igniting:
							$AniBody.play("Hurt")
							$AniArm.play("Hurt")
						elif $GroundTimer.time_left > 0:
							$AniBody.play("Ground")
						else:
							$AniBody.play("Stand")
						$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
					if velocity.x > 400 and velocity.x < 800:
						$AniLeg.play("Use")
					if velocity.x > 100 and velocity.x < 400:
						$AniLeg.play("AimMove")
			elif Key.lefting and !Key.righting and !dashing:
				if $GroundTimer.time_left > 0.3 and velocity.x > -200:
					$AniLeg.play("Ground")
				elif velocity.x < -1600 and dash_left:
					$AniArm.play("Run")
					$AniBody.play("Run")
					$AniLeg.play("Run")
					walking = true
				elif velocity.x < -800 and velocity.x > -1600:
					walking = true
					$AniLeg.play("Walk")
					$AniBody.play("Walk")
					if $Weapon.bare:
						$AniArm.play("Walk")
				else:
					walking = false
					if $Weapon.bare:
						$AniBody.play("Stand")
						if melee_idle:
							$AniArm.play("Void")
						else:
							$AniArm.play("Stand")
					if slash:
						$AniBody.play("Void")
						$AniArm.play("Void")
						$AniBody.playback_default_blend_time = 0
					else:
						if igniting:
							$AniBody.play("Hurt")
							$AniArm.play("Hurt")
						elif $GroundTimer.time_left > 0:
							$AniBody.play("Ground")
						else:
							$AniBody.play("Stand")
						$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
					if velocity.x < -400 and velocity.x > -800:
						$AniLeg.play_backwards("Use")
					if velocity.x < -100 and velocity.x > -400:
						$AniLeg.play_backwards("AimMove")
			elif dashing:
				$AniArm.play("Dash")
				$AniBody.play("Dash")
				$AniLeg.play("Dash")
				walking = false
			else:
				if abs(velocity.x) > 200 and !$GroundTimer.time_left > 0:
					$AniBody.play("FallMove")
					$AniLeg.play("Stop")
				elif $GroundTimer.time_left > 0:
					$AniBody.play("Ground")
					$AniLeg.play("Ground")
				walking = false
		if abs(velocity.x) < 200:
			walking = false
			if crouching:
				$AniBody.play("Crouch")
				if $Weapon.bare:
					$AniArm.play("Crouch")
			else:
				if $Weapon.bare:
					$AniBody.play("Void")
					if melee_idle:
						$AniArm.play("Void")
					else:
						$AniArm.play("Stand")
				if slash:
					$AniBody.play("Void")
					$AniArm.play("Void")
					$AniBody.playback_default_blend_time = 0
				else:
					if igniting:
						$AniBody.play("Hurt")
						$AniArm.play("Hurt")
					else:
						$AniBody.play("Stand")
					$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
			if abs(int(foot_distance)) > foot_distance/5 + 5:
				if $FootCastR.is_colliding():
					$SpriteR/Base/LegR.position.x = $FootCastR.position.x
					$SpriteR/Base/LegR.global_position.y = $FootCastR.get_collision_point().y - 12
					$SpriteL/Base/LegL.position.x = $FootCastR.position.x
					$SpriteL/Base/LegL.global_position.y = $FootCastR.get_collision_point().y - 12
				if $FootCastL.is_colliding():
					$SpriteR/Base/LegL.position.x = $FootCastL.position.x
					$SpriteR/Base/LegL.global_position.y = $FootCastL.get_collision_point().y - 12
					$SpriteL/Base/LegR.position.x = $FootCastL.position.x
					$SpriteL/Base/LegR.global_position.y = $FootCastL.get_collision_point().y - 12
				foot_stuck = true
				if abs(int(foot_distance)) > abs(int(foot_distance))/5 + foot_distance/2:
					if facing_right:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-54,0.1 * Setting.tick)
						$FootCastL.position.x = lerpf($FootCastL.position.x,32,0.1 * Setting.tick)
					else:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-32,0.1 * Setting.tick)
						$FootCastL.position.x = lerpf($FootCastL.position.x,54,0.1 * Setting.tick)
				else:
					if facing_right:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-56,0.1 * Setting.tick)
						$FootCastL.position.x = lerpf($FootCastL.position.x,64,0.1 * Setting.tick)
					else:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-64,0.1 * Setting.tick)
						$FootCastL.position.x = lerpf($FootCastL.position.x,56,0.1 * Setting.tick)
			else:
				if crouching:
					$AniLeg.play("Crouch")
				else:
					if $Weapon.bare and !slash:
						$AniLeg.play("Chill")
					else:
						$AniLeg.play("Stand")
		else:
			foot_stuck = false
	elif !$Grounded.is_colliding() and !sliding and !crouching and !slash and !break_charge > 0 and !($Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding())):
		walking = false
		$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
		$AniLeg.playback_default_blend_time = 0.25 * Setting.inverse
		if $Weapon.bare and abs(velocity.x) < 1600 and !$ClimbTimer.time_left > 0:
			$AniArm.play("Jump")
			if !melee_idle:
				$AniArmRotateL.play("Down")
		if abs(velocity.x) < 200 and count_jump > 0 or velocity.y < -1600 and count_jump > 0 :
			$AniBody.play("Jump")
		if velocity.y < -1600 and abs(velocity.x) < 800 and count_jump >= jump_time - 1:
			$AniLeg.play("Jump")
		if velocity.y < -1600 and velocity.x > 800 and velocity.x < 1600:
			$AniLeg.play("JumpMoveR")
		if velocity.y < -1600 and velocity.x < -800 and velocity.x > -1600:
			$AniLeg.play("JumpMoveL")
		if velocity.y < -1600 and !dashing and count_jump < jump_time - 1 and !fly:
			$AniBody.play("JumpBoost")
		elif fly:
			$AniBody.play("Fly")
		if velocity.y > 1600 and abs(velocity.x) < 200:
			$AniLeg.play("Fall")
		if velocity.y > 1600 and velocity.x > 800 and velocity.x < 1600:
			$AniLeg.play("FallMoveR")
			$AniBody.play("FallMove")
		if velocity.y > 1600 and velocity.x < -800 and velocity.x > -1600:
			$AniLeg.play("FallMoveL")
			$AniBody.play("FallMove")
		if abs(velocity.x) > 2000 and !dashing and velocity.y > -1600:
			$AniBody.play("AirFast")
			if $Weapon.switch_count == 0:
				$AniArm.play("Air")
		if abs(velocity.x) > 1600 and !dashing:
			$AniLeg.play("Jump_2")
		if dashing:
			$AniArm.play("Dash")
			$AniBody.play("Dash")
			$AniLeg.play("Dash")
		if climb or $ClimbTimer.time_left > 0:
			if climb:
				$AniArm.play("ClimbHold")
			else:
				$AniArm.play("Climb")
			$AniArm.playback_default_blend_time = 0 * Setting.inverse
			$AniBody.play("Stand")
			$AniLeg.play("Jump")
		else:
			$AniArm.playback_default_blend_time = 0.25 * Setting.inverse
	elif sliding:
		walking = false
		$AniArm.playback_default_blend_time = 0.25 * Setting.inverse
		if $Grounded.is_colliding():
			if $GroundTimer.time_left > 0:
				$AniLeg.playback_default_blend_time = 0.1 * Setting.inverse
				$AniBody.playback_default_blend_time = 0.1 * Setting.inverse
				$AniLeg.play("SlideGround")
				$AniBody.play("SlideGround")
			else:
				$AniLeg.playback_default_blend_time = 0.25 * Setting.inverse
				$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
				$AniLeg.play("Slide")
				$AniBody.play("Slide")
		else:
			$AniLeg.playback_default_blend_time = 0.25 * Setting.inverse
			$AniBody.playback_default_blend_time = 0.25 * Setting.inverse
			$AniLeg.play("SlideAir")
			$AniBody.play("Slide")
		if $Weapon.bare:
			$AniArm.play("Air")
	elif slash:
		walking = false
		$AniBody.playback_default_blend_time = 0
		$AniLeg.playback_default_blend_time = 0.25 * Setting.inverse
		$AniBody.play("Void")
		$AniLeg.play("Void")
	elif $Blub.is_colliding() and !($Grounded.is_colliding() and !$Breath.is_colliding()):
		walking = false
		$AniBody.playback_default_blend_time = 0.5 * Setting.inverse
		$AniLeg.playback_default_blend_time = 0.5 * Setting.inverse
		if (Key.righting and !Key.lefting and velocity.x > 200 or Key.lefting and !Key.righting and velocity.x < -200) and !dashing:
			if swim:
				$AniBody.play("Swim")
				$AniLeg.play("Swim")
			else:
				$AniBody.play("Swim_2")
				$AniLeg.play("Swim_2")
		else:
			if Key.fly and !Key.dive and $Breath.is_colliding() and !dashing:
				if swim:
					$AniBody.play("FloatUp")
					$AniLeg.play("Swim_V")
				else:
					$AniBody.play("FloatUp_2")
					$AniLeg.play("Swim_V_2")
			elif !Key.fly and Key.dive and !$Grounded.is_colliding() and !dashing:
				if swim:
					$AniBody.play_backwards("Float_2")
					$AniLeg.play_backwards("Swim_V_2")
				else:
					$AniBody.play_backwards("Float")
					$AniLeg.play_backwards("Swim_V")
			else:
				if dashing:
					$AniArm.play("Dash")
					$AniBody.play("Dash")
					$AniLeg.play("Dash")
				else:
					if swim:
						$AniBody.play("Float")
						$AniLeg.play("Float")
					else:
						$AniBody.play("Float_2")
						$AniLeg.play("Float_2")
	if !slash:
		$AniArmRotateR.play("Up")
		if $Weapon.bare and crouching or $Weapon.throwing and !$Weapon/Sentry.time_left > 0 or $Weapon/Armor.time_left > 0.1 or $Weapon/Heal.time_left > 0.1 or igniting and crouching:
			$AniArmRotateL.play("Down")
		elif $Weapon.facing_up and !melee_idle:
			$AniArmRotateL.play("Up")
		else:
			if (($SpriteR/Base/TayL.global_position.x < $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 10 and facing_right) or ($SpriteL/Base/TayL.global_position.x > $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 10 and !facing_right)):
				$AniArmRotateL.play("Down")
			elif (($SpriteR/Base/TayL.global_position.x > $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 20 and facing_right) or ($SpriteL/Base/TayL.global_position.x < $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 20 and !facing_right)):
				$AniArmRotateL.play("Up")
	if slash or $Weapon.fire_delay or $Weapon.reloading or $Weapon.switching or $Weapon.mode_changing or $Weapon.block or $Weapon.aim or abs(velocity.x) > 200 or abs(velocity.y) > 200 or Key.up or Key.down or $Hurt.time_left > 0 or hp < 20 or igniting:
		wait_count = 120
	else:
		wait_count -= Setting.tick
	if wait_count < 1:
		$Weapon.wait = true
	else:
		$Weapon.wait = false
	if igniting and corruptor:
		if $Weapon/Ignitor.time_left > 0:
			$Weapon/Igniter/Ani.play("Deploy")
		else:
			$Weapon/Igniter/Ani.play("Process")
	else:
		$Weapon/Igniter/Ani.play("Off")
var focus = false
var eyes_speed = 0
var eyes_distance = 0
var face_state = 0
var blink = 0
var face_state_count = 0
var eyes_check = Vector2()
func emote():
	$SpriteL/Skeleton/Body/Head/Face/Lash.position.y = $SpriteR/Skeleton/Body/Head/Face2/Lash.position.y
	$SpriteL/Skeleton/Body/Head/Face/Lash.frame = $SpriteR/Skeleton/Body/Head/Face2/Lash.frame
	$SpriteL/Skeleton/Body/Head/Face/Brow.position.x = -$SpriteR/Skeleton/Body/Head/Face2/Brow.position.x
	$SpriteL/Skeleton/Body/Head/Face/Brow.position.y = $SpriteR/Skeleton/Body/Head/Face2/Brow.position.y
	$SpriteL/Skeleton/Body/Head/Face/Brow.rotation = -$SpriteR/Skeleton/Body/Head/Face2/Brow.rotation
	$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.x = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.x,clampf($BodyPos/HeadPos/EyesPos.position.x/64,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.y = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.y,clampf($BodyPos/HeadPos/EyesPos.position.y/eyes_distance,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.x = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.x,clampf($BodyPos/HeadPos/EyesPos.position.x/64,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.y = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.y,clampf($BodyPos/HeadPos/EyesPos.position.y/eyes_distance,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.x = lerpf($SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.x,clampf($BodyPos/HeadPos/EyesPos.position.x/64,-6,1),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.y = lerpf($SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.y,clampf($BodyPos/HeadPos/EyesPos.position.y/eyes_distance,-6,6),eyes_speed)
	$SpriteL/Skeleton/Body/Head/Face/Eye/Pupil.position.x = -$SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.x
	$SpriteL/Skeleton/Body/Head/Face/Eye/Pupil.position.y = $SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.position.y
	$SpriteR/Skeleton/Body/Head/Face2/Eye/Pupil.scale = $SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.scale
	$SpriteL/Skeleton/Body/Head/Face/Eye/Pupil.scale = $SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.scale
	if $Weapon.aim:
		eyes_speed = 0.2 * Setting.tick
		eyes_distance = 128
		face_state = 0
		$BodyPos/HeadPos/EyesPos.position.x = abs($Weapon/CrossHair.position.x)
		$BodyPos/HeadPos/EyesPos.position.y = $Weapon/CrossHair.position.y
	elif $Weapon.reloading or $Weapon.switching:
		eyes_speed = 0.5 * Setting.tick
		eyes_distance = 64
		face_state = 0
		if $Weapon.current_gun == 30:
			$BodyPos/HeadPos/EyesPos.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		else:
			$BodyPos/HeadPos/EyesPos.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
	elif $Weapon.fire_delay or Key.up or Key.down or sliding or (slash or $Hurt.time_left > 0 or hp < 20) and !$Melee/Target.is_colliding():
		eyes_distance = 64
		eyes_speed = 0.5
		face_state = 0
		$BodyPos/HeadPos/EyesPos.position = $Weapon/Rotation/Recoil/Position.position * 64
	else:
		if $Weapon.wait:
			eyes_distance = 64
			eyes_speed = 0.2
			if face_state_count > 0:
				face_state_count -= Setting.tick
			else:
				face_state = randi_range(0,4)
				if face_state < 3:
					face_state_count = randi_range(60, 120)
				else:
					face_state_count = randi_range(30, 60)
				eyes_check = Vector2(randf_range(-300,300),randf_range(-300,300))
			if face_state == 0:
				$BodyPos/HeadPos/EyesPos.position = Vector2(300,-97)
			elif face_state == 1:
				eyes_speed = 0.2
				eyes_distance = 128
				$BodyPos/HeadPos/EyesPos.global_position = $Weapon/CrossHair.global_position
			elif face_state == 2 and $Melee/Target.is_colliding() and $Melee/Target.get_collider(0) != null:
				$BodyPos/HeadPos/EyesPos.position.x = to_local($Melee/Target.get_collision_point(0)).x * facing
				$BodyPos/HeadPos/EyesPos.position.y = to_local($Melee/Target.get_collision_point(0)).y
			else:
				$BodyPos/HeadPos/EyesPos.position = eyes_check
		else:
			eyes_distance = 64
			eyes_speed = 0.5
			$BodyPos/HeadPos/EyesPos.position = Vector2(300,-97)
	if $Hurt.time_left > 0 or hp < 20:
		$AniFace.play("Hurt")
	elif $Weapon.fire_delay or slash and !$Hurt.time_left > 0:
		$AniFace.play("Shoot")
	elif ($Weapon.aim or Key.up or Key.down and !crouching) and !$Weapon.fire_delay and !$Hurt.time_left > 0 and hp > 50:
		$AniFace.play("Aim")
	else:
		if blink > 0:
			blink -= Setting.tick
		else:
			blink = randi_range(100,200)
		if blink > 5:
			$AniFace.play("Ready")
		else:
			$AniFace.play("Blink")
	if $Hurt.time_left > 0:
		$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = randi_range(32,39)
		$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = randi_range(32,39)
	else:
		if hp == 100:
			$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = 1
			$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = 1
		else:
			if hp > 25:
				if hp > 50:
					if hp > 75:
						$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = randi_range(8,15)
						$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = randi_range(8,15)
					else:
						$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = randi_range(16,23)
						$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = randi_range(16,23)
				else:
					$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = randi_range(24,31)
					$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = randi_range(24,31)
			else:
				$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR/Class.frame = randi_range(32,39)
				$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL/Class.frame = randi_range(32,39)

func part():
	$Weapon.position.x = $GunPos.position.x * facing
	$Weapon.tolerance_rotate = $GunPos.rotation
	$Grounded.position = $LegCollision.position
	$Ouch.position.y = $LegCollision.position.y - 200
	$Ouch.position.x = $BodyPos.position.x * facing
	$Ouch.enabled = sliding or dash_right or dash_left or crouching
	$HitBox/Leg.position.y = $LegCollision.position.y - 42
	$HitBox/Body.global_position = $BaseCollision.global_position
	$HitBox/Body.rotation = $BaseCollision.rotation
	$Climb.position.x = (60 + $BodyPos.position.x) * facing
	$CantClimb.position.x = (60 + $BodyPos.position.x) * facing
	$BaseCollision.position = ($BodyPos.position + $BodyPos2.position + Vector2(0,35)) * Vector2(facing,1)
	$BaseCollision.global_rotation = $SpriteR/Skeleton/Body/BodySprite.global_rotation
	$BaseCollision.disabled = $Sit.is_colliding()
	$Block.enabled = !$Weapon.bare
	$Effect/JetR.z_index = -3 * facing
	$Effect/JetL.z_index = -3 * facing
	$Effect/Tracker1.z_index = -3 * facing
	$Effect/Tracker2.z_index = -3 * facing
	$Effect/Tracker1.emitting = count_jump == 0
	$Effect/Tracker2.emitting = count_jump == 0
	$SpriteR/Base/Body.position.x = ($BodyPos.position.x + $BodyPos2.position.x) * facing
	$SpriteL/Base/Body.position.x = ($BodyPos.position.x + $BodyPos2.position.x) * facing
	$SpriteR/Base/Body/Head.position.x = ($BodyPos/HeadPos.position.x + $HeadPos2.position.x) * facing
	$SpriteL/Base/Body/Head.position.x = ($BodyPos/HeadPos.position.x + $HeadPos2.position.x) * facing
	$SpriteR/Base/Body.position.y = $BodyPos.position.y
	$SpriteL/Base/Body.position.y = $BodyPos.position.y
	$SpriteR/Base/Body/Head.position.y = $BodyPos/HeadPos.position.y
	$SpriteL/Base/Body/Head.position.y = $BodyPos/HeadPos.position.y
	$SpriteR/Skeleton/Body/UpperLegR.show_behind_parent = walking
	$SpriteR/Skeleton/Body/UpperLegR/LegR.show_behind_parent = crouching
	if corruptor:
		$SpriteR/Skeleton/Body/BodySprite/BSword/Rigid/BSheath/BSwordS.modulate.a = 1.0 - $Melee/BSword.modulate.a
		$SpriteR/Skeleton/Body/BodySprite/BSword/Rigid/BSheath/BSwordL.modulate.a = 1.0 - $Melee/BSword2.modulate.a
		$SpriteR/Skeleton/Body/BodySprite2/BSword/Rigid/BSheath/BSwordS.modulate.a = 1.0 - $Melee/BSword.modulate.a
		$SpriteR/Skeleton/Body/BodySprite2/BSword/Rigid/BSheath/BSwordL.modulate.a = 1.0 - $Melee/BSword2.modulate.a
		$SpriteL/Skeleton/Body/BodySprite/BSword/Rigid/BSheath/BSwordS.modulate.a = 1.0 - $Melee/BSword.modulate.a
		$SpriteL/Skeleton/Body/BodySprite/BSword/Rigid/BSheath/BSwordL.modulate.a = 1.0 - $Melee/BSword2.modulate.a
		$SpriteL/Skeleton/Body/BodySprite2/BSword/Rigid/BSheath/BSwordS.modulate.a = 1.0 - $Melee/BSword.modulate.a
		$SpriteL/Skeleton/Body/BodySprite2/BSword/Rigid/BSheath/BSwordL.modulate.a = 1.0 - $Melee/BSword2.modulate.a
	else:
		$SpriteL/Skeleton/Body/BodySprite/CBlade/Rigid/CSheath/CBlade.modulate.a = 1.0 - $Melee/CBlade.modulate.a
		$SpriteL/Skeleton/Body/BodySprite/CBlade/Rigid/CSheath/CBlade2.modulate.a = 1.0 - $Melee/CBlade2.modulate.a
		$SpriteL/Skeleton/Body/BodySprite2/CBlade/Rigid/CSheath/CBlade.modulate.a = 1.0 - $Melee/CBlade.modulate.a
		$SpriteL/Skeleton/Body/BodySprite2/CBlade/Rigid/CSheath/CBlade2.modulate.a = 1.0 - $Melee/CBlade2.modulate.a
		$SpriteR/Skeleton/Body/BodySprite/CBlade/Rigid/CSheath/CBlade.modulate.a = 1.0 - $Melee/CBlade.modulate.a
		$SpriteR/Skeleton/Body/BodySprite/CBlade/Rigid/CSheath/CBlade2.modulate.a = 1.0 - $Melee/CBlade2.modulate.a
		$SpriteR/Skeleton/Body/BodySprite2/CBlade/Rigid/CSheath/CBlade.modulate.a = 1.0 - $Melee/CBlade.modulate.a
		$SpriteR/Skeleton/Body/BodySprite2/CBlade/Rigid/CSheath/CBlade2.modulate.a = 1.0 - $Melee/CBlade2.modulate.a
	if $Weapon.current_gun == 15:
		$Weapon.position.y = $GunPos.position.y + 26
	else:
		$Weapon.position.y = $GunPos.position.y
	if $Weapon.aim or $Weapon.fire_delay or $Weapon.reloading or Key.up or Key.down:
		$BodyPos2.global_position.x = $Weapon/Rotation/Recoil/Body.global_position.x - $Weapon.position.x
		$HeadPos2.global_position.x = $Weapon/Head/Rotate.global_position.x - $Weapon.position.x
	else:
		$BodyPos2.position.x = lerpf($BodyPos2.position.x,0,0.2 * Setting.tick)
		$HeadPos2.position.x = lerpf($HeadPos2.position.x,0,0.2 * Setting.tick)
	if $Grounded.is_colliding() and !sliding and !foot_stuck and !dashing and !(slash and $Weapon.switch_count == 0 or break_charge > 0):
		$FootR.disabled = $Sit.is_colliding()
		$FootL.disabled = $Sit.is_colliding()
		if facing_right:
			$FootR.global_position.x = $SpriteR/Base/LegR.global_position.x
			$FootR.global_position.y = $SpriteR/Base/LegR.global_position.y - 38
			$FootL.global_position.x = $SpriteR/Base/LegL.global_position.x
			$FootL.global_position.y = $SpriteR/Base/LegL.global_position.y - 38
		else:
			$FootR.global_position.x = $SpriteL/Base/LegR.global_position.x
			$FootR.global_position.y = $SpriteL/Base/LegR.global_position.y - 38
			$FootL.global_position.x = $SpriteL/Base/LegL.global_position.x
			$FootL.global_position.y = $SpriteL/Base/LegL.global_position.y - 38
	elif slash and $Weapon.switch_count == 0 and !sliding or break_charge > 0:
		$FootR.disabled = $Sit.is_colliding()
		$FootL.disabled = $Sit.is_colliding()
		$FootR.global_position.x = $Melee/LegR.global_position.x
		$FootR.global_position.y = $Melee/LegR.global_position.y - 38
		$FootL.global_position.x = $Melee/LegL.global_position.x
		$FootL.global_position.y = $Melee/LegL.global_position.y - 38
	else:
		$FootR.disabled = true
		$FootL.disabled = true
	if sliding:
		$CakeCollision.disabled = true
		if !$Weapon.aim and !$Weapon.fire_delay and !Key.up and !Key.down:
			$Weapon.slide = true
		else:
			$Weapon.slide = false
	elif crouching:
		$CakeCollision.disabled = true
		$Weapon.slide = false
	else:
		$CakeCollision.disabled = false
		$Weapon.slide = false
	if !$Weapon.bare and !($Weapon.switch_count == 0 and !$Weapon.throwing) and !igniting and !($Melee/Slash_delay.time_left > 0.2 and slash_count > 3 or break_charge > 12 or evading):
		$SpriteR/Base/TayR.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		$SpriteR/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
		$SpriteL/Base/TayR.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		$SpriteL/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
	if !$Weapon.bare and !$Weapon.switch_count == 0 and !igniting and !($Melee/Slash_delay.time_left > 0.2 and !$Melee/Kick.time_left > 0 or break_charge > 0) and !climb and !$ClimbTimer.time_left > 0 or $Weapon.throwing:
		$SpriteR/Base/TayL.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
		$SpriteR/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
		$SpriteL/Base/TayL.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
		$SpriteL/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
	if $Weapon.bare and slash:
		$SpriteR/Base/TayR.global_position = $Melee/HandR.global_position
		$SpriteR/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
		$SpriteL/Base/TayR.global_position = $Melee/HandR.global_position
		$SpriteL/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
		$SpriteR/Base/TayL.global_position = $Melee/HandL.global_position
		$SpriteR/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
		$SpriteL/Base/TayL.global_position = $Melee/HandL.global_position
		$SpriteL/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
	if slash:
		if $Weapon.bare or $Weapon.switch_count == 0 or slash_delay and slash_count > 3 and !$Melee/Kick.time_left > 0 or break_charge > 12 or evading or slash_dash:
			$SpriteR/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteR/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
			$SpriteL/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteL/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
		else:
			if !$Weapon.bare:
				$SpriteR/Base/TayR.global_position.x = lerpf($SpriteR/Base/TayR.global_position.x,$Weapon/Rotation/Recoil/Body/ArmR.global_position.x,0.5 * Setting.tick)
				$SpriteR/Base/TayR.global_position.y = lerpf($SpriteR/Base/TayR.global_position.y,$Weapon/Rotation/Recoil/Body/ArmR.global_position.y,0.5 * Setting.tick)
				$SpriteR/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
				$SpriteL/Base/TayR.global_position.x = lerpf($SpriteL/Base/TayR.global_position.x,$Weapon/Rotation/Recoil/Body/ArmR.global_position.x,0.5 * Setting.tick)
				$SpriteL/Base/TayR.global_position.y = lerpf($SpriteL/Base/TayR.global_position.y,$Weapon/Rotation/Recoil/Body/ArmR.global_position.y,0.5 * Setting.tick)
				$SpriteL/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
		if $Weapon.bare or $Weapon.switch_count == 0 or slash_delay and !$Melee/Kick.time_left > 0:
			$SpriteR/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteR/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
			$SpriteL/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteL/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
		else:
			if !$Weapon.bare:
				$SpriteR/Base/TayL.global_position.x = lerpf($SpriteR/Base/TayL.global_position.x,$Weapon/Rotation/Recoil/Body/ArmL.global_position.x,0.5 * Setting.tick)
				$SpriteR/Base/TayL.global_position.y = lerpf($SpriteR/Base/TayL.global_position.y,$Weapon/Rotation/Recoil/Body/ArmL.global_position.y,0.5 * Setting.tick)
				$SpriteR/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
				$SpriteL/Base/TayL.global_position.x =  lerpf($SpriteL/Base/TayL.global_position.x,$Weapon/Rotation/Recoil/Body/ArmL.global_position.x,0.5 * Setting.tick)
				$SpriteL/Base/TayL.global_position.y =  lerpf($SpriteL/Base/TayL.global_position.y,$Weapon/Rotation/Recoil/Body/ArmL.global_position.y,0.5 * Setting.tick)
				$SpriteL/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
		if slash_count > 3 or slash_count < 4 and !$Grounded.is_colliding() or break_charge > 0 or evading or slash_dash or $Melee/Kick.time_left > 0:
			if $Grounded.is_colliding() or break_charge > 0 and !corruptor:
				$SpriteR/Base/LegR.global_position = $Melee/LegR.global_position
				$SpriteR/Base/LegL.global_position = $Melee/LegL.global_position
				$SpriteL/Base/LegR.global_position = $Melee/LegR.global_position
				$SpriteL/Base/LegL.global_position = $Melee/LegL.global_position
			else:
				$SpriteR/Base/LegR.global_position = $Melee/LegRAir.global_position
				$SpriteR/Base/LegL.global_position = $Melee/LegLAir.global_position
				$SpriteL/Base/LegR.global_position = $Melee/LegRAir.global_position
				$SpriteL/Base/LegL.global_position = $Melee/LegLAir.global_position
	else:
		if melee_idle:
			$SpriteR/Base/LegR.global_position = $Melee/LegR.global_position
			$SpriteR/Base/LegL.global_position = $Melee/LegL.global_position
			$SpriteL/Base/LegR.global_position = $Melee/LegR.global_position
			$SpriteL/Base/LegL.global_position = $Melee/LegL.global_position
			$SpriteR/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteR/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
			$SpriteL/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteL/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
			$SpriteR/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteR/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
			$SpriteL/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteL/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
	if $Grounded.is_colliding() and !sliding and !dashing:
		foot_position_r = lerpf(foot_position_r,$FootCastR.get_collision_point().y - global_position.y,0.1 * Setting.tick)
		foot_position_l = lerpf(foot_position_l,$FootCastL.get_collision_point().y - global_position.y,0.1 * Setting.tick)
		foot_distance = clampf(foot_position_r - foot_position_l,-60,60)
		if abs(velocity.x) < 200 and !(slash and slash_count > 3):
			if abs(int(foot_distance)) > foot_distance/5 + 5:
				if abs(int(foot_distance)) > foot_distance/5 + 25:
					if crouching:
						$LegCollision.position.y = lerpf($LegCollision.position.y,60 - abs(int(foot_distance))/4,0.2 * Setting.tick)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,142 - abs(int(foot_distance))/4,0.2 * Setting.tick)
				else:
					if crouching:
						$LegCollision.position.y = lerpf($LegCollision.position.y,90 - abs(int(foot_distance))/4,0.2 * Setting.tick)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,146 - abs(int(foot_distance))/4,0.2 * Setting.tick)
			else:
				if crouching:
					$LegCollision.position.y = lerpf($LegCollision.position.y,60,0.2 * Setting.tick)
				else:
					if $Weapon.bare and !slash and !melee_idle:
						$LegCollision.position.y = lerpf($LegCollision.position.y,158,0.2 * Setting.tick)
					elif slash or melee_idle:
						$LegCollision.position.y = lerpf($LegCollision.position.y,$Melee/LegR.position.y - 32.5,0.5 * Setting.tick)
					elif $GroundTimer.time_left > 0:
						$LegCollision.position.y = 120
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,140,0.2 * Setting.tick)
		else:
			if slash and slash_count > 3 or melee_idle:
				$LegCollision.position.y = lerpf($LegCollision.position.y,$Melee/LegR.position.y - 32.5,0.5 * Setting.tick)
			elif crouching:
				$LegCollision.position.y = lerpf($LegCollision.position.y,70,0.1 * Setting.tick)
			elif $GroundTimer.time_left > 0:
				$LegCollision.position.y = 120
			else:
				$LegCollision.position.y = lerpf($LegCollision.position.y,130,0.1 * Setting.tick)
	else:
		foot_distance = 0
		foot_position_r = 0
		foot_position_l = 0
		if sliding:
			if $GroundTimer.time_left > 0:
				$LegCollision.position.y = 39
			else:
				$LegCollision.position.y = lerpf($LegCollision.position.y,54,0.2 * Setting.tick)
		elif dash_left and !sliding or dash_right and !sliding:
			if dashing:
				$LegCollision.position.y = 90
			elif $Ouch.is_colliding() and abs(velocity.x) < 400 and $Grounded.is_colliding():
				crouching = true
				$LegCollision.position.y = lerpf($LegCollision.position.y,62,0.2 * Setting.tick)
			else:
				$LegCollision.position.y = 105
		else:
			$LegCollision.position.y = lerpf($LegCollision.position.y,140,0.2 * Setting.tick)
	if $Melee/Slash_delay.time_left > 0.4 and abs(velocity.x) < 1600 or break_charge > 0 or melee_idle:
		$SpriteR/Skeleton/Body/UpperArmL.z_index = $Melee/HandL.z_index * facing
		$SpriteL/Skeleton/Body/UpperArmR.z_index = $Melee/HandL.z_index * facing
	elif $Weapon.throwing or $Weapon/Armor.time_left > 0 or $Weapon/Heal.time_left > 0.1 or igniting:
		$SpriteR/Skeleton/Body/UpperArmL.z_index = 1
		$SpriteL/Skeleton/Body/UpperArmR.z_index = -1
	else:
		if (($SpriteR/Base/TayL.global_position.x < $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 10 and facing_right) or ($SpriteL/Base/TayL.global_position.x > $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 10 and !facing_right)) and ($Weapon.aim or Key.up or Key.down or $Block.is_colliding()) and !$Weapon.reloading:
			$SpriteR/Skeleton/Body/UpperArmL.z_index = 0
			$SpriteL/Skeleton/Body/UpperArmR.z_index = -1
		elif (($SpriteR/Base/TayL.global_position.x > $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 20 and facing_right) or ($SpriteL/Base/TayL.global_position.x < $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 20 and !facing_right)) or walking:
			$SpriteR/Skeleton/Body/UpperArmL.z_index = -1
			$SpriteL/Skeleton/Body/UpperArmR.z_index = 1
	if !$Weapon.bare and $Weapon.gun != null:
		$SpriteR/Skeleton/Body/UpperArmL/LowerArmL.z_index = $Weapon.gun.get_node("Body/HandL").z_index * 2
		$SpriteL/Skeleton/Body/UpperArmR/LowerArmR.z_index = $Weapon.gun.get_node("Body/HandL").z_index * -2
	
var immunity = 0
var evade = 0
var avoiding = 0
@onready var armor_chip = preload("res://Screen/Asset/Entity/Object/Piece/chip.tscn")
@onready var hitmarker = preload("res://Screen/Asset/Function/HUD/hit_marker.tscn")
@onready var sprite_r = preload("res://Screen/Asset/Entity/CloneSprite/sprite_r.tscn")
@onready var sprite_l = preload("res://Screen/Asset/Entity/CloneSprite/sprite_l.tscn")
@onready var glitch = preload("res://Screen/Asset/Entity/Effect/Glitch.tscn")
@onready var prism = preload("res://Screen/Asset/Entity/Effect/Prims1.tscn")
var clone = []

func hurt(area):
	if (area.get_parent().is_in_group("danger") or (area.get_parent().is_in_group("bullet") and !area.id == id)) and !immunity > 0:
		if dashing and !evade > 0:
			if corruptor:
				for i in 16:
					var ins = glitch.instantiate()
					ins.position = global_position
					ins.id = id
					ins.apply_impulse(Vector2(randi_range(-2000,2000), randi_range(-2000,2000)).rotated(0), Vector2())
					get_tree().get_root().call_deferred("add_child",ins)
					clone.append(ins)
				for i in 8:
					var ins = prism.instantiate()
					ins.position = global_position + Vector2(randi_range(-200,200),randi_range(-200,200))
					ins.look_at(global_position)
					ins.scale = Vector2(randf_range(0.5,1),randf_range(0.5,1))
					get_tree().get_root().call_deferred("add_child",ins)
			else:
				$Melee/Evade.restart()
				$Effect/Glitch.restart()
				$Effect/Heal.restart()
				var state = 1
				clone.clear()
				for i in 4:
					var sprite
					if facing_right:
						sprite = sprite_r.instantiate()
					else:
						sprite = sprite_l.instantiate()
					match state:
						1:
							sprite.get_node("Ani").play("Evade1")
							state = 2
						2: 
							sprite.get_node("Ani").play("Evade2")
							state = 3
						3: 
							sprite.get_node("Ani").play("Evade3")
							state = 4
						4: 
							sprite.get_node("Ani").play("Evade4")
							state = 1
					sprite.position = global_position
					sprite.id = id
					get_tree().get_root().call_deferred("add_child",sprite)
					clone.append(sprite)
			evade = 60
			immunity = 60
		else:
			if armor > 0:
				if area.get_parent().dmg >= current_armor:
					armor_break = true
					var ins = armor_chip.instantiate()
					ins.position = $Weapon.global_position
					ins.angular_velocity = 20 * facing
					ins.get_node("Smoke").restart()
					ins.apply_impulse(Vector2(randf_range(220,180) * facing, randf_range(-250,-350)).rotated(0), Vector2())
					get_tree().get_root().call_deferred("add_child",ins)
				if infantry_armor > 0:
					if area.get_parent().dmg > infantry_armor:
						armor -= infantry_armor
						immunity = 20
					else:
						armor -= area.get_parent().dmg
					infantry_armor -= area.get_parent().dmg
				else:
					if armor > area.get_parent().dmg:
						armor -= area.get_parent().dmg
					else:
						hp -= area.get_parent().dmg - armor
						armor -= armor
				$UI/BreakR.restart()
				$UI/BreakL.restart()
			else:
				hp -= area.get_parent().dmg
			if !corruptor:
				heal_cool = 120
			if !avoiding > 0 and Inventory.defender:
				earthquake()
				avoiding = 300
			$Hurt.start(1)
			$Weapon/Camera2D.shake(10,5)
		hit_position = area.get_parent().global_position
		$Weapon/HitPosition.position.y = to_local(hit_position).y/2 + 36
		$Weapon/HitPosition.look_at(hit_position)
		var ins = hitmarker.instantiate()
		ins.rotation = $Weapon/HitPosition.rotation
		add_child(ins)
		var tween = create_tween()
		tween.tween_property(ins,"modulate", Color(1,1,1,1), 0)
		tween.chain().tween_property(ins,"modulate", Color(1,1,1,0),1)
		tween.play()
		var tween2 = create_tween()
		tween2.tween_property(ins,"scale", Vector2(1.1,1.1),0.05)
		tween2.chain().tween_property(ins,"scale", Vector2(1,1),0.05)
		tween2.play()
		tween.tween_callback(ins.queue_free)
	if area.get_parent().get_parent().is_in_group("flash"):
		flash_time = 255 - (global_transform.origin.distance_to(area.global_transform.origin))/10
