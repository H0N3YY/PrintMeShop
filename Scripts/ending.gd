
extends Control

@onready var scene_image: TextureRect = $SceneImage
@onready var quote_label: Label = $QuoteLabel
@onready var ending_type_label: Label = $EndingTypeLabel
@onready var replay_button: TextureButton = $Roleplay_btn
@onready var main_menu_button: TextureButton = $Main_btn

const INTRO_SCENE_PATH := "res://Scenes/Intro.tscn"
const MAIN_MENU_SCENE_PATH := "res://Scenes/MainMenu.tscn"

const ENDING_SCENES := {
	"oscar": {
		"good": {
			"image": "res://assets/ending/e_oscar_1.png",
			"quote": "Miłość zwyciężyła! Ty i Oskar bierzecie ślub na wrocławskim śmietniku za sklepem. Wśród zaproszonych gości nie zabrakło najbliższej rodziny, czyli całej kolonii szczurów."
		},
		"neutral": {
			"image": "res://assets/ending/e_oscar_2.png",
			"quote": "Wspólna przyszłość z Oskarem? Czemu nie! Co prawda mieszkacie teraz pod mostem, a waszą codziennością są uliczne bitwy o butelki kaucyjne, ale przynajmniej nigdy nie jest nudno."
		},
		"bad": {
			"image": "res://assets/ending/e_oscar_3.png",
			"quote": "Los w końcu uśmiechnął się do Oskara! Dawny król ulicy dorobił się fortuny i teraz to on patrzy na ciebie z góry. Kto by pomyślał, że role tak szybko się odwrócą?"
		}
	},
	"skolim": {
		"good": {
			"image": "res://assets/ending/e_skolim_1.png",
			"quote": "Ktoś puka do drzwi. To Skolim, i to półnagi! Z tajemniczym uśmiechem proponuje ci hot doga z kiełbasą serową i czerwonym sosem. Zapowiada się naprawdę gorący wieczór."
		},
		"neutral": {
			"image": "res://assets/ending/e_skolim_2.png",
			"quote": "Skolim dostrzegł w tobie prawdziwy talent! Zaproponował ci pracę na swojej stacji. Może to nie wielka miłość, ale przynajmniej zamieniasz sklep z merchem na królestwo Latino."
		},
		"bad": {
			"image": "res://assets/ending/e_skolim_3.png",
			"quote": "Zostają ci tylko łzy i YouTube. Oglądasz, jak Skolim rozkręca kolejne dożynki, śpiewając dla tłumu dzieciaków. Zazdrość zżera cię od środka. Król Latino odjechał bez ciebie."
		}
	},
	"sekciarz": {
		"good": {
			"image": "res://assets/ending/e_sekciarz_1.png",
			"quote": "Stało się. Dołączasz do Ideiska i razem zakładacie fotowoltaiczne imperium. Teraz wspólnie przekonujecie ludzi, że panele słoneczne to rozwiązanie absolutnie wszystkich życiowych problemów."
		},
		"neutral": {
			"image": "res://assets/ending/e_sekciarz_2.png",
			"quote": "Ideisek uznał, że jesteś całkiem spoko. W przypływie niezwykłej hojności zaliczył ci praktyki. Bez rozmowy kwalifikacyjnej, bez papierologii i, co najważniejsze, bez kupowania jego e-booka."
		},
		"bad": {
			"image": "res://assets/ending/e_sekciarz_3.png",
			"quote": "Prawda o Ideisku w końcu wychodzi na jaw. To on od dawna pociąga za sznurki na twojej uczelni! Na dodatek właśnie podwoił ci czesne. Chyba jednak znajomość z nim nie była najlepszą inwestycją."
		}
	},
	"gotka": {
		"good": {
			"image": "res://assets/ending/e_gotka_1.png", 
			"quote": "Matylda znalazła sobie idealnego pupilka. Ciebie! Z obrożą na szyi i smyczą w jej dłoni grzecznie podążasz za swoją gotycką panią. Chyba trochę inaczej wyobrażałeś sobie te relacje."
			},
		"neutral": {
			"image": "res://assets/ending/e_gotka_2.png",
			"quote": "Z Matyldą odkrywasz zupełnie nowe hobby: polowanie na żywe krasnale! Uzbrojeni w kukiriny przemierzacie ulice Wrocławia, tropiąc małych uciekinierów. Kto powiedział, że randki muszą być nudne?"
			},
		"bad": {
			"image": "res://assets/ending/e_gotka_3.png", 
			"quote": "Miłość zmienia człowieka, a ciebie zmieniła w prawdziwego glamour gotha. Razem z Matyldą spędzacie romantyczne popołudnie na pikniku pod katedrą. Czarna koronka, mroczna muzyka i pełnia szczęścia."
		}
	},
	"kukuryniarz": {
		"good": {
			"image": "res://assets/ending/e_kukuryniarz_1.png", 
			"quote": "Norbercik zrobił coś niewiarygodnego. Oddał ci swojego ukochanego kukyrina! Od tej chwili jesteście najlepszymi przyjaciółmi i razem przemierzacie miasto, zostawiając wszystkich kasztanów daleko w tyle."
			},
		"neutral": {
			"image": "res://assets/ending/e_kukuryniarz_2.png", 
			"quote": "Norbercik odkrył twoje nowe powołanie: bycie przeszkodą terenową. Z dumą przeskakuje cię na swoim kukyrinie, popisując się kolejnymi trikami. Przynajmniej ktoś dobrze się bawi."
			},
		"bad": {
			"image": "res://assets/ending/e_kukuryniarz_3.png", 
			"quote": "Uciekaj, ile sił w nogach! Norbercik i jego gang krasnali urządzili sobie na ciebie polowanie. To zdecydowanie najgorszy wyścig twojego życia."
			}
	}
}

const SOLO_ENDING := {
	"image": "res://assets/ending/e_foreveralone.png",
	"quote": "Jesteś sam, ze swoim długiem, niestety nie udało ci się poznać bratniej duszy. Może następnym razem się uda!"
}

const ENDING_TYPE_LABELS := {
	"good": "GOOD ENDING",
	"neutral": "NEUTRAL",
	"bad": "BAD",
	"solo": "BAD"
}



func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

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
