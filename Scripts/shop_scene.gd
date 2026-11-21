extends Node2D

@onready var customer_sprite: TextureRect = $LeftCustomerPanel/CustomerSprite
@onready var talk_button: TextureButton = $LeftCustomerPanel/TalkButton
@onready var product_panel: Control = $ShopWorkArea/ProductPanel
@onready var color_panel: Control = $ShopWorkArea/ColorPanel
@onready var merch_select: ItemList = $ShopWorkArea/MerchPanel/MerchSelect
@onready var result_label: Label = $ShopWorkArea/ResultPanel/ResultLabel
@onready var product_preview: Control = $ShopWorkArea/ResultPanel/ProductPreview
@onready var confirm_button: TextureButton = $ShopWorkArea/ConfirmButton
@onready var shop_work_area: Control = $ShopWorkArea
@onready var dialogue_area: Control = $DialogueArea
@onready var day_label: Label = $TopBar/DayLabel

@onready var product_sound: AudioStreamPlayer = $ProductSound
@onready var color_sound: AudioStreamPlayer = $ColorSound
@onready var merch_sound: AudioStreamPlayer = $MerchSound
@onready var sell_sound: AudioStreamPlayer = $SellSound
@onready var idle_animation_timer: Timer = $IdleAnimationTimer

var idle_base_texture: Texture2D
var idle_alt_texture: Texture2D
var idle_frame_active: bool = false

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
	"Pomarańczowy": "orange", "Żółty": "yellow","Szary":"gray",
}

const MERCH_TEXTURES := {
	"Fat Cat": "logocat.png",
	"Hatsune Miku": "logohatsume.png",
	"Hello IT": "logohelloit.png",
	"Ideis": "logoideis.png",
	"Kukuryniarz": "logokucyk.png",
	"League of Legends": "logoporo.png",
	"Love and Deepspace": "logocrow.png",
	"Piwo Janka": "logopiwo.png",
	"Roblox": "logoroblox.png",
	"Skolim": "logoskolim.png",
	"Monsterek": "logoszkiely.png",
	"Netflix": "logodomino.png"
}

const PRODUCT_PREVIEW_TRANSFORMS := {
	"Koszulka": {"scale": 1.00, "offset": Vector2(0, 0) },
	"Czapka": {"scale": 1.20, "offset": Vector2(0, 8)},
	"Kubek": {"scale": 1.05, "offset": Vector2(0, 0)},
	"Torba": {"scale": 1.10, "offset": Vector2(0, 0)},
	"Plakat": {"scale": 1.08, "offset": Vector2(0, 0)},
	"Skarpetki": {"scale": 1.15, "offset": Vector2(0, 5)},
	"Brelok": {"scale": 1.12, "offset": Vector2(0, 0)},
	"Przypinka": {"scale": 1.15, "offset": Vector2(0, 0)},
	"Naklejki": {"scale": 1.10, "offset": Vector2(0, 0)}
}

const CHARACTER_IDLE_FRAMES := {
	"res://assets/characters/osci.png": "res://assets/characters/oscianimation.png",
	"res://assets/characters/gotka1.png": "res://assets/characters/gotka1animation.png",
	"res://assets/characters/gotka2.png": "res://assets/characters/gotka2animation.png",
	"res://assets/characters/skolim1.png": "res://assets/characters/skolim1animation.png",
	"res://assets/characters/skolim2.png": "res://assets/characters/skolim2animation.png",
	"res://assets/characters/sekciarz1.png": "res://assets/characters/sekciarz1animation.png",
	"res://assets/characters/sekciarz2.png": "res://assets/characters/sekciarz2animation.png",
	"res://assets/characters/kukuryniarz.png": "res://assets/characters/kukuryniarzanimation.png"
}


const CUSTOMER_MOVE_DURATION: float = 1.5

var customer_rest_position: Vector2
var customer_is_moving: bool = false

var preview_texture_rect: TextureRect
var logo_preview_texture_rect: TextureRect

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
	customer_rest_position = customer_sprite.position
	setup_preview_texture()
	setup_product_buttons()
	setup_color_buttons()
	setup_merch_list()
	confirm_button.pressed.connect(confirm_order)
	create_temporary_dialogue_ui()
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	talk_button.pressed.connect(_on_talk_button_pressed)
	update_day_counter()
	idle_animation_timer.timeout.connect(_on_idle_animation_timer_timeout)
	start_customer()
	
	
func update_day_counter() -> void:
	day_label.text = "DAY %d/%d" % [
		GameState.day,
		GameData.MAX_DAYS
	]
	
	
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
	preview_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	product_preview.add_child(preview_texture_rect)
	preview_texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	preview_texture_rect.position = Vector2.ZERO
	preview_texture_rect.size = product_preview.size

	logo_preview_texture_rect = TextureRect.new()
	logo_preview_texture_rect.name = "SelectedLogoTexture"
	logo_preview_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_preview_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	product_preview.add_child(logo_preview_texture_rect)
	logo_preview_texture_rect.hide()

	product_preview.resized.connect(update_product_preview_transform)


func update_product_preview_transform() -> void:
	if preview_texture_rect == null:
		return

	if selected_product.is_empty():
		preview_texture_rect.position = Vector2.ZERO
		preview_texture_rect.size = product_preview.size
		return

	var settings: Dictionary = PRODUCT_PREVIEW_TRANSFORMS.get(
		selected_product,
		{
			"scale": 1.0,
			"offset": Vector2.ZERO
		}
	)

	var scale_value: float = float(settings.get("scale", 1.0))
	var offset_value: Vector2 = settings.get(
		"offset",
		Vector2.ZERO
	)

	var container_size: Vector2 = product_preview.size
	var scaled_size: Vector2 = container_size * scale_value

	preview_texture_rect.size = scaled_size
	preview_texture_rect.position = (
		(container_size - scaled_size) / 2.0
		+ offset_value
	)

	update_logo_position()




func update_logo_position() -> void:
	if logo_preview_texture_rect == null:
		return

	if preview_texture_rect.texture == null:
		return

	if selected_product.is_empty():
		return

	var product_texture: Texture2D = preview_texture_rect.texture
	var texture_size: Vector2 = product_texture.get_size()
	var available_size: Vector2 = preview_texture_rect.size

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	if available_size.x <= 0 or available_size.y <= 0:
		return

	# Calculate the actual displayed image size.
	var image_scale: float = minf(
		available_size.x / texture_size.x,
		available_size.y / texture_size.y
	)

	var image_size: Vector2 = texture_size * image_scale
	var image_offset: Vector2 = (
		available_size - image_size
	) / 2.0

	# Get the individual print area for this product.
	var print_area: Rect2 = PRODUCT_LOGO_RECTS.get(
		selected_product,
		Rect2(0.35, 0.35, 0.30, 0.30)
	)

	# Account for both the image position and product offset.
	logo_preview_texture_rect.position = (
		preview_texture_rect.position
		+ image_offset
		+ print_area.position * image_size
	)

	logo_preview_texture_rect.size = (
		print_area.size * image_size
	)



func select_product(value: String) -> void:
	if selected_product != value:
		selected_product = value

		selected_color = ""
		selected_design = ""
		merch_select.deselect_all()

	product_sound.play()
	update_preview()
	
	
func select_color(value: String) -> void:
	if selected_product == "":
		return
		
	selected_color = value
	color_sound.play()
	update_preview()


func on_design_selected(index: int) -> void:
	if selected_product.is_empty() or selected_color.is_empty():
		merch_select.deselect_all()
		return

	selected_design = merch_select.get_item_text(index)

	merch_sound.play()
	update_preview()

func update_preview() -> void:
	result_label.text = "Produkt: %s\nKolor: %s\nWzór: %s" % [
		selected_product if not selected_product.is_empty() else "—",
		selected_color if not selected_color.is_empty() else "—",
		selected_design if not selected_design.is_empty() else "—"
	]

	update_item_texture()
	update_merch_texture()

func update_item_texture() -> void:
	preview_texture_rect.texture = null

	if selected_product.is_empty():
		return

	if not ITEM_FILE_PREFIX.has(selected_product):
		push_warning("No texture mapping for: " + selected_product)
		return

	var prefix: String = ITEM_FILE_PREFIX[selected_product]
	var suffix: String = COLOR_FILE_SUFFIX.get(selected_color, "gray")

	var texture_path: String = (
		"res://assets/items/%s%s.png" % [prefix, suffix]
	)

	if ResourceLoader.exists(texture_path):
		preview_texture_rect.texture = load(texture_path) as Texture2D
		print("Texture loaded successfully!")
	else:
		push_warning("Texture not found: " + texture_path)
	update_product_preview_transform()
	

func update_merch_texture() -> void:
	logo_preview_texture_rect.texture = null
	logo_preview_texture_rect.hide()

	if selected_product.is_empty():
		return

	if selected_design.is_empty():
		return

	var merch_name: String = GameData.canonical_design(
		selected_design
	)

	if not MERCH_TEXTURES.has(merch_name):
		push_warning("No merch texture mapping for: " + merch_name)
		return

	var texture_path: String = (
		"res://assets/merch/" + MERCH_TEXTURES[merch_name]
	)

	if not ResourceLoader.exists(texture_path):
		push_warning("Merch texture not found: " + texture_path)
		return

	logo_preview_texture_rect.texture = (
		load(texture_path) as Texture2D
	)

	update_logo_position()
	logo_preview_texture_rect.show()


func reset_order() -> void:
	# Reset order automatically for the next customer
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
		and GameData.canonical_design(selected_design)
			== GameData.canonical_design(str(expected[2]))
	)
	sell_sound.play()
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
	talk_button.hide()
	
	animate_customer_enter()


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
			texture_path = str(appearances.get("pickup_" + route, texture_path))

	customer_sprite.texture = null

	if texture_path != "" and ResourceLoader.exists(texture_path):
		customer_sprite.texture = load(texture_path) as Texture2D
	elif texture_path != "":
		push_warning("Missing character texture: " + texture_path)

	# Always configure idle animation after loading the appearance.
	setup_idle_animation(texture_path)



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

	# Close dialogue and restore the shop UI.
	dialogue_area.hide()
	shop_work_area.show()

	var result: Dictionary = GameState.complete_encounter(
		pending_order,
		intro_points,
		pickup_points
	)

	if result.is_empty():
		return

	# Animate only the customer sprite.
	await animate_customer_exit()

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
	
func animate_customer_enter() -> void:
	customer_is_moving = true
	talk_button.hide()

	# Start outside the left side of the screen.
	customer_sprite.position = Vector2(
		-customer_sprite.size.x - 50.0,
		customer_rest_position.y
	)

	customer_sprite.show()

	var tween: Tween = create_tween()

	tween.tween_property(
		customer_sprite,
		"position",
		customer_rest_position,
		CUSTOMER_MOVE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished

	customer_is_moving = false

	if current_phase == "waiting_intro":
		talk_button.show()


func animate_customer_exit() -> void:
	idle_animation_timer.stop()
	customer_sprite.texture = idle_base_texture
	customer_is_moving = true
	talk_button.hide()

	var exit_position := Vector2(
		get_viewport_rect().size.x + 50.0,
		customer_rest_position.y
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		customer_sprite,
		"position",
		exit_position,
		CUSTOMER_MOVE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

	customer_sprite.hide()
	customer_is_moving = false
	
	
func setup_idle_animation(texture_path: String) -> void:
	idle_animation_timer.stop()

	idle_base_texture = customer_sprite.texture
	idle_alt_texture = null
	idle_frame_active = false

	var animation_path: String = str(
		CHARACTER_IDLE_FRAMES.get(texture_path, "")
	)

	if animation_path.is_empty():
		return

	if not ResourceLoader.exists(animation_path):
		return

	idle_alt_texture = load(animation_path) as Texture2D

	if idle_base_texture != null and idle_alt_texture != null:
		idle_animation_timer.start()


func _on_idle_animation_timer_timeout() -> void:
	if idle_base_texture == null or idle_alt_texture == null:
		return

	if customer_is_moving:
		return

	idle_frame_active = not idle_frame_active

	if idle_frame_active:
		customer_sprite.texture = idle_alt_texture
	else:
		customer_sprite.texture = idle_base_texture
		
