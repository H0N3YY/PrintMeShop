class_name GameData
extends RefCounted

# Game configuration and ending thresholds
const MAX_DAYS := 5
const ENDING_GOOD_MIN := 6
const ENDING_NEUTRAL_MIN := 3

const PRODUCTS := {
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

const COLORS := {
	"white": "Biały", "black": "Czarny", "pink": "Różowy",
	"red": "Czerwony", "blue": "Niebieski", "green": "Zielony",
	"orange": "Pomarańczowy", "yellow": "Żółty", "gray":"Szary"
}

const DESIGNS := [
	"Fat Cat", "Hatsune Miku", "Hello IT", "Ideis", "Kukuryniarz",
	 "League of Legends", "Love and Deepspace", "Monsterek",
	"Netflix", "Piwo Janka", "Roblox", "Skolim"
]

const CHARACTERS := {
	"gotka": {"name": "Matylda", "romance": true, "texture": "res://assets/characters/gotka1.png"},
	"gotkaGlamur": {"name": "Matylda", "romance": true, "texture": "res://assets/characters/gotka2.png"},
	"oscar": {"name": "Osci", "romance": true, "texture": "res://assets/characters/osci.png"},
	"skolim": {"name": "Skolim", "romance": true, "texture": "res://assets/characters/skolim1.png"},
	"skolimHot": {"name": "Skolim", "romance": true, "texture": "res://assets/characters/skolim2.png"},
	"sekciarz": {"name": "Ideisek", "romance": true, "texture": "res://assets/characters/sekciarz1.png"},
	"sekciarzFurry": {"name": "Ideisek", "romance": true, "texture": "res://assets/characters/sekciarz2.png"},
	"kukuryniarz": {"name": "Norbi Kukuryniarz", "romance": true, "texture": "res://assets/characters/kukuryniarz.png"},
	"npc1": {"name": "Pan Janusz", "romance": false, "texture": "res://assets/characters/npc1.png"},
	"npc2": {"name": "Pani Grazyna", "romance": false, "texture": "res://assets/characters/npc2.png"}
}

# Daily schedule: each encounter ID appears exactly once
const DAYS := [
	["oscar_1", "gotka_1", "npc1_1"],
	["ideis_1", "skolim_1", "npc2_1"],
	["kukuryniarz_1", "oscar_2", "npc1_2"],
	["gotka_2", "ideis_2", "npc2_2"],
	["skolim_2", "kukuryniarz_2", "npc1_3"]
]

# Encounter orders use [product display name, color display name, design display name].
const ENCOUNTERS := {
	"gotka_1": {"character": "gotka", "order": ["Koszulka", "Czarny", "Fat Cat"]},
	"ideis_1": {"character": "ideis", "order": ["Przypinka", "Żółty", "Ideis"]},
	"npc1_1": {"character": "npc1", "order": ["Plakat", "Biały", "Hatsune Miku"]},
	"oscar_1": {"character": "oscar", "order": ["Czapka", "Czarny", "Kukuryniarz"]},
	"skolim_1": {"character": "skolim", "order": ["Koszulka", "Różowy", "Skolim"]},
	"npc2_1": {"character": "npc2", "order": ["Torba", "Zielony", "Hello IT"]},
	"ideis_2": {"character": "ideis", "order": ["Kubek", "Żółty", "Ideis"]},
	"kukuryniarz_1": {"character": "kukuryniarz", "order": ["Breloczek", "Pomarańczowy", "Kukuryniarz"]},
	"npc1_2": {"character": "npc1", "order": ["Naklejki", "Niebieski", "Poro League of Legends"]},
	"gotka_2": {"character": "gotka", "order": ["Czapka", "Różowy", "Fat Cat"]},
	"oscar_2": {"character": "oscar", "order": ["Skarpetki", "Biały", "Kruk z Love and Deepspace"]},
	"npc2_2": {"character": "npc2", "order": ["Plakat", "Czerwony", "Monsterek"]},
	"skolim_2": {"character": "skolim", "order": ["Torba", "Czarny", "Skolim"]},
	"kukuryniarz_2": {"character": "kukuryniarz", "order": ["Kubek", "Pomarańczowy", "Kukuryniarz"]},
	"npc1_3": {"character": "npc1", "order": ["Przypinka", "Zielony", "Hello IT"]}
}

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
