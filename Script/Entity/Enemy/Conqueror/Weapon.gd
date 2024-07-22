extends Node2D

var current_recoil = 0
var facing_right = true
var facing = 1
var facing_up = true
var aim = false
var dmg = 10

var id = 0

var ammo = [0,600,0,0,0]

var lethal = [0,0]
var tactical = [5,5]
var armor = 20

var weapon = [105040000010]
var backpack = []
var cash = 1000


var perk = []
var perk_unlocked = 16
var perk_key = []
var current_perk = 1
var perk_mod_1 = []
var perk_mod_2 = []
var perk_mod_3 = []
var perk_mod_4 = []
var perk_slot = 0
var loadout_perk = 0
var item = []
var used_slot = 0
func _ready():
	id = get_parent().id
	perk.clear()
	perk.append_array(perk_mod_1)
	perk.append_array(perk_mod_2)
	perk.append_array(perk_mod_3)
	perk.append_array(perk_mod_4)
	for i in 2 - weapon.size():
		weapon.append(0)
	for i in perk:
		if i == 1:
			loadout += 1
	perk_load(perk_key)
	used_slot = 0
	if weapon[0] == 0 and weapon[1] > 0:
		weapon[0] = weapon[1]
		weapon[1] = 0
		
var right_aim = true
var tolerance_rotate = 0
var shake = 0
var unstable = 0
func active():
	switch()
	pick()
	throw()
	shoot = get_parent().fire
	shooting = get_parent().firing
func _physics_process(_delta):
	killstreak()
	if get_child(0).get_class() == "Node2D":
		weaponfunc()
		bare = false
	else:
		bare = true
	if coiling:
		if get_parent().crouching:
			current_recoil += recoil * 0.75 * Setting.inverse
			spread = randf_range(-max_spread,max_spread) * 0.75
		else:
			current_recoil += recoil * Setting.inverse
			spread = randf_range(-max_spread,max_spread)
	else:
		current_recoil = lerpf(current_recoil,0,(0.2 + aim_speed) * Setting.inverse)
		spread = lerpf(spread,0,(0.2 + aim_speed) * Setting.inverse)
	if get_parent().righting and !get_parent().lefting and !aim and !get_parent().get_node("BlockR").is_colliding():
		facing_right = true
	elif get_parent().lefting and !get_parent().righting and !aim and !get_parent().get_node("BlockL").is_colliding():
		facing_right = false
	if facing_right and get_parent().get_node("BlockR").is_colliding() and !get_parent().get_node("BlockL").is_colliding() and !aim and !melee and get_parent().get_node("Grounded").is_colliding() or facing_right and get_parent().target_dash < 0 and get_parent().slash and get_parent().slash_count > 3 and !get_parent().righting:
		if get_parent().velocity.x > 800 and !get_parent().slash:
			$Camera2D.shake(abs(get_parent().velocity.x)/100,5)
		facing_right = false
	if !facing_right and get_parent().get_node("BlockL").is_colliding() and !get_parent().get_node("BlockR").is_colliding() and !aim and !melee and get_parent().get_node("Grounded").is_colliding() or !facing_right and get_parent().target_dash > 0 and get_parent().slash and get_parent().slash_count > 3 and !get_parent().lefting:
		if get_parent().velocity.x < -800 and !get_parent().slash:
			$Camera2D.shake(abs(get_parent().velocity.x)/100,5)
		facing_right = true
	if !aim or block and facing_right and right_aim or block and !facing_right and !right_aim or block and get_parent().crouching or (abs($CrossHair.position.x) + abs($CrossHair.position.y) < 200 and !(get_parent().aim and Setting.stick_aim)):
		if get_parent().up and !reloading and !melee and !switching and !mode_changing:
			$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,deg_to_rad(-90),(0.2 + aim_speed) * Setting.inverse)
		elif get_parent().down and !reloading and !melee and !switching and !mode_changing and !get_parent().crouching:
			$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,deg_to_rad(90),(0.2 + aim_speed) * Setting.inverse)
		else:
			if facing_right:
				$Rotation.rotation = lerp_angle($Rotation.rotation,deg_to_rad(0.001),(0.2 + aim_speed) * Setting.inverse)
			else:
				$Rotation.rotation = lerp_angle($Rotation.rotation,deg_to_rad(179.999),(0.2 + aim_speed) * Setting.inverse)
	else:
		$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,$Idle/Aim.global_rotation,(0.5 + aim_speed) * Setting.inverse)
	if get_parent().alt and !melee and !reloading and !switching and !mode_changing and !(get_parent().get_node("BlockR").is_colliding() and right_aim or get_parent().get_node("BlockL").is_colliding() and !right_aim):
		aim = true
		$Label.text = str(aim)
		unstable = 0
		$Idle/Aim.look_at($CrossHair.global_position)
		if ($Rotation/Recoil/Position.global_position.x - global_position.x) > 25:
			facing_right = true
		elif ($Rotation/Recoil/Position.global_position.x - global_position.x) < -25:
			facing_right = false
		get_parent().get_node("Block").rotation = $Idle/Aim.rotation
	else:
		aim = false
		unstable = 1
		get_parent().get_node("Block").rotation = $Rotation.rotation
	right_aim = $CrossHair.position.x > 0
	shake = move_toward(shake,randf_range(-2,2),0.05)
	if facing_right:
		facing = 1
	else:
		facing = -1
	if slide or reloading or fire_delay:
		walk = false
	$Head/Rotate.position.x = $Recoil.position.x/2 * -facing
	$Head.rotation = $Rotation.rotation
	$Rotation/Recoil/Body.position.x = $Recoil.position.x/2
	$Rotation/Recoil.rotation_degrees = (current_recoil + spread) * -facing
	$Idle.position.x = ($Rotation/Recoil/Body.global_position.x - global_position.x) * facing
	if !bare and int(current_gun/10) == 0:
		$Idle/Aim.position.x = 0
	else:
		$Idle/Aim.position.x = -10 * facing
	if ($Rotation/Recoil/Position.global_position.y - global_position.y) < 20:
		facing_up = true
	elif ($Rotation/Recoil/Position.global_position.y - global_position.y) > 20:
		facing_up = false
	if !bare and gun != null:
		if aim:
			gun.global_position.x = $Idle/Aim.global_position.x
		else:
			gun.position.x = lerpf(gun.position.x,$Idle.position.x,0.2 * Setting.inverse)
		gun.position.y = shake
	block = get_parent().get_node("Block").is_colliding()
	action = melee or throwing or get_parent().climb
	if current_gun == 40:
		$Idle/Aim.position.y = -28
	elif current_gun == 15:
		$Idle/Aim.position.y = 100
	else:
		$Idle/Aim.position.y = 0
	slow = lerpf(slow,1,0.25 * Setting.inverse)
	for i in Contract.time:
		if i != -1:
			if i > 0:
				i -= 1
			else:
				Contract.fail.append(i)
var melee = false
var switch_count = 1
var back_count = 1
var switching = false
var bare = true
var slot_1 = true
var slot_2 = false
var break_action = false
var on_slot_1 = true
func switch():
	if get_parent().scroll_up:
		if switch_count > 0:
			if switch_count > 1:
				switch_count -= 1
				on_slot_1 = true
				$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if get_parent().scroll_down:
		if switch_count > 0:
			if switch_count < 2 and get_child(1).get_class() == "Node2D":
				switch_count += 1
				on_slot_1 = false
				$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if get_parent().scroll and !melee and get_child(1).get_class() == "Node2D":
		if switch_count > 0:
			on_slot_1 = !on_slot_1
			$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if $Switch.time_left > 0:
		switching = true
		break_action = true
	else:
		switching = false
		$Switch.stop()
	if switch_count != 0:
		if on_slot_1:
			switch_count = 1
		else:
			switch_count = 2
	if switch_count > 0 and !bare:
		back_count = switch_count
	match switch_count:
		0:
			slot_1 = false
			slot_2 = false
		1:
			slot_1 = true
			slot_2 = false
		2:
			slot_1 = false
			slot_2 = true

@onready var PistolA = preload("res://Screen/Asset/Weapon/PistolA.tscn")
@onready var PistolB = preload("res://Screen/Asset/Weapon/PistolB.tscn")
@onready var PistolC = preload("res://Screen/Asset/Weapon/PistolC.tscn")
@onready var PistolD = preload("res://Screen/Asset/Weapon/PistolD.tscn")
@onready var RifleA = preload("res://Screen/Asset/Weapon/RifleA.tscn")
@onready var RifleB = preload("res://Screen/Asset/Weapon/RifleB.tscn")
@onready var RifleC = preload("res://Screen/Asset/Weapon/RifleC.tscn")
@onready var SniperA = preload("res://Screen/Asset/Weapon/SniperA.tscn")
@onready var SniperB = preload("res://Screen/Asset/Weapon/SniperB.tscn")
@onready var SMGA = preload("res://Screen/Asset/Weapon/SMGA.tscn")
@onready var SMGB = preload("res://Screen/Asset/Weapon/SMGB.tscn")
@onready var SMGC = preload("res://Screen/Asset/Weapon/SMGC.tscn")
@onready var ShotgunA = preload("res://Screen/Asset/Weapon/Shotgun.tscn")
@onready var ShotgunB = preload("res://Screen/Asset/Weapon/ShotgunB.tscn")
@onready var ShotgunC = preload("res://Screen/Asset/Weapon/ShotgunC.tscn")
@onready var DMR = preload("res://Screen/Asset/Weapon/DMR.tscn")
@onready var LMG = preload("res://Screen/Asset/Weapon/LMG.tscn")
@onready var LauncherA = preload("res://Screen/Asset/Weapon/Launcher.tscn")
@onready var drop = preload("res://Screen/Asset/Entity/Stuff/Drop.tscn")
var gun
var current_gun = 0
var stuff
var weapon_1
var weapon_2
var hovering = 0
var perk_code = 0

var loadout = 0
var echo = 0
var recharge = 0
var spotter = 0
var payout = 0

var pick_cool = 0
func pick():
	if get_child(0).get_class() != "Node2D" and weapon[0] > 0:
		replacing_gun(weapon[0])
	if get_child(1).get_class() != "Node2D" and weapon[1] > 0:
		replacing_gun(weapon[1])
	$PickRange.position.x = 0
	$PickRange.position.y = 0
	if $PickRange.is_colliding() and $PickRange.get_collider(0) != null:
		stuff = $PickRange.get_collider(0).get_parent()
	if stuff != null and stuff.is_in_group("stuff") and $PickRange.is_colliding() and !get_parent().velocity.x > 1600:
		if get_parent().use and stuff.key[0] == 1:
			if weapon[1] > 0:
				var drop_ins = drop.instantiate()
				drop_ins.global_position = global_position
				drop_ins.code = gun.gun
				drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
				get_tree().get_root().add_child(drop_ins)
				replacing_gun(stuff.code)
			else:
				replacing_gun(stuff.code)
				switch_count += 1
				on_slot_1 = false
			stuff.queue_free()
	for auto_pick in $PickRange.get_collision_count():
		if $PickRange.is_colliding() and $PickRange.get_collider(auto_pick) != null and $PickRange.get_collider(auto_pick).get_parent().is_in_group("stuff") and !pick_cool > 0:
			var picking_stuff = $PickRange.get_collider(auto_pick).get_parent()
			match picking_stuff.key[0]:
				2: match picking_stuff.key[1]:
					0: if ammo[1] <= 600 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						ammo[1] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
					1: if ammo[0] <= 600 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						ammo[0] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
					2: if ammo[2] <= 300 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						ammo[2] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
					3: if ammo[3] <= 300 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						ammo[3] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
					4: if ammo[4] <= 100 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						ammo[4] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
					6: if armor < 20:
						armor += 1
						picking_stuff.queue_free()
					7:
						if lethal_type == picking_stuff.key[2] and lethal.size() < 2:
							lethal.append(picking_stuff.key[2])
							picking_stuff.queue_free()
						if tactical_type == picking_stuff.key[2] and tactical.size() < 2:
							tactical.append(picking_stuff.key[2])
							picking_stuff.queue_free()
	pick_cool = move_toward(pick_cool,0,Setting.inverse)

var shoot = false
var shooting = false
var shooted = false
var reload = false
var mode = false
var reverse_ammo = 0
var recoil = 0
var spread = 0
var max_spread = 0
var current_ammo = 0
var aim_speed = 0
var fire_delay = false
var coiling = false
var reloading = false
var walk = false
var slide = false
var mode_changing = false
var wait = false
var block = false
var action = false
var fire_mode = 0
var pack_opening = false
var scope = 0.0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var buffer = 0
func weaponfunc():
	if get_child(0).get_class() == "Node2D":
		weapon_1 = get_child(0)
		weapon_1.switching = switching
		weapon_1.gun = int(str(1) + str(int(weapon_1.code / 10)) + str(weapon_1.code % 10) + str(int(weapon_1.current_ammo / 100)) + str(int(int(weapon_1.current_ammo) % 100/10)) + str(int(weapon_1.current_ammo) % 10) + str(weapon_1.scope) + str(weapon_1.foregrip) + str(weapon_1.muzzle) + str(weapon_1.magazine) + str(weapon_1.laser) + str(weapon_1.stock))
		weapon[0] = weapon_1.gun
		if get_child(1).get_class() == "Node2D":
			weapon_2 = get_child(1)
			weapon_2.switching = switching
			weapon_2.gun = int(str(1) + str(int(weapon_2.code / 10)) + str(weapon_2.code % 10) + str(int(weapon_2.current_ammo / 100)) + str(int(int(weapon_2.current_ammo) % 100/10)) + str(int(weapon_2.current_ammo) % 10) + str(weapon_2.scope) + str(weapon_2.foregrip) + str(weapon_2.muzzle) + str(weapon_2.magazine) + str(weapon_2.laser) + str(weapon_2.stock))
			weapon[1] = weapon_2.gun
			if get_child(2).get_class() == "Node2D":
				get_child(2).hide()
	if slot_1:
		gun = weapon_1
		if weapon_1.get_parent().get_class() == "Node2D":
			if !switching:
				weapon_1.current()
			weapon_1.show()
		if $Switch.time_left > 0:
			if $Switch.wait_time > 0.3:
				weapon_1.take = true
				weapon_1.on = false
			else:
				weapon_1.take = false
				weapon_1.on = true
		else:
			weapon_1.take = false
			weapon_1.on = false
			weapon_1.off = false
		if !melee and !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0:
			$Recoil.position.x = weapon_1.get_node("Recoil").position.x * facing
			$Recoil.position.y = weapon_1.get_node("Recoil").position.y
	else:
		weapon_1.take = false
		weapon_1.on = false
		weapon_1.stop()
		if $Switch.time_left > 0.4:
			weapon_1.off = true
		else:
			weapon_1.off = false
			weapon_1.hide()
	if get_child(1).get_class() == "Node2D":
		if slot_2:
			gun = weapon_2
			if weapon_2.get_parent().get_class() == "Node2D":
				if !switching:
					weapon_2.current()
				weapon_2.show()
			if $Switch.time_left > 0:
				if $Switch.wait_time > 0.3:
					weapon_2.take = true
					weapon_2.on = false
				else:
					weapon_2.take = false
					weapon_2.on = true
			else:
				weapon_2.take = false
				weapon_2.on = false
				weapon_2.off = false
			if !melee and !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0:
				$Recoil.position.x = weapon_2.get_node("Recoil").position.x * facing
				$Recoil.position.y = weapon_2.get_node("Recoil").position.y
		else:
			weapon_2.take = false
			weapon_2.on = false
			weapon_2.stop()
			if $Switch.time_left > 0.4:
				weapon_2.off = true
			else:
				weapon_2.off = false
				weapon_2.hide()
	current_gun = gun.code
	recoil = gun.recoil
	max_spread = gun.max_spread
	current_ammo = gun.current_ammo 
	reverse_ammo = gun.reverse_ammo
	fire_delay = gun.fire_delay
	coiling = gun.coiling
	reloading = gun.reloading
	scope = gun.scope
	aim_speed = gun.aim_speed
	mode_changing = gun.mode_changing
	fire_mode = gun.fire_mode
	get_parent().get_node("Block").target_position.x = gun.get_node("Fire").position.x + 10
	if (echo > 0 and get_parent().fired or get_parent().fire) and get_parent().sprint_delay > 0:
		buffer = 10
	buffer = move_toward(buffer,0,Setting.inverse)
	if gun.fire or gun.firing:
		buffer = 0
	gun.fire = (buffer > 0 or echo > 0 and get_parent().fired or get_parent().fire) and !get_parent().sprint_delay > 0
	gun.firing = get_parent().firing and !get_parent().sprint_delay > 0
	gun.reload = get_parent().reload
	gun.mode = get_parent().mode
	gun.facing = facing
	gun.walk = walk
	gun.slide = slide
	gun.wait = wait
	gun.block = block
	gun.action = action
	gun.z_index = facing
	gun.global_rotation = $Rotation/Recoil.global_rotation + (tolerance_rotate + deg_to_rad(shake)) * unstable
	if $Switch.time_left > $Switch.wait_time - 0.1 or $Lethal.time_left < 0.1 and $Lethal.time_left > 0 or $Tactical.time_left < 0.1 and $Tactical.time_left > 0 or $Sentry.time_left < 0.1 and $Sentry.time_left > 0 or $Chaser.time_left < 0.1 and $Chaser.time_left > 0 or $Armor.time_left < 0.1 and $Armor.time_left > 0 or $Heal.time_left < 0.1 and $Heal.time_left > 0:
		$Rotation/Recoil/Body/ArmR.global_position.x = lerpf($Rotation/Recoil/Body/ArmR.global_position.x,gun.get_node("Body/HandR").global_position.x,0.5 * Setting.inverse)
		$Rotation/Recoil/Body/ArmR.global_position.y = lerpf($Rotation/Recoil/Body/ArmR.global_position.y,gun.get_node("Body/HandR").global_position.y,0.5 * Setting.inverse)
		$Rotation/Recoil/Body/ArmR/HandR.global_position = gun.get_node("Body/HandR/HandR2").global_position
		if !throwing or $Armor.time_left > 0 or $Heal.time_left > 0:
			$Rotation/Recoil/Body/ArmL.global_position.x = lerpf($Rotation/Recoil/Body/ArmL.global_position.x,gun.get_node("Body/HandL").global_position.x,0.5 * Setting.inverse)
			$Rotation/Recoil/Body/ArmL.global_position.y = lerpf($Rotation/Recoil/Body/ArmL.global_position.y,gun.get_node("Body/HandL").global_position.y,0.5 * Setting.inverse)
			$Rotation/Recoil/Body/ArmL/HandL.global_position = gun.get_node("Body/HandL/HandL2").global_position
	else:
		if !lethal_hold and !$Lethal.time_left > 0 and !$Sentry.time_left > 0:
			$Rotation/Recoil/Body/ArmR.global_position = gun.get_node("Body/HandR").global_position
			$Rotation/Recoil/Body/ArmR/HandR.global_position = gun.get_node("Body/HandR/HandR2").global_position
		if !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0:
			$Rotation/Recoil/Body/ArmL.global_position = gun.get_node("Body/HandL").global_position
			$Rotation/Recoil/Body/ArmL/HandL.global_position = gun.get_node("Body/HandL/HandL2").global_position
			

@onready var frag = preload("res://Screen/Asset/Weapon/Lethal/Frag.tscn")
@onready var fire = preload("res://Screen/Asset/Weapon/Lethal/Fire.tscn")
@onready var knife = preload("res://Screen/Asset/Weapon/Lethal/Knife.tscn")
@onready var mine = preload("res://Screen/Asset/Weapon/Lethal/Mine.tscn")
@onready var smoke = preload("res://Screen/Asset/Weapon/Tactical/Smoke.tscn")
@onready var flash = preload("res://Screen/Asset/Weapon/Tactical/Flash.tscn")
@onready var decoy = preload("res://Screen/Asset/Weapon/Tactical/Decoy.tscn")
@onready var latch = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
@onready var ring = preload("res://Screen/Asset/Weapon/Lethal/Ring.tscn")
var lethal_type = 0
var tactical_type = 4
var charging_lethal = 0
var charging_tactical = 0
var hold = 0.0
var strengt = 0
var throwing = false
var lethal_hold = false
var tactical_hold = false
func throw():
	if !break_action and abs(get_parent().velocity.x) < 1200 and !switching and !mode_changing and !reloading and !fire_delay and !melee and !get_parent().armor_using and !get_parent().healing:
		if get_parent().lethal_hold:
			hold = 0
			if !tactical_hold and lethal.size() > 0:
				lethal_hold = true
				throwing = true
			else:
				tactical_hold = false
				throwing = false
		if get_parent().tactical_hold and tactical.size() > 0 and !tactical[0] == 6:
			hold = 0
			if !lethal_hold and tactical.size() > 0:
				tactical_hold = true
				throwing = true
			else:
				lethal_hold = false
				throwing = false
	else:
		break_action = false
		throwing = $Lethal.time_left > 0.2 or $Tactical.time_left > 0.2 or $Sentry.time_left > 0 or $Chaser.time_left > 0
		lethal_hold = false
		tactical_hold = false
	if lethal_hold:
		if hold < 60 and !$Lethal.time_left > 0.2:
			hold += 1 * Setting.inverse
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.global_position.x = global_position.x + $ArmR/HandR.position.x * facing
		$Rotation/Recoil/Body/ArmR/HandR.global_position.y = global_position.y + $ArmR/HandR.position.y 
	if tactical_hold:
		if hold < 60 and !$Tactical.time_left > 0.2:
			hold += 1 * Setting.inverse
	if throwing or $Armor.time_left > 0.1 or $Heal.time_left > 0.1:
		$Rotation/Recoil/Body/ArmL.global_position.x = global_position.x + $ArmL.position.x * facing
		$Rotation/Recoil/Body/ArmL.global_position.y = global_position.y + $ArmL.position.y
		$Rotation/Recoil/Body/ArmL/HandL.position.x = $ArmL/HandL.position.x
		$Rotation/Recoil/Body/ArmL/HandL.position.y = $ArmL/HandL.position.y * facing

	if lethal_hold:
		$Anim.play("Hold_Lethal")
	if $Lethal.time_left > 0.1:
		throwing = true
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.position.x = $ArmR/HandR.position.x
		$Rotation/Recoil/Body/ArmR/HandR.position.y = $ArmR/HandR.position.y * facing
		$Anim.play("Throw_Lethal")
	if $Sentry.time_left > 0.1:
		throwing = true
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.position.x = $ArmR/HandR.position.x
		$Rotation/Recoil/Body/ArmR/HandR.position.y = $ArmR/HandR.position.y * facing
		$Anim.play("Throw_Sentry")
	if tactical_hold:
		$Anim.play("Hold_Tac")
	if $Tactical.time_left > 0.1 or $Chaser.time_left > 0.1:
		throwing = true
		$Anim.play("Throw_Tac")
	if $Tactical.time_left > 0 and $Tactical.time_left < 0.1 or $Chaser.time_left > 0 and $Chaser.time_left < 0.1:
		throwing = false
	if $Ignitor.time_left > 0:
		$Anim.play("Blast")
	strengt = 2000 + hold * 50
	if lethal.size() > 0:
		lethal_type = lethal[0]
	if tactical.size() > 0:
		tactical_type = tactical[0]
	if get_parent().lethal and lethal.size() > 0 and lethal_hold:
		var ins
		match lethal[0]:
			0: ins = frag.instantiate()
			1: ins = fire.instantiate()
			2: ins = knife.instantiate()
			3: ins = mine.instantiate()
		match lethal[0]:
			2: ins.apply_impulse(Vector2(strengt + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.05 * facing), Vector2())
			3: ins.apply_impulse(Vector2(strengt / 2 + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.05 * facing), Vector2())
			_:
				ins.apply_impulse(Vector2(strengt + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.2 * facing), Vector2())
				var ins1 = ring.instantiate()
				ins1.global_position = global_position
				ins1.apply_impulse(Vector2(-1000, -500).rotated($Rotation/Recoil.global_rotation), Vector2())
				get_tree().get_root().add_child(ins1)
		ins.global_position = global_position
		ins.angular_velocity = 40 * facing
		ins.id = get_parent().id
		get_tree().get_root().add_child(ins)
		lethal.remove_at(0)
		$Lethal.start(0.3)
		hold = 0
		lethal_hold = false
	if get_parent().tactical and tactical.size() > 0 and tactical_hold:
		var ins
		match tactical[0]:
			4: ins = smoke.instantiate()
			5: ins = flash.instantiate()
			7: ins = decoy.instantiate()
		ins.global_position = global_position
		ins.angular_velocity = 20 * facing
		ins.apply_impulse(Vector2(strengt * 0.75 + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.2 * facing), Vector2())
		get_tree().get_root().add_child(ins)
		tactical.remove_at(0)
		$Tactical.start(0.3)
		hold = 0
		tactical_hold = false
	if recharge > 0:
		if lethal.size() < 2:
			charging_lethal += (0.001 + 0.00025 * get_parent().overload) * Setting.inverse
		if tactical.size() < 2:
			charging_tactical += (0.001 + 0.00025 * get_parent().overload) * Setting.inverse
	else:
		charging_lethal = 0
		charging_tactical = 0
	if charging_lethal > 1:
		lethal.append(lethal)
		charging_lethal = 0
	if charging_tactical > 1:
		tactical.append(tactical)
		charging_tactical = 0

func replacing_gun(code):
	var instance
	match int((code % 100000000000)/10000000000):
		0: match int((code % 10000000000)/1000000000):
			0: instance = PistolA.instantiate()
			1: instance = PistolB.instantiate()
			2: instance = PistolC.instantiate()
			3: instance = PistolD.instantiate()
			4: instance = SMGA.instantiate()
			5: instance = SMGB.instantiate()
			6: instance = SMGC.instantiate()
		1: match int((code % 10000000000)/1000000000):
			0: instance = RifleA.instantiate()
			1: instance = RifleB.instantiate()
			2: instance = RifleC.instantiate()
			3: instance = DMR.instantiate()
			4: instance = LMG.instantiate()
		2: match int((code % 10000000000)/1000000000):
			0: instance = ShotgunA.instantiate()
			1: instance = ShotgunB.instantiate()
			2: instance = ShotgunC.instantiate()
		3: match int((code % 10000000000)/1000000000):
			0: instance = SniperA.instantiate()
			1: instance = SniperB.instantiate()
		4: instance = LauncherA.instantiate()
	instance.position = $Idle.position
	instance.global_rotation_degrees = $Rotation/Recoil.global_rotation_degrees
	if slot_1:
		instance.gun = code
		if get_child(0).get_class() == "Node2D":
			if get_child(1).get_class() == "Node2D":
				weapon_1.queue_free()
				add_child(instance)
				move_child(instance,0)
				weapon[0] = code
				$Switch.start(0.5)
			else:
				add_child(instance)
				move_child(instance,1)
				weapon[1] = code
				$Switch.start(0.5)
		else:
			add_child(instance)
			move_child(instance,0)
			weapon[0] = code
			$Switch.start(0.5)
	if slot_2:
		instance.gun = code
		weapon_2.queue_free()
		add_child(instance)
		move_child(instance,1)
		weapon[1] = code
		$Switch.start(0.5)
			
func perk_load(code):
	perk_slot = 0
	loadout = 0
	get_parent().conscious = 0
	get_parent().recovery = 0
	get_parent().overclock = 0
	get_parent().resilience = 0
	echo = 0
	get_parent().succinct = 0
	spotter = 0
	get_parent().sonic = 0
	payout = 0
	get_parent().overload = 0
	get_parent().berserk = 0
	get_parent().phantom = 0
	get_parent().alert = 0
	recharge = 0
	get_parent().shifter = 0
	for i in code:
		match i % 10:
			9: if perk_slot < 13:
				match int((i % 1000)/100):
					1: if get_parent().phantom < 1:
						get_parent().phantom += 1
						perk_slot += 4
					2: if get_parent().alert < 1:
						get_parent().alert += 1
						perk_slot += 4
					3: if recharge < 1:
						recharge += 1
						perk_slot += 4
					4: if get_parent().shifter < 1:
						get_parent().shifter += 1
						perk_slot += 4
			_: match int((i % 100)/10):
				5: if perk_slot < 15:
					match i % 10:
						1: if get_parent().resilience < 1:
							get_parent().resilience += 1
							perk_slot += 2
						2: if echo < 1:
							echo += 1
							perk_slot += 2
						3: if get_parent().succinct < 1:
							get_parent().succinct += 1
							perk_slot += 2
						4: if spotter < 1:
							spotter += 1
							perk_slot += 2
						5: if get_parent().sonic < 2:
							get_parent().sonic += 1
							perk_slot += 2
						6: if payout < 2:
							payout += 1
							perk_slot += 2
						7: if get_parent().overload < 4:
							get_parent().overload += 1
							perk_slot += 2
						8: if get_parent().berserk < 4:
							get_parent().berserk += 1
							perk_slot += 2
				_: if perk_slot < 16:
					match i:
						1: if loadout < 6:
							loadout += 1
							perk_slot += 1
						2: if get_parent().conscious < 2:
							get_parent().conscious += 1
							perk_slot += 1
						3: if get_parent().recovery < 4:
							get_parent().recovery += 1
							perk_slot += 1
						4: if get_parent().overclock < 4:
							get_parent().overclock += 1
							perk_slot += 1
func refill():
	for i in 2 - lethal.size():
		lethal.append(lethal)
	for i in 2 - tactical.size():
		tactical.append(tactical)
	ammo[1] = move_toward(ammo[1],600,120)
	ammo[0] = move_toward(ammo[0],600,120)
	ammo[2] = move_toward(ammo[2],300,60)
	ammo[3] = move_toward(ammo[3],300,60)
	ammo[4] = move_toward(ammo[4],100,20)
	

var kill_count = 0
var streak = 0
var streak_count = 0
func killstreak():
	if streak_count > 0:
		streak_count -= Setting.inverse
	else:
		streak = 0

@onready var missile = preload("res://Screen/Asset/Weapon/Streak/Missile.tscn")
func airstrike():
	if get_parent().sentry:
		$Camera2D.enabled = false
		get_parent().can_move = false
		get_parent().fight = false
		var ins = missile.instantiate()
		ins.get_node("Camera2D").make_current()
		ins.position = Vector2(global_position.x + randi_range(-2000,2000),-10000)
		ins.rotation_degrees = 90
		get_tree().get_root().add_child(ins)

func hit(dmg):
	pass
var slow = 0
func slash(dmg):
	pass
func kill(type):
	if get_parent().resilience > 0:
		get_parent().heal_cool = 0
func shaked():
	$Camera2D.shake(10,5)
