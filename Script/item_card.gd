extends Panel

@onready var item_name: Label = $ItemName
@onready var item_price: Label = $ItemPrice
@onready var buy_button: Button = $BuyButton

var item_data = {}

func setup(data):
	item_data = data
	item_name.text = data.name
	item_price.text = str(data.price) + " Coin"

func _on_BuyButton_pressed():

	print("Membeli:", item_data.name)
	
