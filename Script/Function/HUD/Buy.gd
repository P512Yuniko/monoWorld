extends Button

@export var code = 0
var price = 0
var rarity = 0
var key = []
var gun = 0
func _ready():
	if code > 2 and code < 20:
		$Sprite2D2.frame = code - 5
	if code > 20:
		gun = Library.loadout(code - 100)
		split(gun)
		$Gun.frame = int(str(key[1]) + str(key[2]))
		$Type.frame = key[1]
		rarity = 0
		for i in [key[6],key[7],key[8],key[9],key[10],key[11]]:
			if i > 0:
				rarity += 1
		$Rarity.value = rarity
		$Name.text = Library.named(int(str(1) + str(key[1]) + str(key[2])))
		price = 2500
		$Price.text = "$2500"
	else:
		$Price.text = str("$",Library.cost(int(code + 25)))
		price = Library.cost(int(code + 25))
		$Name.text = Library.named(int(code + 25))
func split(codes: int) -> Array:
	while codes > 0:
		var element = codes % 10
		key.insert(0,element)
		codes = codes / 10
	return key
