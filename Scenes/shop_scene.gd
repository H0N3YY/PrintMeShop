extends Node2D

@onready var customer_sprite: TextureRect = $LeftCustomerPanel/CustomerSprite
@onready var product_select: OptionButton = $ShopWorkArea/ProductPanel/ProductSelect
@onready var color_select: OptionButton = $ShopWorkArea/ColorPanel/ColorSelect
@onready var merch_select: OptionButton = $ShopWorkArea/MerchPanel/MerchSelect
@onready var result_label: Label = $ShopWorkArea/ResultPanel/ResultLabel
@onready var cancel_button: Button = $ShopWorkArea/CancelButton
@onready var confirm_button: Button = $ShopWorkArea/ConfirmButton

var customers = [
	{
		"name": "Gotka",
		"texture": "res://assets/characters/gotka.png"
	},
	{
		"name": "Oscar",
		"texture": "res://assets/characters/oscar.png"
	}
]

var customer_index := 0

var products = [
	"Koszulka", "Przypinka", "Torba",
	"Breloczek", "Skarpetki", "Naklejki",
	"Kocie uszka", "Plakat", "Czapka"
]

var colors = [
	"Biały", "Czarny", "Różowy",
	"Czerwony", "Niebieski", "Zielony",
	"Pomarańczowy", "Żółty", "Szary"
]

var designs = [
	"Kruk z Love and Deepspace",
	"Ideis",
	"Poro",
	"Kukuryniarz",
	"Fat Cat",
	"Hello IT",
    "Hatsune Miku"
]

func _ready() -> void:
	setup_options()

	product_select.item_selected.connect(_on_selection_changed)
	color_select.item_selected.connect(_on_selection_changed)
	merch_select.item_selected.connect(_on_selection_changed)

	cancel_button.pressed.connect(reset_order)
	confirm_button.pressed.connect(confirm_order)

	show_customer()
	update_preview()


func setup_options() -> void:
	for item in products:
		product_select.add_item(item)

	for item in colors:
		color_select.add_item(item)

	for item in designs:
		merch_select.add_item(item)


func show_customer() -> void:
	var customer = customers[customer_index]

	var texture = load(customer["texture"])

	if texture:
		customer_sprite.texture = texture

	print("Nowy klient: ", customer["name"])


func _on_selection_changed(_index: int) -> void:
	update_preview()


func update_preview() -> void:
	var product = product_select.get_item_text(
		product_select.selected
	)

	var color = color_select.get_item_text(
		color_select.selected
	)

	var design = merch_select.get_item_text(
		merch_select.selected
	)

	result_label.text = (
		"Produkt: " + product +
		"\nKolor: " + color +
		"\nNadruk: " + design
	)


func reset_order() -> void:
	product_select.select(0)
	color_select.select(0)
	merch_select.select(0)

	update_preview()


func confirm_order() -> void:
	print("Zamówienie zatwierdzone!")

	customer_index += 1

	if customer_index >= customers.size():
		customer_index = 0

	show_customer()
	reset_order()
