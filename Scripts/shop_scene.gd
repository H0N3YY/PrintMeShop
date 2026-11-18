extends Node2D

# Attach this script to the existing ShopScene root node.
# Dialogue choices are temporary A/B/C buttons. Dialogic integration comes later.

@onready var customer_sprite: TextureRect = $LeftCustomerPanel/CustomerSprite
@onready var product_panel: Control = $ShopWorkArea/ProductPanel
@onready var color_panel: Control = $ShopWorkArea/ColorPanel
@onready var merch_select: ItemList = $ShopWorkArea/MerchPanel/MerchSelect
@onready var result_label: Label = $ShopWorkArea/ResultPanel/ResultLabel
@onready var product_preview: Control = $ShopWorkArea/ResultPanel/ProductPreview
@onready var cancel_button: Button = $ShopWorkArea/CancelButton
@onready var confirm_button: Button = $ShopWorkArea/ConfirmButton
@onready var shop_work_area: Control = $ShopWorkArea
@onready var dialogue_area: Control = $DialogueArea

# Item textures: res://assets/items/shirtwhite.png, shirtpink.png, etc.
# Add file prefixes for other item types once their textures are available.
const ITEM_FILE_PREFIX := {
	"Koszulka": "shirt",
	"Skarpetki": "socks"
}

const COLOR_FILE_SUFFIX := {
	"Biały": "white", "Czarny": "black", "Różowy": "pink",
	"Czerwony": "red", "Niebieski": "blue", "Zielony": "green",
	"Pomarańczowy": "orange", "Żółty": "yellow"
}

var preview_texture_rect: TextureRect
var selected_product := ""
var selected_color := ""
var selected_design := ""
var intro_points: int = 0
var pickup_points: int = 0
var current_phase := ""
var pending_order: Dictionary = {}
var is_order_correct := false

var overlay: Control
var overlay_message: Label
var overlay_buttons: VBoxContainer

func _ready() -> void:
	setup_preview_texture()
	setup_product_buttons()
	setup_color_buttons()
	setup_merch_list()
	cancel_button.pressed.connect(reset_order)
	confirm_button.pressed.connect(confirm_order)
	create_temporary_dialogue_ui()
	start_customer()

func setup_product_buttons() -> void:
	for node_name in GameData.PRODUCTS:
		var button: Button = product_panel.get_node_or_null(node_name) as Button
		if button == null:
			push_warning("Product button not found: " + node_name)
			continue
		button.pressed.connect(select_product.bind(GameData.PRODUCTS[node_name]))

func setup_color_buttons() -> void:
	for node_name in GameData.COLORS:
		var button: Button = color_panel.get_node_or_null(node_name) as Button
		if button == null:
			push_warning("Color button not found: " + node_name)
			continue
		button.pressed.connect(select_color.bind(GameData.COLORS[node_name]))

func setup_merch_list() -> void:
	merch_select.clear()
	merch_select.select_mode = ItemList.SELECT_SINGLE
	for design in GameData.DESIGNS:
		merch_select.add_item(design)
	merch_select.item_selected.connect(on_design_selected)

func setup_preview_texture() -> void:
	# Create a TextureRect programmatically inside the existing ProductPreview.
	preview_texture_rect = TextureRect.new()
	preview_texture_rect.name = "SelectedItemTexture"
	preview_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	product_preview.add_child(preview_texture_rect)
	preview_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func select_product(value: String) -> void:
	print("Product button pressed: ", value)
	# Selecting a different product requires clearing the current order first.
	if selected_product != "":
		print("Clear the selected product before choosing another one.")
		return
	selected_product = value
	selected_color = "Biały"
	update_preview()

func select_color(value: String) -> void:
	if selected_product == "":
		print("Select a product first.")
		return
	# Color can be changed any number of times without changing the product.
	selected_color = value
	update_preview()

func on_design_selected(index: int) -> void:
	selected_design = merch_select.get_item_text(index)
	update_preview()

func update_preview() -> void:
	result_label.text = "Produkt: %s\nKolor: %s\nWzór: %s" % [
		selected_product if selected_product != "" else "—",
		selected_color if selected_color != "" else "—",
		selected_design if selected_design != "" else "—"
	]
	update_item_texture()

func update_item_texture() -> void:
	preview_texture_rect.texture = null
	if selected_product == "":
		return

	if not ITEM_FILE_PREFIX.has(selected_product):
		# No item image mapping has been configured for this product yet.
		print("No texture mapping configured for product: ", selected_product)
		return

	var prefix: String = ITEM_FILE_PREFIX[selected_product]
	var suffix: String = COLOR_FILE_SUFFIX.get(selected_color, "white")
	var path: String = "res://assets/items/%s%s.png" % [prefix, suffix]
	print("Item texture path: ", path)
	if ResourceLoader.exists(path):
		preview_texture_rect.texture = load(path) as Texture2D
	else:
		push_warning("Item texture not found: " + path)

func reset_order() -> void:
	# Trash button: clear the product, color, and design.
	# Do not change the customer or reset dialogue points.
	selected_product = ""
	selected_color = ""
	selected_design = ""
	merch_select.deselect_all()
	update_preview()

func confirm_order() -> void:
	if current_phase != "work":
		return
	if selected_product == "" or selected_color == "" or selected_design == "":
		result_label.text = "Wybierz produkt, kolor i wzór!"
		return
	pending_order = {
		"product": selected_product,
		"color": selected_color,
		"design": selected_design
	}
	var expected: Array = GameState.current_encounter()["order"]
	is_order_correct = (
		selected_product == expected[0]
		and selected_color == expected[1]
		and selected_design == expected[2]
	)
	start_pickup_dialogue()

func start_customer() -> void:
	var encounter: Dictionary = GameState.current_encounter()
	if encounter.is_empty():
		push_error("No current encounter is available")
		return
	reset_order()
	pending_order.clear()
	intro_points = 0
	pickup_points = 0
	var character_id: String = encounter["character"]
	var customer: Dictionary = GameData.CHARACTERS[character_id]
	var texture_path: String = customer["texture"]
	if texture_path != "" and ResourceLoader.exists(texture_path):
		customer_sprite.texture = load(texture_path) as Texture2D
	else:
		customer_sprite.texture = null
		if texture_path != "":
			push_warning("Character texture is missing (check game_data.gd): " + texture_path)
	show_intro_dialogue()

func show_intro_dialogue() -> void:
	current_phase = "intro"
	shop_work_area.hide()
	var encounter: Dictionary = GameState.current_encounter()
	var character_name: String = GameData.CHARACTERS[encounter["character"]]["name"]
	var order: Array = encounter["order"]
	show_choices(
		"%s zamawia: %s, kolor %s, wzór %s. Zapamiętaj!" % [character_name, order[0], order[1], order[2]],
		GameData.choice_options("intro")
	)

func on_intro_choice(points: int) -> void:
	intro_points = points
	current_phase = "work"
	overlay.hide()
	shop_work_area.show()
	update_preview()

func start_pickup_dialogue() -> void:
	current_phase = "pickup"
	shop_work_area.hide()
	var reaction := "Zamówienie poprawne!" if is_order_correct else "To nie jest moje zamówienie!"
	show_choices(reaction + " — wybierz odpowiedź na pożegnanie:", GameData.choice_options("pickup"))

func on_pickup_choice(points: int) -> void:
	pickup_points = points
	overlay.hide()
	var result: Dictionary = GameState.complete_encounter(pending_order, intro_points, pickup_points)
	if result.is_empty():
		return
	if GameState.has_more_customers_today():
		start_customer()
	else:
		show_day_results()

func show_day_results() -> void:
	current_phase = "results"
	shop_work_area.hide()
	var summary: Dictionary = GameState.finish_day()
	var best_name := "Samotny wieczór (remis lub zero punktów)"
	if summary["best"] != "":
		best_name = GameData.CHARACTERS[summary["best"]]["name"]
	var message := "DZIEŃ %d / %d\nPoprawne: %d   Błędne: %d\nNowe serduszka: %d\nNajlepsza relacja: %s" % [
		summary["day"], GameData.MAX_DAYS, summary["correct"],
		summary["wrong"], summary["love_gained"], best_name
	]
	if GameState.day == GameData.MAX_DAYS:
		show_action(message, "Zobacz finał", show_final_ending)
	else:
		show_action(message, "Następny dzień", next_day)

func next_day() -> void:
	if GameState.go_to_next_day():
		overlay.hide()
		start_customer()

func show_final_ending() -> void:
	current_phase = "ending"
	var ending: Dictionary = GameState.finish_game()
	var who := "Samotny gracz"
	if ending["character"] != "":
		who = GameData.CHARACTERS[ending["character"]]["name"]
	var ending_labels := {"good": "Dobre", "neutral": "Neutralne", "bad": "Złe", "solo": "Samotne"}
	var ending_label: String = ending_labels.get(ending["type"], ending["type"])
	var message := "FINAŁ GRY\n%s\nTyp zakończenia: %s\nPunkty: %d\nID: %s" % [
		who, ending_label, ending["points"], ending["id"]
	]
	show_action(message, "Zagraj ponownie", restart_game)

func restart_game() -> void:
	GameState.new_game()
	overlay.hide()
	start_customer()

# Temporary testing UI; keeps the existing shop art and layout intact.
# Replace this later with Dialogic speech bubbles and choices.
func create_temporary_dialogue_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TemporaryDialogueLayer"
	layer.layer = 10
	add_child(layer)

	overlay = Control.new()
	overlay.name = "TemporaryDialogueOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 300)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	overlay_message = Label.new()
	overlay_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_message.custom_minimum_size = Vector2(520, 90)
	content.add_child(overlay_message)

	overlay_buttons = VBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 8)
	content.add_child(overlay_buttons)
	overlay.hide()

func clear_overlay_buttons() -> void:
	for child in overlay_buttons.get_children():
		overlay_buttons.remove_child(child)
		child.queue_free()

func show_choices(message: String, options: Array) -> void:
	clear_overlay_buttons()
	overlay_message.text = message
	for option in options:
		var button := Button.new()
		button.text = option["text"]
		button.custom_minimum_size = Vector2(520, 48)
		var score: int = option["points"]
		if current_phase == "intro":
			button.pressed.connect(on_intro_choice.bind(score))
		else:
			button.pressed.connect(on_pickup_choice.bind(score))
		overlay_buttons.add_child(button)
	overlay.show()

func show_action(message: String, button_text: String, callback: Callable) -> void:
	clear_overlay_buttons()
	overlay_message.text = message
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(520, 50)
	button.pressed.connect(callback)
	overlay_buttons.add_child(button)
	overlay.show()
