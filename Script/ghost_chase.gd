extends CanvasLayer

func ghost_success():
	print("Player selamat! +3 coins")
	GameData.add_coin(3)

func ghost_failed():
	print("Player tertangkap! -1 coin")
	if GameData.coins > 0:
		GameData.coins -= 1
		GameData.emit_signal("stats_updated")
