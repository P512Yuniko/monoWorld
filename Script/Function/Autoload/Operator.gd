extends Node

signal shake
signal portal_ready
signal portal_connect
signal break_charge

var conqueror = []

var traveni = true
var dmg_dealt = 0
var crosshair
var first_portal
var second_portal
var portal_placed = false
var portal_facing = 1
var prism = 0
var taken_prism = 0

func hit(id,dmg):
	if conqueror.size() > 0:
		for i in conqueror:
			if i.id == id:
				conqueror[conqueror.find(i)].operator.hit(dmg)
func kill(id,type):
	if conqueror.size() > 0:
		for i in conqueror:
			if i.id == id:
				conqueror[conqueror.find(i)].operator.kill(type)
func slash(id,dmg):
	if conqueror.size() > 0:
		for i in conqueror:
			if i.id == id:
				conqueror[conqueror.find(i)].operator.slash(dmg)
