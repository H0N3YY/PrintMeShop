
extends Control

const SHOP_SCENE_PATH := "res://Scenes/ShopScene.tscn"
const ENDING_SCENE_PATH := "res://Scenes/Ending.tscn"

@onready var scene_image: TextureRect = $SceneImage
@onready var quote_label: Label = $QuoteLabel
@onready var stats_text: Label = $StatsPanel/StatsText
@onready var day_label: Label = $DayLabel
@onready var next_day_button: Button = $NextDay_btn

# TODO Add correct image paths when your assets are ready
const RESULT_SCENES := {
	"oscar": {
		1: { "image": "res://assets/characters/osci.png", "quote": "Czekałem na Ciebie cały dzień. Nie żebym miał niezdrową obsesję na twoim punkcie, po prostu bardzo ładnie pachniesz. Nie to co ja. Ale po co komu ładne zapachy? Inni mogą się chwalić sukcesami, zarobkami czy jakimś przereklamowanym dachem nad głową. Ja za to mam mój ulubiony most i gromadkę zaprzyjaźnionych szczurów. Swoją drogą, może masz ochotę mnie nakarmić? Trochę przymieram z głodu." },
		2: { "image": "res://assets/characters/oscianimation.png", "quote": "Moje kochane szczurki donoszą że podobno kończysz pracę! Akurat szukam wsparcia do następnej wielkiej bitwy o butelki kaucyjne mającej miejsce w… (może macie jakiś fajny pomysł na to gdzie we Wrocławiu najlepiej to umiejscowić dla największej beki xd). Cała największa menelnia się zjawi, zatem ja też muszę. To mój obowiązek. Myślę że świetnie poradzimy sobie w parze, a potem mogę pomóc ci się umyć w Odrze." }
	},

	"gotka": { 
		1: { "image": "res://assets/characters/gotka1.png", "quote": "Miewasz czasem wrażenie że całe to miasto zawiązało przeciwko tobie z wszechświatem jakiś pakt? Wczoraj tramwaj którym jechałam zaliczył drift po chodniku na zakręcie, a dzisiaj jakiś mały krasnal na hulajnodze o mało mnie nie skasował! Na szczęście w oczy rzucił mi się ten sklep! Merch który dla mnie przygotowałeś poprawił mi humor i idealnie siądzie na dzisiejszy koncert w starej katedrze. Może chcesz pójść ze mną i posłuchać trochę dobrej muzyki?" },
		2: { "image": "res://assets/characters/gotka2.png", "quote": "Wyglądasz jakby przydało ci się coś mocniejszego niż niedobra kawa z automatu po tym całym dniu. Dobrze się składa, chętnie wybrałabym się na spacer i piwo. Możesz nawet kupić mi kwiaty. Chętnie powiesiłabym takie na ścianie by powoli pięknie uschły i zdobiły pokój przypominając o tym spokojnym wieczorze." }
	},

	"skolim": {
		1: { "image": "res://assets/characters/skolim1.png", "quote": "No hej gwiazdo! Myślałem że się nie doczekam. Mam bardzo napięty grafik i jestem spóźniony na koncert już trzy godziny. Dożynki same się nie rozkręcą, a Królowi Latino nie każe się czekać. Ale w sumie możesz być małym wyjątkiem od tej reguły." },
		2: { "image": "res://assets/characters/skolim2.png.png", "quote": "Witaj myszko. Co powiesz na przejażdżkę nocą po mieście moim skolimmobilem? Potem mogę odwieźć cię do domu.. lub możemy skoczyć gdzieś indziej. Albo może pokażesz mi zaplecze tego waszego sklepiku? Chętnie trochę pozwiedzam." }
	},

	"sekciarz": {
		1: { "image": "res://assets/characters/sekciarz1.png", "quote": "Nie myśl sobie że na Ciebie czekałem. Żal mi się Ciebie zrobiło, gdy zdałem sobie sprawę że nie stać Cię nawet na opłacenie czesnego i musisz tak ciężko pracować. Ja w twoim wieku mam własną firmę i sprzedaje ebooki jak osiągnąć taki sukces. Chodź już, jeśli chcesz możesz mi potowarzyszyć w trakcie spaceru. Spacery raczej nie są ci obce, w końcu musisz przemieszczać się w 5 minut przerwy na Wagonową między zajęciami." },
		2: { "image": "res://assets/characters/sekciarz2.png", "quote": "Bardzo się cieszę, że Cię poznałem. Czuję że przy Tobie nie muszę ukrywać swojego prawdziwego ja. Pod tym ciężkim i ciemnym kapturem, jestem tylko bezbronną istotą która boi się okazywać szczere uczucia. Jednak przy Tobie moje obawy znikają. Jakbyśmy znali się od lat i nie mieli przed sobą żadnych tajemnic. Czy chcesz ze mną zamieszkać i dołączyć do mojej firmy zajmującej się fotowoltaiką?" }
	},

	"kukuryniarz": {
		1: { "image": "res://assets/characters/kukuryniarz.png", "quote": "Ile można pracować? Ja to bym nie chciał pracować. Chcesz ze mną pośmigać na hulajnodze?! A kupisz mi energetyczka? Dupnął bym sobie monsterka. Albo 5. A potem możemy pojeździć na mojej hulajnodze! Chodźmy chodźmy bo już późno!" },
		2: { "image": "res://assets/characters/kukuryniarzanimation.png", "quote": "Wiesz, myślę że musisz zrezygnować z pracy. Nie masz czasu na fajne rzeczy. Ale rozumiem, nie masz pieniędzy. Ja mam kasę od starego. Kupił mi wczoraj nowiutkiego kukirinka G3 PRO. Jest super i bardzo drogi. A teraz chodź, w końcu porobisz coś fajnego kasztanie!" }
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
