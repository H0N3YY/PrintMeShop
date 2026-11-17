
extends Node2D

@onready var customer_sprite: TextureRect = $LeftCustomerPanel/CustomerSprite

@onready var product_panel: Control = $ShopWorkArea/ProductPanel
@onready var color_panel: Control = $ShopWorkArea/ColorPanel
@onready var merch_select: ItemList = $ShopWorkArea/MerchPanel/MerchSelect
@onready var result_label: Label = $ShopWorkArea/ResultPanel/ResultLabel
@onready var cancel_button: Button = $ShopWorkArea/CancelButton
@onready var confirm_button: Button = $ShopWorkArea/ConfirmButton


# Klienci
var customers = [
	{
		"name": "Gotka",
		"texture": "res://assets/characters/gotka.png"
	},
	{
		"name": "Oskar",
		"texture": "res://assets/characters/oskar.png"
	}
]

var customer_index: int = 0


# Produkty przypisane do nazw przycisków
var products = {
	"brelok_btn": "Breloczek",
	"skarpety_btn": "Skarpetki",
	"naklejki_btn": "Naklejki",
	"koszulka_btn": "Koszulka",
	"pin_btn": "Przypinka",
	"torba_btn": "Torba",
	"kubek_btn": "Kubek",
	"plakat_btn": "Plakat",
	"czapka_btn": "Czapka"
}


# Kolory przypisane do nazw przycisków
var colors = {
	"white": "Biały",
	"black": "Czarny",
	"pink": "Różowy",
	"red": "Czerwony",
	"blue": "Niebieski",
	"green": "Zielony",
	"orange": "Pomarańczowy",
	"yellow": "Żółty"
}


var designs = [
	"Love and Deepspace",
	"Ideis",
	"Leaguage Of Legends",
	"Kukuryniarz",
	"Cute Cats",
	"Hello IT",
	"Hatsune Miku",
	"My Little Pony",
	"Egzorcysta",
	"Piwo Janka",
	"Roblox",
	"Skolim"
]


# Aktualne zamówienie
var selected_product: String = ""
var selected_color: String = ""
var selected_design: String = ""


func _ready() -> void:
	setup_product_buttons()
	setup_color_buttons()
	setup_merch_options()

	merch_select.item_selected.connect(_on_merch_selected)

	cancel_button.pressed.connect(reset_order)
	confirm_button.pressed.connect(confirm_order)

	show_customer()
	update_preview()


# ---------------------------------------
# Merch Products
# ---------------------------------------

func setup_product_buttons() -> void:
	for button_name in products:
		var button = product_panel.get_node_or_null(button_name) as Button

		if button == null:
			push_warning("Nie znaleziono przycisku produktu: " + button_name)
			continue

		button.pressed.connect(
			_on_product_pressed.bind(products[button_name])
		)


func _on_product_pressed(product_name: String) -> void:
	selected_product = product_name

	print("Wybrano produkt: ", selected_product)
	update_preview()


# ---------------------------------------
# Colors
# ---------------------------------------

func setup_color_buttons() -> void:
	for button_name in colors:
		var button = color_panel.get_node_or_null(button_name) as Button

		if button == null:
			push_warning("Nie znaleziono przycisku koloru: " + button_name)
			continue

		button.pressed.connect(
			_on_color_pressed.bind(colors[button_name])
		)


func _on_color_pressed(color_name: String) -> void:
	selected_color = color_name

	print("Wybrano kolor: ", selected_color)
	update_preview()


# ---------------------------------------
# Merch Logos
# ---------------------------------------

func setup_merch_options() -> void:
	merch_select.clear()

	for design in designs:
		merch_select.add_item(design)


func _on_merch_selected(index: int) -> void:
	selected_design = merch_select.get_item_text(index)
	update_preview()


# ---------------------------------------
# Review Order
# ---------------------------------------

func update_preview() -> void:
	var product_text = selected_product
	var color_text = selected_color
	var design_text = selected_design

	if product_text == "":
		product_text = "Nie wybrano"

	if color_text == "":
		color_text = "Nie wybrano"

	if design_text == "":
		design_text = "Nie wybrano"

	result_label.text = (
		"Produkt: " + product_text +
		"\nKolor: " + color_text +
		"\nNadruk: " + design_text
	)


# ---------------------------------------
# Reset Order
# ---------------------------------------

func reset_order() -> void:
	selected_product = ""
	selected_color = ""
	selected_design = ""

	merch_select.deselect_all()

	update_preview()

	print("Zamówienie wyczyszczone")


# ---------------------------------------
# Accept Order
# ---------------------------------------

func confirm_order() -> void:
	if selected_product == "":
		print("Najpierw wybierz produkt!")
		return

	if selected_color == "":
		print("Najpierw wybierz kolor!")
		return

	if selected_design == "":
		print("Najpierw wybierz nadruk!")
		return

	print("Zamówienie zatwierdzone!")
	print("Produkt: ", selected_product)
	print("Kolor: ", selected_color)
	print("Nadruk: ", selected_design)

	next_customer()


# ---------------------------------------
# Clients
# ---------------------------------------

func show_customer() -> void:
	var customer = customers[customer_index]

	var texture = load(customer["texture"]) as Texture2D

	if texture != null:
		customer_sprite.texture = texture
	else:
		customer_sprite.texture = null
		push_warning("Nie znaleziono grafiki klienta: " + customer["texture"])

	print("Nowy klient: ", customer["name"])


func next_customer() -> void:
	customer_index += 1

	if customer_index >= customers.size():
		customer_index = 0

	show_customer()
	reset_order()
