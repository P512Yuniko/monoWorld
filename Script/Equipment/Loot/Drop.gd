extends RigidBody2D

@export var code = int()
var key = []
@export var node = "100000OFMMLS"
var rarity = 0
#code format: 012345678900 (muoi hai chu so)
#11 kind: sung, dan, giap, mau
#10 9 class: sung nao, dan nao
#8 7 6 so luong HAI CHU SO: bao nhieu dan, 00, 01, 22, 60,...
#5 optics: 0, 1, 2, 3
#4 foregrip: 0, 1, 2, 3(launcher)
#3 muzzle: 0, 1, 2, 3
#2 mag: 0, 1, 2
#1 laser: 0, 1
#0 stock: 0, 1
func split(codes: int) -> Array:
	while codes > 0:
		var element = codes % 10
		key.insert(0,element)
		codes = codes / 10
	return key
func _ready():
	split(code)
	rarity = 0
	if key[0] == 1 and (key[1] > 0 or key[1] == 0 and key[2] > 3):
		$Pad.frame = 1
		$CollisionShape2D.shape.size = Vector2(128,64)
		$Gun.scale = Vector2(0.5,0.5)
		$Ammo.position = Vector2(-40,8)
		$Ammo.scale = Vector2(1,1)
		$Label.position.x = 8
	else:
		$Pad.frame = 0
		$CollisionShape2D.shape.size.x = 64
		$Gun.scale = Vector2(0.75,0.75)
		$Ammo.position = Vector2(0,0)
		$Ammo.scale = Vector2(1.5,1.5)
		$Label.position.x = -28
	match key[0]:
		1:
			$Gun.show()
			$Ammo.show()
			$Item.hide()
			$Nade.hide()
			$Label.text = str(int(str(key[3],key[4], key[5])))
			$Ammo.frame = key[1]
			$Ammo.modulate.a = 0.7
			$Gun.frame = int(str(key[1]) + str(key[2]))
			rarity = 0
			for i in [key[6],key[7],key[8],key[9],key[10],key[11]]:
				if i > 0:
					rarity += 1
			if rarity < 5:
				$Gun.modulate = Color(0.7,0.7,0.7)
		2:
			$Gun.hide()
			$Item.hide()
			match key[1]:
				7:
					$Nade.show()
					$Ammo.hide()
					$Nade.frame = key[2]
					$Label.text = ""
				_:
					$Nade.hide()
					$Ammo.show()
					$Ammo.frame = key[1]
					$Ammo.modulate.a = 1
					$Label.text = str(int(str(key[2],key[3], key[4])))
		4:
			$Gun.hide()
			$Ammo.hide()
			$Item.show()
			$Nade.hide()
			$Item.hide()
			$Label.text = str("$",key[1],key[2],key[3],key[4],key[5],key[6])
		8:
			$Gun.hide()
			$Ammo.hide()
			$Item.show()
			$Nade.hide()
			$Item.frame = key[1]
			$Label.text = ""
		_:
			$Gun.hide()
			$Ammo.hide()
			$Item.show()
			$Nade.hide()
			$Item.frame = key[0] - 4
			$Label.text = ""
			match key[1]:
				5: rarity = 2
				6: rarity = 3
				_: rarity = 1
