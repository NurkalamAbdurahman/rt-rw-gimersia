extends Node

signal stats_updated

var health: int = 6
var max_health: int = 7
var coins: int = 0
var silver_keys: int = 3
var golden_keys: int = 0
var skull_keys: int = 0
var pity: int = 0
var max_pity: int = 3
var potion: int = 0

func set_health(value: int):
	health = clamp(value, 0, 100)
	emit_signal("stats_updated")

func add_coin(amount: int = 1):
	coins += amount
	emit_signal("stats_updated")

func add_potion(amount: int = 1):
	potion += amount
	health += 1
	emit_signal("stats_updated")

func check_if_max_health():
	if health >= max_health:
		health = 6
		print("true")
		print(health)
		emit_signal("stats_updated")

func add_golden_key(amount: int = 1):
	golden_keys += amount
	emit_signal("stats_updated")
	
func add_skull_key(amount: int = 1):
	skull_keys += amount
	emit_signal("stats_updated")
	
func add_silver_key(amount: int = 1):
	silver_keys += amount
	emit_signal("stats_updated")

func add_pity(amount: int) :
	pity += amount
	print(pity)
	emit_signal("stats_updated")
