class_name GameData
extends RefCounted

# Game configuration and ending thresholds
const MAX_DAYS := 5
const ENDING_GOOD_MIN := 6
const ENDING_NEUTRAL_MIN := 3

const PRODUCTS := {
	"brelok_btn": "Brelok",
	"skarpety_btn": "Skarpetki",
	"naklejki_btn": "Naklejki",
	"koszulka_btn": "Koszulka",
	"pin_btn": "Przypinka",
	"torba_btn": "Torba",
	"kubek_btn": "Kubek",
	"plakat_btn": "Plakat",
	"czapka_btn": "Czapka"
}

const COLORS := {
	"white": "Biały", "black": "Czarny", "pink": "Różowy",
	"red": "Czerwony", "blue": "Niebieski", "green": "Zielony",
	"orange": "Pomarańczowy", "yellow": "Żółty"
}

const DESIGNS := [
	"Fat Cat", "Hatsune Miku", "Hello IT", "Ideis", "Kukuryniarz",
	 "League of Legends", "Love and Deepspace", "Monsterek",
	"Netflix", "Piwo Janka", "Roblox", "Skolim"
]

const CHARACTERS := {
	"gotka": {"name": "Matylda", "romance": true, "texture": "res://assets/characters/gotka1.png"},
	"oscar": {"name": "Osci", "romance": true, "texture": "res://assets/characters/osci.png"},
	"skolim": {"name": "Skolim", "romance": true, "texture": "res://assets/characters/skolim1.png"},
	"sekciarz": {"name": "Ideisek", "romance": true, "texture": "res://assets/characters/sekciarz1.png"},
	"kukuryniarz": {"name": "Norbi Kukuryniarz", "romance": true, "texture": "res://assets/characters/kukuryniarz.png"},
	"npc1": {"name": "Pan Janusz", "romance": false, "texture": "res://assets/characters/npc1.png"},
	"npc2": {"name": "Pani Grazyna", "romance": false, "texture": "res://assets/characters/npc2.png"}
}

# Daily schedule: each encounter ID appears exactly once
const DAYS := [
	["oscar_1", "gotka_1", "npc1_1"],
	["sekciarz_1", "npc2_1", "skolim_1"],
	["npc1_2", "kukuryniarz_1", "oscar_2"],
	["gotka_2", "sekciarz_2", "npc2_2"],
	["skolim_2", "npc1_3","kukuryniarz_2"]
]

# Encounter orders use [product display name, color display name, design display name].
const ENCOUNTERS := {
	"gotka_1": {"character": "gotka", "order": ["Koszulka", "Czarny", "Fat Cat"]},
	"sekciarz_1": {"character": "sekciarz", "order": ["Przypinka", "Żółty", "Ideis"]},
	"oscar_1": {"character": "oscar", "order": ["Skarpetki", "Biały", "Piwo Janka"]},
	"skolim_1": {"character": "skolim", "order": ["Czapka", "Różowy", "Monsterek"]},
	"kukuryniarz_1": {"character": "kukuryniarz", "order": ["Skarpetki", "Zielony", "Kukuryniarz"]},
	"npc1_1": {"character": "npc1", "order": ["Plakat", "Niebieski", "Hatsune Miku"]},
	"npc2_1": {"character": "npc2", "order": ["Torba", "Czerwony", "Skolim"]},

	"gotka_2": {"character": "gotka", "order": ["Torba", "Biały", "Netflix"]},
	"sekciarz_2": {"character": "sekciarz", "order": ["Brelok", "Pomarańczowy", "Piwo Janka"]},
	"oscar_2": {"character": "oscar", "order": ["Koszulka", "Niebieski", "Hello IT"]},
	"skolim_2": {"character": "skolim", "order": ["Plakat", "Różowy", "Skolim"]},
	"kukuryniarz_2": {"character": "kukuryniarz", "order": ["Naklejki", "Żółty", "Twarz Roblox"]},
	"npc1_2": {"character": "npc1", "order": ["Koszulka", "Czarny", "Poro"]},
	"npc2_2": {"character": "npc2", "order": ["Kubek", "Zielony", "Kruk z Love and Deepspace"]},
	"npc1_3": {"character": "npc1", "order": ["Przypinka", "Zielony", "Hello IT"]}
}

# Route specific entries are examples: edit which route displays each variant
const CHARACTER_APPEARANCES :={
	"gotka": {
		"default": "res://assets/characters/gotka1.png",
		"second_visit": "res://assets/characters/gotka2.png"
	},
	"skolim": {
		"default": "res://assets/characters/skolim1.png",
		"second_visit": "res://assets/characters/skolim2.png"
	},
	"sekciarz": {
		"default": "res://assets/characters/sekciarz1.png",
		"second_visit": "res://assets/characters/sekciarz2.png"
	}
}

# Map order only design desc. to an available merch list label
const DESIGN_ALIASES :={
	"Poro League of Legends": "League of Legends",
	"Kruk z Love and Deepspace": "Love and Deepspace"
}

static func canonical_design(design_name: String) -> String:
	return DESIGN_ALIASES.get(design_name, design_name)
	
static func encounter_visit_number(encounter_id: String) -> int:
	return int(encounter_id.get_slice("_", 1))
	

static func dialogue_timeline_path(
	encounter_id: String,
	phase: String,
	_route: String = ""
) -> String:
	return "res://assets/dialogues/%s_%s.dtl" % [
		encounter_id,
		phase
	]

	
static func encounter_at(day_number: int, customer_number: int) -> Dictionary:
	if day_number < 1 or day_number > DAYS.size():
		return {}
	var ids: Array = DAYS[day_number - 1]
	if customer_number < 0 or customer_number >= ids.size():
		return {}
	var encounter_id: String = ids[customer_number]
	var data: Dictionary = ENCOUNTERS[encounter_id].duplicate(true)
	data["id"] = encounter_id
	return data

static func choice_options(phase: String) -> Array:
	# TODO: Replace test dialogue options with Dialogic timelines.
	if phase == "intro":
		return [
			{"text": "A. Miło cię widzieć!", "points": 2},
			{"text": "B. W czym pomóc?", "points": 1},
			{"text": "C. No, mów szybko.", "points": 0}
		]
	return [
		{"text": "A. Dzięki, wróć do nas!", "points": 2},
		{"text": "B. Do zobaczenia.", "points": 1},
		{"text": "C. Następny!", "points": 0}
	]
	
