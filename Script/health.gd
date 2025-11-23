extends Control

@onready var hearts_container: Control = $HeartsContainer

func _ready():
	_update_hearts()
	GameData.connect("stats_updated", Callable(self, "_update_hearts"))

func _update_hearts():
	var max_hearts = hearts_container.get_child_count()  
	var total_health = GameData.health                   
	var hp_per_heart = 2                                

	for i in range(max_hearts):
		var heart_node = hearts_container.get_child(i)

		var full = heart_node.get_node("HpFull")
		var half = heart_node.get_node("HpHalf")
		var empty = heart_node.get_node("HpNothing")

		var heart_hp = total_health - (i * hp_per_heart)

		# tampilkan sprite sesuai HP
		if heart_hp >= 2:
			full.visible = true
			half.visible = false
			empty.visible = false
		elif heart_hp == 1:
			full.visible = false
			half.visible = true
			empty.visible = false
		else:
			full.visible = false
			half.visible = false
			empty.visible = true
