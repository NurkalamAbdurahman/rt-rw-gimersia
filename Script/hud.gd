extends CanvasLayer

@onready var damage: Button = $Damage
@onready var coin__1: Button = $"Coin +1"
@onready var golden_key: Button = $goldenKey
@onready var silver_key: Button = $SilverKey


func _ready():
	damage.pressed.connect(_on_damage_pressed)
	coin__1.pressed.connect(_on_add_coin_pressed)
	golden_key.pressed.connect(_on_add_golden_key_pressed)
	silver_key.pressed.connect(_on_add_silver_key_pressed)

func _on_damage_pressed():
	GameData.health -= 1
	GameData.emit_signal("stats_updated")
	
func _on_add_coin_pressed():
	GameData.add_coin(1)
	print("Coins now:", GameData.coins)
	
func _on_add_golden_key_pressed():
	GameData.add_golden_key(1)
	print("Golden keys now:", GameData.golden_keys)
	
func _on_add_silver_key_pressed():
	GameData.add_silver_key(1)
	print("Silver keys now:", GameData.silver_keys)
