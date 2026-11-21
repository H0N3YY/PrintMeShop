extends Node2D

@onready var customer_sprite: TextureRect = $LeftCustomerPanel/CustomerSprite
@onready var talk_button: TextureButton = $LeftCustomerPanel/TalkButton
@onready var product_panel: Control = $ShopWorkArea/ProductPanel
@onready var color_panel: Control = $ShopWorkArea/ColorPanel
@onready var merch_select: ItemList = $ShopWorkArea/MerchPanel/MerchSelect
@onready var result_label: Label = $ShopWorkArea/ResultPanel/ResultLabel
@onready var product_preview: Control = $ShopWorkArea/ResultPanel/ProductPreview
@onready var cancel_button: TextureButton = $ShopWorkArea/CancelButton
@onready var confirm_button: TextureButton = $ShopWorkArea/ConfirmButton
@onready var shop_work_area: Control = $ShopWorkArea
@onready var dialogue_area: Control = $DialogueArea

const RESULTS_SCENE_PATH := "res://Scenes/Results.tscn"

const ITEM_FILE_PREFIX := {
	"Koszulka": "shirt",
	"Skarpetki": "socks",
	"Kubek": "mug",
	"Plakat": "poster",
	"Torba": "bag",
	"Brelok": "keychain",
	"Przypinka": "pin",
	"Naklejki": "stickers",
	"Czapka": "cap"
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
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	talk_button.pressed.connect(_on_talk_button_pressed)
	start_customer()
	
func _on_talk_button_pressed() -> void:
	if current_phase != "waiting_intro":
		return

	talk_button.hide()
	show_intro_dialogue()

func setup_product_buttons() -> void:
	for node_name in GameData.PRODUCTS:
		var button: TextureButton = product_panel.get_node_or_null(node_name) as TextureButton
		if button == null:
			push_warning("Product button not found: " + node_name)
			continue
		button.pressed.connect(select_product.bind(GameData.PRODUCTS[node_name]))

func setup_color_buttons() -> void:
	for node_name in GameData.COLORS:
		var button: TextureButton = color_panel.get_node_or_null(node_name) as TextureButton
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
	selected_color = "Szary"
	update_preview()

func select_color(value: String) -> void:
	if selected_product == "":
		print("Select a product first.")
		return
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

	if selected_product.is_empty():
		return

	if not ITEM_FILE_PREFIX.has(selected_product):
		push_warning("No texture mapping for: " + selected_product)
		return

	var prefix: String = ITEM_FILE_PREFIX[selected_product]
	var suffix: String = COLOR_FILE_SUFFIX.get(selected_color, "white")

	var texture_path: String = (
		"res://assets/items/%s%s.png" % [prefix, suffix]
	)

	print("Selected product: ", selected_product)
	print("Selected color: ", selected_color)
	print("Loading texture: ", texture_path)
	print("File exists: ", ResourceLoader.exists(texture_path))

	if ResourceLoader.exists(texture_path):
		preview_texture_rect.texture = load(texture_path) as Texture2D
		print("Texture loaded successfully!")
	else:
		push_warning("Texture not found: " + texture_path)

func reset_order() -> void:
	# Trash button = clear product, color, and design
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
		push_error("No current encounter is available.")
		return

	reset_order()
	pending_order.clear()
	
	intro_points = 0
	pickup_points = 0
	is_order_correct = false

	current_phase = "waiting_intro"
	set_customer_appearance("intro")

	# Show customer and shop before conversation
	shop_work_area.show()
	dialogue_area.hide()
	talk_button.show()


# Show encounter art independently from  romance ID
func set_customer_appearance(phase: String) -> void:
	var encounter: Dictionary = GameState.current_encounter()
	var character_id: String = str(encounter["character"])
	var character: Dictionary = GameData.CHARACTERS[character_id]
	var texture_path: String = str(character.get("texture", ""))
	var appearances: Dictionary = GameData.CHARACTER_APPEARANCES.get(character_id, {})
	if not appearances.is_empty():
		texture_path = str(appearances.get("default", texture_path))
		if GameData.encounter_visit_number(str(encounter["id"])) == 2:
			texture_path = str(appearances.get("second_visit", texture_path))
		if phase == "pickup":
			var route: String = get_current_route()
			# Optional overrides e.g. "pickup_good", "pickup_neutral", "pickup_bad"
			texture_path = str(appearances.get("pickup_" + route, texture_path))
	customer_sprite.texture = null
	if texture_path != "" and ResourceLoader.exists(texture_path):
		customer_sprite.texture = load(texture_path) as Texture2D
	elif texture_path != "":
		push_warning("Missing character texture: " + texture_path)

func get_current_route() -> String:
	var encounter: Dictionary = GameState.current_encounter()
	var character_id: String = str(encounter["character"])
	var additional_points: int = intro_points if is_order_correct else 0
	return GameState.relationship_route(character_id, additional_points)


func start_dialogic_phase(phase: String) -> void:
	var encounter: Dictionary = GameState.current_encounter()
	var route: String = ""

	if phase == "pickup":
		var character_id: String = str(encounter["character"])
		var is_romance: bool = GameData.CHARACTERS[character_id]["romance"]

		if is_romance:
			route = get_current_route()

	var timeline_path: String = GameData.dialogue_timeline_path(
		str(encounter["id"]), phase, route
	)

	if not ResourceLoader.exists(timeline_path):
		push_error("Dialogic timeline not found: " + timeline_path)
		return

	GameState.reset_dialogue_choice()

	talk_button.hide()
	shop_work_area.hide()
	dialogue_area.show()
	$DialogueArea/ChoiceArea.show()
	
	await get_tree().process_frame
	for button in get_tree().get_nodes_in_group("dialogic_choice_button"):
		print(
		"Choice button: ", button.name,
		" | Parent visible: ",
		button.get_parent().is_visible_in_tree(),
		" | Index: ", button.choice_index
	)

	Dialogic.start_timeline(timeline_path)


func show_intro_dialogue() -> void:
	current_phase = "intro"
	set_customer_appearance("intro")
	start_dialogic_phase("intro")

func on_intro_choice(points: int) -> void:
	intro_points = points
	current_phase = "work"
	dialogue_area.hide()
	shop_work_area.show()
	update_preview()

func start_pickup_dialogue() -> void:
	current_phase = "pickup"
	set_customer_appearance("pickup")
	start_dialogic_phase("pickup")

func on_pickup_choice(points: int) -> void:
	pickup_points = points
	dialogue_area.hide()
	var result: Dictionary = GameState.complete_encounter(pending_order, intro_points, pickup_points)
	if result.is_empty():
		return
	if GameState.has_more_customers_today():
		start_customer()
	else:
		show_day_results()

func _on_dialogic_timeline_ended() -> void:
	if current_phase != "intro" and current_phase != "pickup":
		return
	var selected_points: int = GameState.dialogue_choice_points
	if selected_points < 0:
		push_warning("Timeline ended without a selected A/B/C answer. Awarding zero points.")
		selected_points = 0
	if current_phase == "intro":
		on_intro_choice(selected_points)
	else:
		on_pickup_choice(selected_points)

func show_day_results() -> void:
	current_phase = "results"

	GameState.finish_day()

	get_tree().call_deferred(
		"change_scene_to_file",
		RESULTS_SCENE_PATH
	)
	
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

# TODO Replace this later with Dialogic speech bubbles and choices
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
