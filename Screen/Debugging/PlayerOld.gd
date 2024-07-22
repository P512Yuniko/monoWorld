extends CharacterBody2D

@export var can_move = true
@export var animation = true
@export var fight = true

@export var walk_speed = 1000
@export var dash_speed = 2000
@export var aim_speed = 200
@export var crouch_speed = 400
@export var use_speed = 600
@export var jump_speed = 2800
var speed = 0
var accel = 100.0
var motion = 0
var time = 1
func _physics_process(_delta):
	ui()
	stat()
	part()
	if animation:
		animate()
		emote()
	gravity()
	if can_move:
		movement()
		go_up()
		slide()
		walk()
		velocity.x = clamp(velocity.x ,-speed * motion,speed * motion)
		move_and_slide()
		if !lying:
			dash()
	if fight:
		skill()
		melee()
		$Weapon.active()
	motion = 1/Engine.time_scale
	time = Engine.time_scale
var corruptor = false

func skill():
	trojan()
	if corruptor:
		pass
	else:
		spectre()
		raze()
		sword = true
var invisible = false
var invisible_time = 200
var invisible_cool = 0
func spectre():
	if Key.tactical_skill and !invisible_cool > 0:
		invisible = !invisible
		if invisible:
			invisible_cool = 100
	if invisible:
		$HitBox.set_collision_layer_value(5,false)
		$SpriteR.modulate = Color8(1,1,1,5)
		$SpriteL.modulate = Color8(1,1,1,5)
		$Weapon.modulate = Color8(1,1,1,5)
		$Melee.modulate = Color8(1,1,1,5)
		if invisible_time > 0:
			invisible_time -= 1
		else:
			invisible = false
	else:
		$HitBox.set_collision_layer_value(5,true)
		$SpriteR.modulate = Color8(255,255,255,255)
		$SpriteL.modulate = Color8(255,255,255,255)
		$Weapon.modulate = Color8(255,255,255,255)
		$Melee.modulate = Color8(255,255,255,255)
		if invisible_time < 200:
			invisible_time += 0.5
var razing
var raze_time = 200
var raze_cool = 0
func raze():
	if Key.lethal_skill and !raze_cool > 0:
		razing = !razing
		if razing:
			raze_cool = 100
		$Weapon/Infantry/TurretR/Take.start(0.5 * time)
		$Weapon/Infantry/TurretL/Take.start(0.5 * time)
	$Weapon.razing = razing
	if razing:
		if raze_time > 0:
			raze_time -= 1
		else:
			razing = false
	else:
		if raze_time < 200:
			raze_time += 0.5
var hold = 0
var hacking = false
func trojan():
	if $Weapon/PickRange.is_colliding() and $Weapon/PickRange.get_collider(0) != null:
		if Key.using and hold <= 20:
			hold += 1
		if hold == 20:
			hold = 0
func movement():
	if grounded and abs(velocity.x * time) < 800 and (Key.crouch and !$Ouch.is_colliding() or $Ouch.is_colliding() and !crouching and !sliding):
		crouching = !crouching
	elif Key.crouch and crouching and !$Ouch.is_colliding():
		crouching = false
	elif crouching and Key.jump and !$Ouch.is_colliding():
		crouching = false
	elif abs(velocity.x * time) < 1200 and !sliding and grounded and $Ouch.is_colliding() and !lying:
		crouching = true
	elif crouching and Key.lay:
		crouching = false
	elif crouching and dashing:
		crouching = false
	elif crouching and !grounded:
		await get_tree().create_timer(0.1).timeout
		if !grounded:
			crouching = false
		else:
			crouching = true
	if lying:
		crouching = false
	if grounded and Key.lay and abs(int(foot_distance)) < 20 and !$Lay.is_colliding() and abs(velocity.x * time) < 200:
		lying = !lying
		$LayTimer.start(0.3 * time)
		if !$Ouch.is_colliding():
			$LayTimer.start(0.3)
		else:
			crouching = true
	elif lying and Key.lay and !$Lay.is_colliding():
		$LayTimer.start(0.3 * time)
		if $Ouch.is_colliding():
			crouching = !crouching
			lying = false
		else:
			lying = false
	elif lying and Key.jump and !$Ouch.is_colliding() and !$Lay.is_colliding():
		$LayTimer.start(0.1 * time)
		lying = false
	elif lying and Key.crouch and !$Lay.is_colliding():
		$LayTimer.start(0.3 * time)
		crouching = true
		lying = false
	elif lying and !grounded:
		await get_tree().create_timer(0.1).timeout
		if !grounded:
			$LayTimer.start(0.3 * time)
			lying = false
		else:
			lying = true

func walk():
	if $Weapon.aim or lying:
		if grounded and !sliding:
			speed = lerpf(speed,aim_speed,0.5)
		else:
			if abs(velocity.x * time) > 800:
				speed = lerpf(speed,walk_speed,0.01)
			else:
				speed = lerpf(speed,aim_speed,0.5)
	elif !$Weapon.aim and crouching:
		speed = lerpf(speed,crouch_speed,0.5)
	elif $Weapon.reloading or $Weapon.switching and !dashing or $Weapon.fire_delay or $Weapon.throwing or Key.up or Key.down or $Weapon.current_gun == "SniperB" and $Weapon.gun.charge > 0 or $Weapon.mode_changing:
		if grounded:
			if abs(velocity.x * time) < 1200:
				speed = lerpf(speed,use_speed,0.5)
		else:
			if abs(velocity.x * time) > 1200:
				speed = lerpf(speed,walk_speed,0.01)
			else:
				speed = lerpf(speed,walk_speed,0.5)
	elif slash_delay and abs(velocity.x * time) < 1200 and grounded:
		speed = lerpf(speed,use_speed,0.5)
	elif dashing or sliding:
		if $DashTimer.time_left > dash_time - dash_time/4:
			speed = lerpf(speed,dash_speed * 2,0.2)
		else:
			speed = lerpf(speed,dash_speed,0.2)
	elif (dash_right or dash_left) and !dashing:
		if grounded or dashing:
			speed = lerpf(speed,dash_speed,0.5)
		else:
			speed = lerpf(speed,walk_speed,0.01)
	else:
		speed = lerpf(speed,walk_speed,0.5)
	if !(lying and $Weapon.aim or lying and $Weapon.fire_delay or break_charging and break_charge > 12):
		if Key.lefting and !Key.righting:
			if lying:
				velocity.x -= accel/20
			else:
				velocity.x -= accel
		elif Key.righting and !Key.lefting:
			if lying:
				velocity.x += accel/20
			else:
				velocity.x += accel
		else:
			if grounded:
				velocity.x = lerpf(velocity.x,0,0.2)
			else:
				if abs(velocity.x * time) < 800:
					velocity.x = lerpf(velocity.x ,0,0.1)
				elif abs(velocity.x * time) > 800 and abs(velocity.x * time) < 1200:
					velocity.x = lerpf(velocity.x ,0,0.01)
				else:
					velocity.x = lerpf(velocity.x ,0,0.005)
		if lying and abs(velocity.x * time) > aim_speed:
			if Key.lefting and !Key.righting:
				velocity.x = -50
			elif Key.righting and !Key.lefting:
				velocity.x = 50
	else:
		velocity.x = lerpf(velocity.x * time,0,0.2)

var dash_timer = 10
@export var dash_time = 0.5
var dashing_right = true
var dashing = false
var dash_boost = 4000
var dash_direction = Vector2()
var dash_right
var dash_left
func dash():
	if dash_timer > 0 and !dash_right and !dash_left:
		dash_timer -= 1
	if Key.lefted and !$DashCool.time_left > 0:
		dash_timer = 10
		dashing_right = false
	elif Key.righted and !$DashCool.time_left > 0:
		dash_timer = 10
		dashing_right = true
	if Key.lefting and dash_timer > 0 and !dashing_right:
		dash_left = true
		dash_direction = Vector2(-1,0.05)
	if Key.righting and dash_timer > 0 and dashing_right:
		dash_right = true
		dash_direction = Vector2(1,0.05)
	if dash_timer > 0 and !$DashCool.time_left > 0 and !$Weapon.aim and !$Weapon.fire_delay and !$CantDash.is_colliding():
		if Key.left and !dashing_right or Key.right and dashing_right: 
			$DashTimer.start(dash_time * time)
			$DashCool.start(dash_time * 2 * time)
			$Weapon.reloading = false
			$Effect/JetR.restart()
			$Effect/JetL.restart()
	if $DashTimer.time_left > 0:
		velocity = dash_direction.normalized() * dash_boost * motion
		if abs(velocity.x * time) > 1200:
			dashing = true
			sliding = false
			$SlideTimer.stop()
		else:
			dashing = false
	else:
		dashing = false
	if abs(velocity.x * time) < 200 or Key.scroll or dashing_right and Key.left or !dashing_right and Key.right:
		dashing = false
		$DashTimer.stop()
	if abs(velocity.x * time) < 200 or $CantDash.is_colliding() or $Weapon.aim or Key.up or Key.down:
		dash_right = false
		dash_left = false
		dashing = false
		$DashTimer.stop()
	if !dash_left and !dash_right:
		dashing = false
	if abs(velocity.x * time) > 1200 and !sliding and !grounded and !$Weapon.aim or abs(velocity.x * time) > 1800 and !sliding and grounded or $Melee/Heavy_delay.time_left > $Melee/Heavy_delay.wait_time - slash_time * 3/4:
		if $Weapon.switch_count > 0:
			$Weapon.switch_count = 0
	else:
		if $Weapon.switch_count == 0 and !$Weapon.bare:
			$Weapon.switch_count += $Weapon.back_count
			$Weapon/Switch.stop()
			$Weapon/Switch.start(0.3 * time)
		elif $Weapon.bare:
			$Weapon.switch_count = 1

@export var jump_time = 2
@export var fly_time = 50
var count_jump = 0
var count_fly = 0
var grounded = false
var climb = false
var fly = false
func go_up():
	if grounded and !sliding and velocity.y >= 0:
		count_jump = jump_time
		if count_fly < fly_time:
			count_fly += 2
	elif grounded and sliding:
		count_jump = jump_time - 1
	if Key.jump and count_jump > 0 and !$Ouch.is_colliding():
		normal_jump()
		count_jump -= 1
		dashing = false
		$DashTimer.stop()
		if grounded:
			$Effect.jump()
	if Inventory.hawk:
		if count_jump < 1 and Key.fly and count_fly > 0:
			dashing = false
			$DashTimer.stop()
			velocity.y -= accel * 2
			count_fly -= 1
			$Effect/JetR.one_shot = false
			$Effect/JetL.one_shot = false
			$Effect/JetR.emitting = true
			$Effect/JetL.emitting = true
			fly = true
		else:
			$Effect/JetR.one_shot = true
			$Effect/JetL.one_shot = true
			fly = false
	if Key.jump and climb:
		normal_jump()
		count_jump -= 1
		$ClimbTimer.start(0.5)
	if !grounded and count_jump > jump_time - 1:
		await get_tree().create_timer(0.2).timeout
		count_jump = 1
	$Effect/JetR.z_index = -3 * facing
	$Effect/JetL.z_index = -3 * facing
	if !grounded and $Weapon.get_child(0).get_class() == "Node2D" and $Weapon.current_gun == "LauncherA" and $Weapon.coiling:
		$Weapon/Knockback.global_position = $Weapon/Rotation/Recoil/Body.global_position
		velocity.x += $Weapon/Knockback.position.x/ 5 * 200
		velocity.y += $Weapon/Knockback.position.x/ -5 * 50
func normal_jump():
	if $Weapon.aim and grounded:
		velocity.y = -jump_speed * 3.0/4 * motion
	else:
		velocity.y = -jump_speed * motion
	if count_jump < jump_time:
		$Effect/JetR.restart()
		$Effect/JetL.restart()
var fall_speed = 3000
func gravity():
	velocity.y += accel
	if climb:
		velocity.y = clampf(velocity.y,-jump_speed * motion,200)
	else:
		velocity.y = clampf(velocity.y,-jump_speed * motion,fall_speed)
	grounded = $Grounded.is_colliding()
	if velocity.y < -400:
		$Grounded.enabled = false
	else:
		$Grounded.enabled = true
	if !grounded and !$CantClimb.is_colliding() and $Climb.is_colliding():
		climb = true
	else:
		climb = false
	$Effect.ground = grounded
	if grounded and velocity.y > 2000:
		$Weapon/Camera2D.shake((velocity.y/1000),5)
var can_slide = true
var sliding = false
var slide_direction = 0
var slide_boost = 2000
@export var slide_time = 1.0
@export var slide_des = 40.0
func slide():
	if grounded:
		if Key.lefting and velocity.x * time < -800:
			slide_direction = -1
			can_slide = true
		elif Key.righting and velocity.x * time > 800:
			slide_direction = 1
			can_slide = true
		else:
			can_slide = false
	else:
		can_slide = false
	if Key.crouch and !sliding and can_slide:
		$Effect/JetR.restart()
		$Effect/JetL.restart()
		if abs(velocity.x * time) > 1200:
			$SlideTimer.start(slide_time * 1.5)
		else:
			$SlideTimer.start(slide_time)
	if $SlideTimer.time_left > 0:
		sliding = true
		if $SlideTimer.wait_time > slide_time:
			velocity.x = slide_direction * slide_boost * 2 * motion
			slide_boost -= slide_des/2 * time
		else:
			velocity.x = slide_direction * slide_boost * motion
			slide_boost -= slide_des/1.5 * time
		if slide_boost < 0:
			slide_boost = 0
	else:
		sliding = false
		slide_boost = 2000
	if $SlideTimer.wait_time > slide_time:
		$SlideCollision.disabled = !sliding
	else:
		$SlideCollision.disabled = true
	$SlideCollision.scale.x = facing
	$SlideCollision/SlideCancel.enabled = sliding
	$SlideCollision/SlideCancel2.enabled = sliding
	if sliding:
		dashing = false
		dash_right = false
		dash_left = false
		$Weapon.wait = false
		if Key.jump:
			normal_jump()
			count_jump -= 1
			sliding = false
			$SlideTimer.stop()
		if $SlideCollision/SlideCancel.is_colliding() or $SlideCollision/SlideCancel2.is_colliding():
			sliding = false
			$SlideTimer.stop()
		if velocity.y < -1200 or abs(velocity.x * time) < 200 or $SlideTimer.time_left < slide_time/4 and !grounded:
			sliding = false
			$SlideTimer.stop()
		if $SlideTimer.time_left > 2 and velocity.y > 1200 and grounded:
			var pre_velo
			if !is_on_floor():
				pre_velo = -velocity.y/4
			velocity.y = pre_velo
@export var facing_right = true
var lying_right
var lying_up
@export var facing = 0
var walking
var idle
var crouching
var lying
var foot_stuck
var foot_distance = 0.0
var foot_position_r = 0
var foot_position_l = 0
func animate():
	$AniBody.speed_scale = motion
	$AniLeg.speed_scale = motion
	$AniArm.speed_scale = motion
	$AniMelee.speed_scale = motion
	$AniSkill.speed_scale = motion
	$SpriteR/Base/Body.position.x = ($BodyPos.position.x + $BodyPos2.position.x) * facing
	$SpriteL/Base/Body.position.x = ($BodyPos.position.x + $BodyPos2.position.x) * facing
	$SpriteR/Base/Body/Head.position.x = ($BodyPos/HeadPos.position.x + $HeadPos2.position.x) * facing
	if lying:
		$SpriteL/Base/Body/Head.position.x = ($BodyPos/HeadPos.position.x + $HeadPos2.position.x * -1)
	else:
		$SpriteL/Base/Body/Head.position.x = ($BodyPos/HeadPos.position.x + $HeadPos2.position.x) * facing
	$SpriteR/Base/Body.position.y = $BodyPos.position.y
	$SpriteL/Base/Body.position.y = $BodyPos.position.y
	$SpriteR/Base/Body/Head.position.y = $BodyPos/HeadPos.position.y
	$SpriteL/Base/Body/Head.position.y = $BodyPos/HeadPos.position.y
	$Weapon.walk = walking
	if !lying:
		facing_right = $Weapon.facing_right
		facing = $Weapon.facing
		if facing_right:
			$SpriteR.show()
			$SpriteL.hide()
			$CakeCollision.scale.x = 1
			lying_up = true
		else:
			$SpriteR.hide()
			$SpriteL.show()
			$CakeCollision.scale.x = -1
			lying_up = false
	if grounded and !sliding and !lying:
		if crouching:
			walking = false
			if abs(velocity.x * time) > 100:
				$AniBody.play("CrouchMove")
			if velocity.x * time > 300:
				$AniLeg.play("CrouchMove")
			elif velocity.x * time < -300:
				$AniLeg.play_backwards("CrouchMove")
			if velocity.x * time > 100 and velocity.x * time < 300:
				$AniLeg.play("CrouchAim")
			elif velocity.x * time < -100 and velocity.x * time > -300:
				$AniLeg.play_backwards("CrouchAim")
		else:
			if Key.righting and !Key.lefting and !dashing:
				if velocity.x * time > 1200 and dash_right:
					$AniArm.play("Void")
					$AniArm.playback_default_blend_time = 0
					$AniBody.play("Run")
					$AniLeg.play("Run")
					walking = true
				elif velocity.x * time > 800 and velocity.x * time < 1200:
					walking = true
					$AniLeg.play("Walk")
					$AniBody.play("Walk")
					if $Weapon.bare:
						$AniArm.play("Walk")
				else:
					walking = false
					if $Weapon.bare:
						$AniBody.play("Stand")
						$AniArm.play("Stand")
					if slash:
						$AniBody.play("Void")
						$AniBody.playback_default_blend_time = 0
					else:
						if $Weapon.wait:
							$AniBody.play("Ready")
						else:
							$AniBody.play("Stand")
						$AniBody.playback_default_blend_time = 0.25
				if velocity.x * time > 200 and velocity.x * time < 800 and !$Weapon.aim:
					$AniLeg.play("Use")
				if velocity.x * time > 100 and $Weapon.aim:
					$AniLeg.play("AimMove")
			elif Key.lefting and !Key.righting and !dashing:
				if velocity.x * time < -1200 and dash_left:
					$AniArm.play("Void")
					$AniArm.playback_default_blend_time = 0
					$AniBody.play("Run")
					$AniLeg.play("Run")
					walking = true
				elif velocity.x * time < -800 and velocity.x * time > -1200:
					walking = true
					$AniLeg.play("Walk")
					$AniBody.play("Walk")
					if $Weapon.bare:
						$AniArm.play("Walk")
				else:
					walking = false
					if $Weapon.bare:
						$AniBody.play("Stand")
						$AniArm.play("Stand")
					if slash:
						$AniBody.play("Void")
						$AniBody.playback_default_blend_time = 0
					else:
						if $Weapon.wait:
							$AniBody.play("Ready")
						else:
							$AniBody.play("Stand")
						$AniBody.playback_default_blend_time = 0.25
				if velocity.x * time < -200 and velocity.x * time > -800 and !$Weapon.aim:
					$AniLeg.play_backwards("Use")
				if velocity.x * time < -100 and $Weapon.aim:
					$AniLeg.play_backwards("AimMove")
			elif dashing:
				if slash:
					$AniArm.play("Dash_Slash")
				else:
					$AniArm.play("Dash")
				$AniBody.play("Dash")
				$AniLeg.play("Dash")
				walking = false
				sliding = false
			else:
				if abs(velocity.x * time) > 200:
					$AniBody.play("FallMove")
					$AniLeg.play("Stop")
				walking = false
				$AniArm.playback_default_blend_time = 0.25
		if abs(velocity.x * time) < 200:
			walking = false
			if crouching:
				$AniBody.play("Crouch")
				if $Weapon.bare:
					$AniArm.play("Crouch")
			else:
				if $Weapon.bare:
					$AniArm.play("Stand")
				if slash:
					$AniBody.play("Void")
					$AniBody.playback_default_blend_time = 0
				else:
					if $Weapon.wait:
						$AniBody.play("Ready")
					else:
						$AniBody.play("Stand")
					$AniBody.playback_default_blend_time = 0.25
			foot_stuck = true
			if abs(int(foot_distance)) > foot_distance/5 + 5:
				$SpriteR/Base/LegR.position.x = $FootCastR.position.x
				$SpriteR/Base/LegL.position.x = $FootCastL.position.x
				$SpriteR/Base/LegR.global_position.y = $FootCastR.get_collision_point().y - 12
				$SpriteR/Base/LegL.global_position.y = $FootCastL.get_collision_point().y - 12
				$SpriteL/Base/LegR.position.x = $FootCastL.position.x
				$SpriteL/Base/LegL.position.x = $FootCastR.position.x
				$SpriteL/Base/LegL.global_position.y = $FootCastR.get_collision_point().y - 12
				$SpriteL/Base/LegR.global_position.y = $FootCastL.get_collision_point().y - 12
				if abs(int(foot_distance)) > abs(int(foot_distance))/5 + 25:
					if facing_right:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-54,0.2)
						$FootCastL.position.x = lerpf($FootCastL.position.x,32,0.2)
					else:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-32,0.2)
						$FootCastL.position.x = lerpf($FootCastL.position.x,54,0.2)
				else:
					if facing_right:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-56,0.2)
						$FootCastL.position.x = lerpf($FootCastL.position.x,64,0.2)
					else:
						$FootCastR.position.x = lerpf($FootCastR.position.x,-64,0.2)
						$FootCastL.position.x = lerpf($FootCastL.position.x,56,0.2)
			else:
				if crouching:
					$AniLeg.play("Crouch")
				else:
					if $Weapon.bare and !(break_charging and break_charge > 12):
						$AniLeg.play("Chill")
					elif break_charging and break_charge > 12:
						$AniLeg.play("Battou")
					else:
						$AniLeg.play("Stand")
		else:
			foot_stuck = false
			$Weapon.wait = false
	elif !grounded and !sliding and !crouching and !$LayTimer.time_left > 0:
		walking = false
		$Weapon.wait = false
		$AniBody.playback_default_blend_time = 0.25
		if $Weapon.bare and abs(velocity.x * time) < 1200 and !$ClimbTimer.time_left > 0:
			$AniArm.play("Jump")
			$AniArmRotate.play("Down")
		if abs(velocity.x * time) < 200 and count_jump > 0 or velocity.y < -1200 and count_jump > 0:
			$AniBody.play("Jump")
		if velocity.y < -1200 and abs(velocity.x * time) < 800 and count_jump >= jump_time - 1:
			$AniLeg.play("Jump")
		if velocity.y < -1200 and velocity.x * time > 800 and velocity.x * time < 1200:
			$AniLeg.play("JumpMoveR")
		if velocity.y < -1200 and velocity.x * time < -800 and velocity.x * time > -1200:
			$AniLeg.play("JumpMoveL")
		if velocity.y < -1200 and !dashing and count_jump < jump_time - 1 and !fly:
			$AniBody.play("JumpBoost")
		elif fly:
			$AniBody.play("Fly")
		if velocity.y > 1200 and abs(velocity.x * time) < 200:
			$AniLeg.play("Fall")
		if velocity.y > 1200 and velocity.x * time > 800 and velocity.x * time < 1200:
			$AniLeg.play("FallMoveR")
			$AniBody.play("FallMove")
		if velocity.y > 1200 and velocity.x * time < -800 and velocity.x * time > -1200:
			$AniLeg.play("FallMoveL")
			$AniBody.play("FallMove")
		if abs(velocity.x * time) > 1200 and !dashing and velocity.y > -1200:
			$AniBody.play("AirFast")
			if !$Weapon.aim:
				$AniArm.play("Air")
		if abs(velocity.x * time) > 1200 and !dashing:
			$AniLeg.play("Jump_2")
		if dashing:
			if slash:
				$AniArm.play("Dash_Slash")
			else:
				$AniArm.play("Dash")
			$AniBody.play("Dash")
			$AniLeg.play("Dash")
		if climb or $ClimbTimer.time_left > 0:
			if climb:
				$AniArm.play("ClimbHold")
			else:
				$AniArm.play("Climb")
			$AniArm.playback_default_blend_time = 0
			$AniBody.play("Stand")
			$AniLeg.play("Jump")
		else:
			$AniArm.playback_default_blend_time = 0.25
	elif sliding:
		walking = false
		if $SlideTimer.wait_time > slide_time:
			if $AniBody.current_animation_position > 1 and $Ouch.is_colliding():
				$AniLeg.play("Crouch")
				$AniBody.play("Crouch")
				if $Weapon.bare:
					$AniArm.play("Crouch")
				$SlideTimer.stop()
				sliding = false
			else:
				$AniLeg.play("SlideLong")
				$AniBody.play("SlideLong")
				if $Weapon.bare:
					$AniArm.play("Air")
		else:
			if $AniBody.current_animation_position > 0.4 and $Ouch.is_colliding():
				$AniLeg.play("Crouch")
				$AniBody.play("Crouch")
				if $Weapon.bare:
					$AniArm.play("Crouch")
				$SlideTimer.stop()
				sliding = false
			else:
				$AniLeg.play("Slide")
				$AniBody.play("Slide")
				if $Weapon.bare:
					$AniArm.play("Air")
	if lying:
		walking = false
		$AniBody.playback_default_blend_time = 0.25
		facing = 1
		if Key.righting and !Key.lefting:
			lying_right = true
		elif Key.lefting and !Key.righting:
			lying_right = false
		if lying_up:
			$SpriteR.show()
			$SpriteL.hide()
			$CakeCollision.scale.x = 1
		else:
			$SpriteR.hide()
			$SpriteL.show()
			$CakeCollision.scale.x = -1
		$LegCollision.position.x = lerpf($LegCollision.position.x,$BaseCollision.position.x,0.2)
		if $LayTimer.time_left > 0:
			if facing_right:
				$AniBody.play("LyingR")
			else:
				$AniBody.play("LyingL")
		else:
			if facing_right:
				$AniBody.play("LayR")
				$Weapon.lying_right = 1
			else:
				$AniBody.play("LayL")
				$Weapon.lying_right = -1
		if $Weapon.reloading or $Weapon.switching:
			$Weapon.facing_right = facing_right
			lying_up = facing_right
		if abs(velocity.x * time) > 50:
			$Weapon.facing_right = facing_right
			if facing_right:
				lying_up = true
				if lying_right:
					$AniLeg.play("LayMove")
				else:
					$AniLeg.play_backwards("LayMove")
			else:
				lying_up = false
				if lying_right:
					$AniLeg.play_backwards("LayMove")
				else:
					$AniLeg.play("LayMove")
		if abs(velocity.x * time) < 100:
			if facing_right:
				$AniLeg.play("LayR")
			else:
				$AniLeg.play("LayL")
			if $Weapon.aim:
				lying_right = $Weapon.facing_right
				if lying_right:
					lying_up = true
				else:
					lying_up = false
			else:
				if Key.firing or Key.lefted or Key.righted:
					$Weapon.facing_right = lying_right
					if lying_right:
						lying_up = true
					else:
						lying_up = false
		$BaseCollision.rotation_degrees = 90 * facing + $FootRotate.global_rotation_degrees
		$SpriteR.global_rotation = $FootRotate.global_rotation
		$SpriteL.global_rotation = $FootRotate.global_rotation
	else:
		if $LayTimer.time_left > 0.25:
			if lying_right:
				$AniBody.play_backwards("LyingR")
			else:
				$AniBody.play_backwards("LyingL")
		else:
			lying_right = facing_right
		$LegCollision.position.x = lerpf($LegCollision.position.x,0,0.2)
		$SpriteR.rotation_degrees = 0
		$SpriteL.rotation_degrees = 0
	if !slash:
		if $Weapon.bare and crouching or $Weapon.throwing:
			$AniArmRotate.play("Down")
		elif $Weapon.facing_up:
			$AniArmRotate.play("Up")
		else:
			if (($SpriteR/Base/TayL.global_position.x < $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 10 and facing_right) or ($SpriteL/Base/TayL.global_position.x > $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 10 and !facing_right)):
				$AniArmRotate.play("Down")
			elif (($SpriteR/Base/TayL.global_position.x > $SpriteR/Skeleton/Body/UpperArmL.global_position.x + 20 and facing_right) or ($SpriteL/Base/TayL.global_position.x < $SpriteL/Skeleton/Body/UpperArmR.global_position.x - 20 and !facing_right)):
				$AniArmRotate.play("Up")
@export var focus = false
var eyes_speed = 0
var eyes_distance = 0
func emote():
	$SpriteL/Skeleton/Body/Head/Face/Lash.position.y = $SpriteR/Skeleton/Body/Head/Face2/Lash.position.y
	$SpriteL/Skeleton/Body/Head/Face/Lash.frame = $SpriteR/Skeleton/Body/Head/Face2/Lash.frame
	$SpriteL/Skeleton/Body/Head/Face/Brow.position.x = -$SpriteR/Skeleton/Body/Head/Face2/Brow.position.x
	$SpriteL/Skeleton/Body/Head/Face/Brow.position.y = $SpriteR/Skeleton/Body/Head/Face2/Brow.position.y
	$SpriteL/Skeleton/Body/Head/Face/Brow.rotation = -$SpriteR/Skeleton/Body/Head/Face2/Brow.rotation
	$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.global_rotation = $SpriteR/Skeleton/Body/Head/Face.global_rotation
	$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.global_rotation = $SpriteR/Skeleton/Body/Head/Face.global_rotation
	$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.x = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.x,clamp($BodyPos/HeadPos/EyesPos.position.x/64,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.y = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeR/PupilR.position.y,clamp($BodyPos/HeadPos/EyesPos.position.y/eyes_distance,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.x = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.x,clamp($BodyPos/HeadPos/EyesPos.position.x/64,-6,6),eyes_speed)
	$SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.y = lerpf($SpriteR/Skeleton/Body/Head/Face/EyeL/PupilL.position.y,clamp($BodyPos/HeadPos/EyesPos.position.y/eyes_distance,-6,6),eyes_speed)
	if !focus and $Weapon.wait or $Weapon.aim:
		eyes_speed = 0.2
		eyes_distance = 128
		$BodyPos/HeadPos/EyesPos.global_position = $Weapon/CrossHair.global_position
	elif $Weapon.reloading or $Weapon.switching:
		eyes_speed = 1
		eyes_distance = 64
		if $Weapon.current_gun == "SniperA":
			$BodyPos/HeadPos/EyesPos.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		else:
			$BodyPos/HeadPos/EyesPos.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
	elif $Weapon.fire_delay or Key.up or Key.down or sliding:
		eyes_distance = 64
		eyes_speed = 1
		$BodyPos/HeadPos/EyesPos.position = $Weapon/Rotation/Recoil/Position.position
	else:
		eyes_distance = 64
		eyes_speed = 1
		$BodyPos/HeadPos/EyesPos.global_position = $EyesPos2.global_position
	if $Weapon.fire_delay:
		$AniFace.play("Shoot")
	elif slash_delay:
		$AniFace.play("Shoot")
	elif ($Weapon.aim or Key.up or Key.down) and !$Weapon.fire_delay:
		$AniFace.play("Aim")
	elif $Weapon.wait:
		$AniFace.play("Focus")
	else:
		if $Weapon.reloading or $Weapon.switching:
			$AniFace.play("Ready")
		else:
			$AniFace.play("Normal")

var slash = false
var slash_time = 0.0
var slash_count = 1
var slash_delay = false
var blade_count = 0
var sword = true
var break_cool = 10
var break_charge = 0
var break_charging = false
func melee():
	slash_time = 0.8 * time
	$Melee.scale.x = facing
	if Key.attack_charge and !slash_delay and !$Melee/Heavy_delay.time_left > 0 and break_charge <= 60 and grounded and abs(velocity.x * time) < 1200:
		break_charge += 1
		if break_charge > 12:
			$AniMelee.play("Break_Charge")
			$AniSkill.play("Break_Charge")
			$Weapon.switch_count = 0
		break_charging = true
	else:
		if !$Melee/Heavy_delay.time_left > 0:
			$AniSkill.play("Off")
		if break_charge < 30:
			break_charge = 0
		break_charging = false
	if slash_count > 3:
		$Weapon.switch_count = 0
	if Key.attack and !slash_delay and ($Melee/Heavy_delay.time_left > 0 or !grounded or abs(velocity.x * time) > 1200) or (Key.attacked and !slash_delay and !$Melee/Heavy_delay.time_left > 0) or break_charge == 60:
		$Melee/Slash_delay.start(slash_time)
		if $Melee/Heavy_delay.time_left > 0 or break_charge < 30:
			blade_count += 1
			if slash_count < 6 and $Melee/Slash_delay.time_left > slash_time * 0.625:
				slash_count += 1
			else:
				slash_count -= 2
	if $Melee/Slash_delay.time_left > slash_time * 3/4:
		slash_delay = true
		$Weapon.wait = false
	else:
		slash_delay = false
	$Weapon.melee = slash_delay
	if $Melee/Slash_delay.time_left > 0 or $Melee/Heavy_delay.time_left > $Melee/Heavy_delay.wait_time - slash_time * 3/4 or break_charging:
		slash = true
	else:
		slash = false
	if !$Melee/Slash_delay.time_left > 0:
		if !break_charging:
			$AniMelee.play("Off")
		blade_count = 0
		slash_count = 0
	if slash_delay:
		if abs(velocity.x * time) > 1200 and !sliding:
			$AniMelee.play("Dash")
		elif sliding:
			$AniMelee.play("Slide")
		elif break_charge > 30:
			$AniSkill.play("Break_L")
			$AniMelee.play("Break_L")
			$Melee/Heavy_delay.start(break_cool * time)
			slash_count = 0
			break_charge = 0
		else:
			if slash_count == 1:
				$AniMelee.play("Quick_1")
			elif slash_count == 2:
				$AniMelee.play("Quick_2")
			elif slash_count == 3:
				$AniMelee.play("Quick_3")
			elif slash_count == 4:
				$AniMelee.play("Blade_1")
	if blade_count > 1:
		$Melee/CBlade.show()
	else:
		$Melee/CBlade.hide()
func part():
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
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor6.z_index = -1
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor7.z_index = -1
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor8.z_index = -1
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2.frame = 26
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2/Armor3.hide()
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 50
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 51
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
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor6.z_index = 0
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor7.z_index = 0
		$SpriteR/Skeleton/Body/UpperArmL/ArmL/Armor8.z_index = 0
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2.frame = 24
		$SpriteR/Skeleton/Body/UpperArmR/LowerArmR/ArmR2/Armor2/Armor3.show()
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 48
		$SpriteR/Skeleton/Body/UpperLegR/LegR.frame = 49
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor6.frame = 22
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor7.frame = 22
		$SpriteL/Skeleton/Body/UpperArmR/ArmR/Armor8.frame = 22
	$Weapon.crouch = crouching
	$Weapon.lay = lying
	$Weapon.lay_facing = facing_right
	if lying:
		if lying_up:
			if facing_right:
				$Weapon.position.x = lerpf($Weapon.position.x,$GunPos.position.x * facing,0.2)
			else:
				$Weapon.position.x = lerpf($Weapon.position.x,($GunPos.position.x + 40) * facing,0.2)
			$Weapon.position.y = $GunPos.position.y + ($SpriteR/Base/Body.global_position.y - $BodyPos.global_position.y)/2
		else:
			if !facing_right:
				$Weapon.position.x = lerpf($Weapon.position.x,$GunPos.position.x * facing,0.2)
			else:
				$Weapon.position.x = lerpf($Weapon.position.x,($GunPos.position.x - 40) * facing,0.2)
			$Weapon.position.y = $GunPos.position.y + ($SpriteL/Base/Body.global_position.y - $BodyPos.global_position.y)/2
	else:
		$Weapon.position.x = $GunPos.position.x * facing
		$Weapon.position.y = $GunPos.position.y
	if $Weapon.aim or $Weapon.fire_delay or $Weapon.reloading or Key.up or Key.down:
		$Weapon.wait = false
		$BodyPos2.global_position.x = $Weapon/Rotation/Recoil/Body.global_position.x - $Weapon.position.x
		$HeadPos2.global_position.x = $Weapon/Head/Rotate.global_position.x - $Weapon.position.x
	else:
		$BodyPos2.position.x = lerpf($BodyPos2.position.x,0,0.2)
		$HeadPos2.position.x = lerpf($HeadPos2.position.x,0,0.2)
	if grounded and !sliding and !foot_stuck and !lying and !dashing:
		$FootR.disabled = false
		$FootL.disabled = false
		if facing_right:
			$FootR.global_position.x = $SpriteR/Base/LegR.global_position.x
			$FootR.global_position.y = $SpriteR/Base/LegR.global_position.y - 33
			$FootL.global_position.x = $SpriteR/Base/LegL.global_position.x
			$FootL.global_position.y = $SpriteR/Base/LegL.global_position.y - 33
		else:
			$FootR.global_position.x = $SpriteL/Base/LegR.global_position.x
			$FootR.global_position.y = $SpriteL/Base/LegR.global_position.y - 33
			$FootL.global_position.x = $SpriteL/Base/LegL.global_position.x
			$FootL.global_position.y = $SpriteL/Base/LegL.global_position.y - 33
	else:
		$FootR.disabled = true
		$FootL.disabled = true
	$Grounded.position = $LegCollision.position
	$Ouch.position.y = $LegCollision.position.y - 228
	$DashCollision.disabled = !dashing
	$DashCollision.scale.x = facing
	$CantDash.scale.x = facing
	$HitBox/Leg.position.y = $LegCollision.position.y - 42
	$HitBox/Body.global_position = $BaseCollision.global_position
	$HitBox/Body.rotation = $BaseCollision.rotation
	$Climb.position.x = 20 * facing
	$CantClimb.position.x = 40 * facing
	$SpriteR/Skeleton/Body/Cloth2.global_position = $SpriteR/Skeleton/Body/UpperArmL/LowerArmL.global_position
	$SpriteL/Skeleton/Body/Cloth2.global_position = $SpriteL/Skeleton/Body/UpperArmR/LowerArmR.global_position
	$SpriteR/Skeleton/Dress2.global_position = $SpriteR/Skeleton/Body/UpperLegL/LowerLegL.global_position
	$SpriteL/Skeleton/Dress2.global_position = $SpriteL/Skeleton/Body/UpperLegL/LowerLegL.global_position
	if sliding:
		$CakeCollision.disabled = true
		if !$Weapon.aim and !$Weapon.fire_delay and !Key.up and !Key.down:
			$Weapon.slide = true
		else:
			$Weapon.slide = false
	elif crouching or lying:
		if crouching:
			safe_margin = 5
		else:
			safe_margin = 1
		$CakeCollision.disabled = true
		$Weapon.slide = false
	else:
		safe_margin = 0.05
		$CakeCollision.disabled = false
		$Weapon.slide = false
	if !$Weapon.bare and (abs(velocity.x * time) < 1200 or sliding) and !(slash and slash_count > 3):
		$SpriteR/Base/TayR.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		$SpriteR/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
		$SpriteL/Base/TayR.global_position = $Weapon/Rotation/Recoil/Body/ArmR.global_position
		$SpriteL/Base/TayR/LAR.global_position = $Weapon/Rotation/Recoil/Body/ArmR/HandR.global_position
	if slash:
		if $Melee/Slash_delay.time_left > 0.4 or break_charging and break_charge > 12 or $Melee/Heavy_delay.time_left > $Melee/Heavy_delay.wait_time - slash_time * 3/4:
			$SpriteR/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteR/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
			$SpriteL/Base/TayL.global_position = $Melee/HandL.global_position
			$SpriteL/Base/TayL/LAL.global_position = $Melee/HandL/HandL2.global_position
			if break_charging and break_charge > 12 or $Melee/Heavy_delay.time_left > $Melee/Heavy_delay.wait_time - slash_time * 3/4:
				$SpriteR/Base/TayR.global_position = $Melee/HandR.global_position
				$SpriteR/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
				$SpriteL/Base/TayR.global_position = $Melee/HandR.global_position
				$SpriteL/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
		else:
			if !$Weapon.bare:
				$SpriteR/Base/TayL.global_position.x = lerpf($SpriteR/Base/TayL.global_position.x,$Weapon/Rotation/Recoil/Body/ArmL.global_position.x,0.5)
				$SpriteR/Base/TayL.global_position.y = lerpf($SpriteR/Base/TayL.global_position.y,$Weapon/Rotation/Recoil/Body/ArmL.global_position.y,0.5)
				$SpriteR/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
				$SpriteL/Base/TayL.global_position.x =  lerpf($SpriteL/Base/TayL.global_position.x,$Weapon/Rotation/Recoil/Body/ArmL.global_position.x,0.5)
				$SpriteL/Base/TayL.global_position.y =  lerpf($SpriteL/Base/TayL.global_position.y,$Weapon/Rotation/Recoil/Body/ArmL.global_position.y,0.5)
				$SpriteL/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
		if slash_count > 3:
			$SpriteR/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteR/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
			$SpriteL/Base/TayR.global_position = $Melee/HandR.global_position
			$SpriteL/Base/TayR/LAR.global_position = $Melee/HandR/HandR2.global_position
	if !$Weapon.bare and (abs(velocity.x * time) < 1200 or sliding) and !climb and !$ClimbTimer.time_left > 0 and !slash or $Weapon.throwing:
		$SpriteR/Base/TayL.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
		$SpriteR/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
		$SpriteL/Base/TayL.global_position = $Weapon/Rotation/Recoil/Body/ArmL.global_position
		$SpriteL/Base/TayL/LAL.global_position = $Weapon/Rotation/Recoil/Body/ArmL/HandL.global_position
	if grounded:
		foot_position_r = lerpf(foot_position_r,$FootCastR.get_collision_point().y - global_position.y,0.1)
		foot_position_l = lerpf(foot_position_l,$FootCastL.get_collision_point().y - global_position.y,0.1)
		foot_distance = clampf(foot_position_r - foot_position_l,-60,60)
		$RotateC.look_at($FootCastL.get_collision_point())
		$RotateC.position.y = (foot_position_l + foot_position_r)/2
		$FootRotate.global_rotation_degrees = clampf(lerpf($FootRotate.global_rotation_degrees,$RotateC.global_rotation_degrees,0.2),-45,45)
	else:
		foot_distance = 0
		$RotateC.rotation = lerpf($RotateC.rotation,0,0.2)
	if grounded and !sliding and !lying and !dashing:
		if abs(velocity.x * time) < 200:
			if abs(int(foot_distance)) > foot_distance/5 + 5:
				if abs(int(foot_distance)) > foot_distance/5 + 25:
					if crouching:
						$LegCollision.position.y = lerpf($LegCollision.position.y,60 - abs(int(foot_distance))/4,0.2)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,142 - abs(int(foot_distance))/4,0.2)
				else:
					if crouching:
						$LegCollision.position.y = lerpf($LegCollision.position.y,90 - abs(int(foot_distance))/4,0.2)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,146 - abs(int(foot_distance))/4,0.2)
			else:
				if crouching:
					$LegCollision.position.y = lerpf($LegCollision.position.y,62,0.5)
				else:
					if $Weapon.bare and !break_charging:
						$LegCollision.position.y = lerpf($LegCollision.position.y,158,0.2)
					elif break_charging and break_charge > 12:
						$LegCollision.position.y = lerpf($LegCollision.position.y,120,0.2)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,150,0.2)
		else:
			if crouching:
				$LegCollision.position.y = lerpf($LegCollision.position.y,90,0.1)
			else:
				$LegCollision.position.y = lerpf($LegCollision.position.y,135,0.1)
	else:
		if sliding:
			if $SlideTimer.wait_time > slide_time:
				if $AniBody.current_animation_position > 1:
					if $Ouch.is_colliding() and grounded:
						$LegCollision.position.y = lerpf($LegCollision.position.y,62,0.5)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,158,0.05)
				else:
					$LegCollision.position.y = lerpf($LegCollision.position.y,42,0.5)
			else:
				if $AniBody.current_animation_position > 0.4:
					if $Ouch.is_colliding() and grounded:
						$LegCollision.position.y = lerpf($LegCollision.position.y,62,0.5)
					else:
						$LegCollision.position.y = lerpf($LegCollision.position.y,158,0.05)
				else:
					$LegCollision.position.y = lerpf($LegCollision.position.y,42,0.5)
		elif dash_left and !sliding or dash_right and !sliding:
			if dashing:
				$LegCollision.position.y = 90
			elif $Ouch.is_colliding() and abs(velocity.x * time) < 400:
				crouching = true
				$DashCollision.disabled = true
				$LegCollision.position.y = lerpf($LegCollision.position.y,62,0.5)
			else:
				$LegCollision.position.y = 105
		elif lying:
			$LegCollision.position.y = lerpf($LegCollision.position.y,45,0.2)
		else:
			$LegCollision.position.y = lerpf($LegCollision.position.y,158,0.2)
	if abs(velocity.x * time) > 1200 and !sliding:
		$BaseCollision.position.x = 70 * facing
		$BaseCollision.position.y = 0
		$BaseCollision.rotation_degrees = 40 * facing
	elif crouching:
		$Lay.enabled = false
		$BaseCollision.position.y = -40
		$BaseCollision.position.x = 70 * facing
		$BaseCollision.rotation_degrees = 40 * facing
	elif lying:
		$Lay.enabled = true
		if facing_right:
			if $Weapon.facing_right:
				$Weapon/Idle.position.x = 0
			else:
				$Weapon/Idle.position.x = -40
		else:
			if $Weapon.facing_right:
				$Weapon/Idle.position.x = 40
			else:
				$Weapon/Idle.position.x = 0
		if facing_right:
			$BaseCollision.position.x = -65
		else:
			$BaseCollision.position.x = 65
		$BaseCollision.position.y = 44
	else:
		$Lay.enabled = false
		$BaseCollision.position.x = 0
		$BaseCollision.position.y = -65
		$BaseCollision.rotation_degrees = 0
		$SpriteR.position.x = lerpf($SpriteR.position.x,0,0.2)
		$SpriteL.position.x = lerpf($SpriteL.position.x,0,0.2)
		$SpriteR.position.y = lerpf($SpriteR.position.y,0,0.2)
		$SpriteL.position.y = lerpf($SpriteL.position.y,0,0.2)
	if ($Weapon.aim or $Weapon.block or Key.up or Key.down or lying) and !$Weapon.bare or $Weapon.throwing:
		$SpriteR/Skeleton/Body/UpperArmL.z_index = 1
		$SpriteL/Skeleton/Body/UpperArmR.z_index = -1
	elif $Melee/Slash_delay.time_left > 0.4 and abs(velocity.x * time) < 1200:
		$SpriteR/Skeleton/Body/UpperArmL.z_index = 2
		$SpriteL/Skeleton/Body/UpperArmR.z_index = -1
	else:
		$SpriteR/Skeleton/Body/UpperArmL.z_index = -1
		$SpriteL/Skeleton/Body/UpperArmR.z_index = 1
	if !$Weapon.bare:
		$SpriteR/Skeleton/Body/UpperArmL/LowerArmL.z_index = $Weapon.gun.get_node("Body/HandL").z_index
		$SpriteL/Skeleton/Body/UpperArmR/LowerArmR.z_index = $Weapon.gun.get_node("Body/HandL").z_index * -1
func ui():
	if !Inventory.hawk or count_jump > 0:
		$Control/Jump.max_value = jump_time
		$Control/Jump.value = count_jump
	else:
		$Control/Jump.max_value = fly_time
		$Control/Jump.value = count_fly
	$UI/Stat/HP.value = hp
	if !$Weapon.bare:
		if $Weapon.fire_delay:
			$UI/Weapon/AmmoBar.value = $Weapon.current_ammo
		else:
			if $UI/Weapon/AmmoBar.value < $Weapon.current_ammo:
				$UI/Weapon/AmmoBar.value += 1
			elif $UI/Weapon/AmmoBar.value > $Weapon.current_ammo:
				$UI/Weapon/AmmoBar.value -= 1
		if $Weapon.current_gun == "RifleA" and $Weapon.gun.mode:
			$UI/Weapon/CurrentAmmo.text = str(Inventory.rocket_ammo)
			$UI/Weapon/ReverseAmmo.text = str("/-")
		else:
			$UI/Weapon/CurrentAmmo.text = str($Weapon.current_ammo)
			$UI/Weapon/ReverseAmmo.text = str("/",$Weapon.reverse_ammo)
		$UI/Weapon/Gun.show()
		if $Weapon.current_gun == "PistolA":
			$UI/Weapon/Gun.frame = 1
		elif $Weapon.current_gun == "PistolB":
			$UI/Weapon/Gun.frame = 3
		elif $Weapon.current_gun == "PistolC":
			$UI/Weapon/Gun.frame = 5
		elif $Weapon.current_gun == "PistolD":
			$UI/Weapon/Gun.frame = 7
		elif $Weapon.current_gun == "RifleA":
			$UI/Weapon/Gun.frame = 9
		elif $Weapon.current_gun == "RifleB":
			$UI/Weapon/Gun.frame = 11
		elif $Weapon.current_gun == "RifleC":
			$UI/Weapon/Gun.frame = 13
		elif $Weapon.current_gun == "DMR":
			$UI/Weapon/Gun.frame = 15
		elif $Weapon.current_gun == "LMG":
			$UI/Weapon/Gun.frame = 17
		elif $Weapon.current_gun == "SMGA":
			$UI/Weapon/Gun.frame = 19
		elif $Weapon.current_gun == "SMGB":
			$UI/Weapon/Gun.frame = 21
		elif $Weapon.current_gun == "SMGC":
			$UI/Weapon/Gun.frame = 23
		elif $Weapon.current_gun == "ShotgunA":
			$UI/Weapon/Gun.frame = 25
		elif $Weapon.current_gun == "ShotgunB":
			$UI/Weapon/Gun.frame = 27
		elif $Weapon.current_gun == "ShotgunC":
			$UI/Weapon/Gun.frame = 29
		elif $Weapon.current_gun == "SniperA":
			$UI/Weapon/Gun.frame = 31
		elif $Weapon.current_gun == "SniperB":
			$UI/Weapon/Gun.frame = 33
		elif $Weapon.current_gun == "LauncherA":
			$UI/Weapon/Gun.frame = 35
	else:
		$UI/Weapon/Gun.hide()
	if $Weapon.current_lethal == $Weapon.frag:
		$UI/Weapon/Slot1/Lethal.frame = 0
		$UI/Weapon/Slot1/Left.value = Inventory.frag
	elif $Weapon.current_lethal == $Weapon.fire:
		$UI/Weapon/Slot1/Lethal.frame = 1
		$UI/Weapon/Slot1/Left.value = Inventory.fire
	elif $Weapon.current_lethal == $Weapon.knife:
		$UI/Weapon/Slot1/Lethal.frame = 4
		$UI/Weapon/Slot1/Left.value = Inventory.knife
	if $Weapon.current_tactical == $Weapon.smoke:
		$UI/Weapon/Slot2/Tactical.frame = 2
		$UI/Weapon/Slot2/Left.value = Inventory.smoke
	elif $Weapon.current_tactical == $Weapon.flash:
		$UI/Weapon/Slot2/Tactical.frame = 3
		$UI/Weapon/Slot2/Left.value = Inventory.flash
	if sliding:
		$Control/Slide.max_value = $SlideTimer.wait_time * 100
		$Control/Slide.value = $SlideTimer.time_left * 100
	elif dashing:
		$Control/Slide.max_value = $DashTimer.wait_time * 100
		$Control/Slide.value = $DashTimer.time_left * 100
	else:
		if $DashCool.time_left > 0:
			$Control/Slide.max_value = $DashCool.wait_time * 100
			$Control/Slide.value = $DashCool.wait_time * 100 - $DashCool.time_left * 100 
		else:
			$Control/Slide.value = lerpf($Control/Slide.value,$Control/Slide.max_value,0.5)
	$UI/Skill1/Left.value = invisible_time/2
	$UI/Skill2/Left.value = raze_time/2
	$UI/Skill3/Left.value = 80 - $Melee/Heavy_delay.time_left * 10
	if invisible_cool > 0:
		invisible_cool -= 1
		$UI/Skill1/Skill.modulate = Color8(255,255,255,80)
	else:
		$UI/Skill1/Skill.modulate = Color8(255,255,255,255)
	if raze_cool > 0:
		raze_cool -= 1
		$UI/Skill2/Skill.modulate = Color8(255,255,255,80)
	else:
		$UI/Skill2/Skill.modulate = Color8(255,255,255,255)
	if $Melee/Heavy_delay.time_left > 0 or !sword or abs(velocity.x * time) > 1200:
		$UI/Skill3/Skill.frame = 8
	else:
		$UI/Skill3/Skill.frame = 9
var hp = 100
var flash = false
var flash_time = 0
func stat():
	if hp < 100:
		hp += 0.1
	if flash:
		$UI/Flash.show()
		flash_time += 1
	else:
		$UI/Flash.hide()
	if flash_time > 50:
		flash = false
		flash_time = 0

func hurt(body):
	if body.is_in_group("danger") and !body.is_in_group("bullet"):
		hp -= body.dmg
	elif body.is_in_group("bullet"):
		hp -= body.dmg/4
	if body.is_in_group("flash"):
		if body.trigged:
			flash = true
			$UI/Anim.stop()
			$UI/Anim.play("Flash")
