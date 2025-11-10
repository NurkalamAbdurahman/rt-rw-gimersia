extends Node

signal stats_updated

var health: int = 6
var coins: int = 0
var silver_keys: int = 0
var golden_keys: int = 0 
var pity: int = 0
var max_pity: int = 3

func set_health(value: int):
	health = clamp(value, 0, 100)
	emit_signal("stats_updated")

func add_coin(amount: int = 1):
	coins += amount
	emit_signal("stats_updated")
	
func add_golden_key(amount: int = 1):
	golden_keys += amount
	emit_signal("stats_updated")
	
func add_silver_key(amount: int = 1):
	silver_keys += amount
	emit_signal("stats_updated")

func add_pity(amount: int) :
	pity += amount
	print(pity)
	emit_signal("stats_updated")
