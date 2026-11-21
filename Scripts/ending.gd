
extends Control

const INTRO_SCENE_PATH := "res://Scenes/Intro.tscn"
const MAIN_MENU_SCENE_PATH := "res://Scenes/MainMenu.tscn"

const ENDING_SCENES := {
	"oscar": {
		"bad": {
			"image": "res://assets/ending/e_oscar1.png",
			"quote": "Oskar staje się bogaty i teraz to on pomiata graczem"
		},
		"neutral": {
			"image": "res://assets/ending/e_oscar2.png",
			"quote": "Gracz również zostaje bezdomny i będzie brał udział w ulicznych bójkach o kałcyjne butelki z Oskarem"
		},
		"good": {
			"image": "res://assets/ending/e_oscar3.png",
			"quote": "Oskar i Gracz biorą ślub na wrocławskim śmietniku na tyłach sklepu razem ze szczurami"
		}
	},
	"skolim": {
		"bad": {
			"image": "res://assets/ending/e_skolim_1.png",
			"quote": "Gracz zapłakany ogląda na yt jak skolim śpiewa na dożynkach dla dzieci i jest zazdrosny."
		},
		"neutral": {
			"image": "res://assets/ending/e_skolim_2.png",
			"quote": "skolim oferuję pracę graczowi na jego stacji zamiast w sklepie"
		},
		"good": {
			"image": "res://assets/ending/e_skolim_3.png",
			"quote": "skolim przychodzi do gracza półnagi w odwiedziny i w drzwiach wychyla sie oferując hot doga z kiełbasą serową i czerwonym sosem"
		}
	},
	"sekciarz": {
		"bad": {
			"image": "res://assets/ending/e_sekciarz_1.png",
			"quote": "Okazuje się że Ideisek skrycie rządzi żelazną ręką nad uczelnią gracza i zwiększa jego czesne dwukrotnie"
		},
		"neutral": {
			"image": "res://assets/ending/e_sekciarz_2.png",
			"quote": "Sekciarz stwierdza że gracz jest spoko  i zalicza mu praktyki"
		},
		"good": {
			"image": "res://assets/ending/e_sekciarz_3.png",
			"quote": "Gracz decyduje się dołączyć do Ideiska by wspólnie naciągać ludzi na fotowoltaike"
		}
	},
	"gotka": {
		"bad": {"image": "", "quote": "gracz kończy jako pupilek gotki na smyczy jak piesek"},
		"neutral": {"image": "", "quote": "Gotka i gracz wspólnie zaczynają polować na żywe krasnale na kukirinach"},
		"good": {"image": "", "quote": "gracz również zostaje glamur gotem i są razem szczęśliwi na pikniku pod jakąś katedrą"}
	},
	"kukuryniarz": {
		"bad": {"image": "", "quote": "Norbercik oddaje graczowi swojego kukurina i zostają najlepszymi przyjaciółmi "},
		"neutral": {"image": "", "quote": "Kukuryniarz robi sobie z głównej postaci tor przeszkód i popisuje się przeskakując go"},
		"good": {"image": "", "quote": "Kukuryniarz ze swoim gangiem krasnali goni postać gracza na hulajnogach i obrzuca go szczurami"}
	}
}

const SOLO_ENDING := {
	"image": "res://assets/ending/e_foreveralone.png",
	"quote": "[Opis zakończenia Forever Alone]"
}

const ENDING_TYPE_LABELS := {
	"good": "GOOD ENDING",
	"neutral": "NEUTRAL ENDING",
	"bad": "BAD ENDING",
	"solo": "BAD ENDING"
}

@onready var scene_image: TextureRect = $SceneImage
@onready var quote_label: Label = $QuoteLabel
@onready var ending_type_label: Label = $EndingTypeLabel
@onready var replay_button: Button = $ReplayButton
@onready var main_menu_button: Button = $MainMenuButton


func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	replay_button.text = "ZAGRAJ PONOWNIE"
	main_menu_button.text = "MENU GŁÓWNE"

	show_ending()


func show_ending() -> void:
	var ending: Dictionary = GameState.final_ending()

	var character_id: String = str(ending.get("character", ""))
	var ending_type: String = str(ending.get("type", "solo"))

	var ending_scene: Dictionary = SOLO_ENDING

	if ending_type != "solo" and ENDING_SCENES.has(character_id):
		var character_endings: Dictionary = ENDING_SCENES[character_id]
		ending_scene = character_endings.get(ending_type, SOLO_ENDING)

	ending_type_label.text = str(
		ENDING_TYPE_LABELS.get(ending_type, "BAD ENDING")
	)

	quote_label.text = str(ending_scene.get("quote", ""))

	var image_path: String = str(ending_scene.get("image", ""))

	scene_image.texture = null

	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		scene_image.texture = load(image_path) as Texture2D


func _on_replay_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(INTRO_SCENE_PATH)


func _on_main_menu_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
