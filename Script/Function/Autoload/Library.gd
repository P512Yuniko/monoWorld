extends Node

func named(code: int):
	match code:
		100: return "P54 Pistol"
		101: return "EM50 Pistol"
		102: return "P15-C Pistol"
		103: return "STA9 Pistol"
		104: return "B5Q-C SMG"
		105: return "G7Q-A SMG"
		106: return "B9Q-PD SMG"
		110: return "Spec556 AR"
		111: return "KR762 AR"
		112: return "BPF556 AR"
		113: return "ST28 BR"
		114: return "HG48 LMG"
		120: return "BK12 SG"
		121: return "VH12 SG"
		122: return "TB12-C SG"
		130: return "SK11 SR"
		131: return "SVC8 SR"
		140: return "RL85 Launcher"
		270: return "FRAG"
		271: return "FIRE"
		272: return "KNIFE"
		273: return "MINE"
		274: return "SMOKE"
		275: return "FLASH"
		276: return "GRAVITY"
		277: return "DECOY"
		20: return "Light Ammo"
		21: return "Heavy Ammo"
		22: return "Shotgun Ammo"
		23: return "Sniper Ammo"
		24: return "Launcher Ammo"
		25: return "Shield RAM"
		26: return "Aid Battery"
		30: return "Ammunition"
		31: return "Recon UAV"
		32: return "Thunderbolt"
		33: return "Aerial Cluster"
		34: return "Fire Carpet"
		35: return "Dead Drop"
		36: return "Instant Exfill"

func cost(code):
	match code:
		25: return 250
		26: return 150
		30: return 1000
		31: return 3000
		32: return 5000
		33: return 5000
		34: return 5000
		35: return 8000
		36: return 10000

func loadout(code):
	match code:
		0: return [102015001010,103018003010,104030113010,105050110110].pick_random()
		1: return [110030210010,111030122000,113015313000].pick_random()
		2: return 120007000001
		3: return 130005000000

func control(code):
	match code:
		0: return "ON"
		1: return "OFF"
		2: return "TOGGLE"
		3: return "HOLD"
		4: return "EXPAND"
		5: return "COLLAPSE"

func description(code):
	pass
