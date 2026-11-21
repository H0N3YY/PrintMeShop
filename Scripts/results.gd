
extends Control

const SHOP_SCENE_PATH := "res://Scenes/ShopScene.tscn"
const ENDING_SCENE_PATH := "res://Scenes/Ending.tscn"

@onready var scene_image: TextureRect = $SceneImage
@onready var quote_label: Label = $QuoteLabel
@onready var stats_text: Label = $StatsPanel/StatsText
@onready var day_label: Label = $DayLabel
@onready var next_day_button: Button = $NextDayButton

# TODO Add correct image paths when your assets are ready
const RESULT_SCENES := {
	"oscar": {
		1: { "image": "res://assets/results/oscar_results_1.png", "quote": "[Pierwsza kwestia Oskara]" },
		2: { "image": "res://assets/results/oscar_results_2.png", "quote": "[Druga kwestia Oskara]" }
	},

	"gotka": { 
		1: { "image": "res://assets/results/gotka_results_1.png", "quote": "[Pierwsza kwestia Matyldy]" },
		2: { "image": "res://assets/results/gotka_results_2.png", "quote": "[Druga kwestia Matyldy]" }
	},

	"skolim": {
		1: { "image": "res://assets/results/skolim_results_1.png", "quote": "[Pierwsza kwestia Skolima]" },
		2: { "image": "res://assets/results/skolim_results_2.png", "quote": "[Druga kwestia Skolima]" }
	},

	"sekciarz": {
		1: { "image": "res://assets/results/sekciarz_results_1.png", "quote": "[Pierwsza kwestia Ideiska]" },
		2: { "image": "res://assets/results/sekciarz_results_2.png", "quote": "[Druga kwestia Ideiska]" }
	},

	"kukuryniarz": {
		1: { "image": "res://assets/results/kukuryniarz_results_1.png", "quote": "[Pierwsza kwestia Kukuryniarza]" },
		2: { "image": "res://assets/results/kukuryniarz_results_2.png", "quote": "[Druga kwestia Kukuryniarza]" }
	}
}

const SOLO_RESULT := {
	"image": "res://assets/results/solo.png",
	"quote": "Kolejny dzień za nami. Czas wracać do domu."
}

func _ready() -> void:
	next_day_button.pressed.connect(_on_next_day_pressed)
	show_day_results()
	
func get_character_visit(character_id: String) -> int:
	var latest_visit: int = 0

	for encounter_id in GameState.completed:
		if not GameData.ENCOUNTERS.has(encounter_id):
			continue

		var encounter: Dictionary = GameData.ENCOUNTERS[encounter_id]

		if str(encounter["character"]) != character_id:
			continue

		var visit_number: int = GameData.encounter_visit_number(
			str(encounter_id)
		)

		latest_visit = maxi(latest_visit, visit_number)

	return latest_visit
	
	
func get_result_scene(character_id: String) -> Dictionary:
	if character_id.is_empty():
		return SOLO_RESULT

	if not RESULT_SCENES.has(character_id):
		return SOLO_RESULT

	var visit_number: int = get_character_visit(character_id)

	if visit_number == 0:
		return SOLO_RESULT

	var character_results: Dictionary = RESULT_SCENES[character_id]

	visit_number = mini(visit_number, 2)

	return character_results.get(visit_number, SOLO_RESULT)



func show_day_results() -> void:
	var summary: Dictionary = GameState.last_day_summary

	if summary.is_empty():
		push_error("No day summary available.")
		return

	var day_number: int = int(summary["day"])
	var character_id: String = str(summary["best"])
	var display_id: String = character_id

	if display_id.is_empty():
		display_id = "solo"

	var character_name := "Samotny wieczór"

	if character_id != "":
		character_name = str(
			GameData.CHARACTERS[character_id]["name"]
		)

	day_label.text = "DZIEŃ %d / %d" % [
		day_number,
		GameData.MAX_DAYS
	]
	
	var result_scene: Dictionary = get_result_scene(display_id) 
	quote_label.text = str(result_scene["quote"])

	stats_text.text = (
		"Najlepsza relacja: %s\n" +
		"Poprawne zamówienia: %d\n" +
		"Błędne zamówienia: %d\n" +
		"Zdobyte punkty relacji: +%d"
	) % [
		character_name,
		int(summary["correct"]),
		int(summary["wrong"]),
		int(summary["love_gained"])
	]

	var image_path: String = str(result_scene["image"])

	scene_image.texture = null

	if image_path != "" and ResourceLoader.exists(image_path):
		scene_image.texture = load(image_path) as Texture2D
	elif image_path != "":
		push_warning("Result image not found: " + image_path)

	if day_number >= GameData.MAX_DAYS:
		next_day_button.text = "Zobacz zakończenie"
	else:
		next_day_button.text = "Do roboty!"


func _on_next_day_pressed() -> void:
	if GameState.day >= GameData.MAX_DAYS:
		open_ending()
		return

	if GameState.go_to_next_day():
		get_tree().change_scene_to_file(SHOP_SCENE_PATH)


func open_ending() -> void:
	var ending: Dictionary = GameState.finish_game()

	print("Final ending: ", ending["id"])

	if not ResourceLoader.exists(ENDING_SCENE_PATH):
		push_error("Ending scene not found: " + ENDING_SCENE_PATH)
		return

	get_tree().change_scene_to_file(ENDING_SCENE_PATH)
