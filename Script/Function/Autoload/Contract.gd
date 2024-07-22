extends Node

var contract = []
var cash = []
var compeleted = []
var fail = []
var time = []
var progress = []

func update():
	for i in progress:
		if i == 0:
			compeleted.append(progress.find(i))
	for i in compeleted:
		if contract.has(i):
			Inventory.cash += cash[contract.find(i)]
			contract.erase(i)
	for i in fail:
		if contract.has(i):
			contract.erase(i)
		
