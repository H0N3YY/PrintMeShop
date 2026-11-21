extends Node

# Autoload this script as GameState in Project Settings > Globals > Autoload.
signal love_changed(character_id: String, new_value: int)
signal encounter_finished(result: Dictionary)
signal day_finished(summary: Dictionary)
signal game_finished(ending: Dictionary)

var day: int = 1
var customer_position: int = 0
var love: Dictionary = {}
var completed: Dictionary = {}
var daily_correct: int = 0
var daily_wrong: int = 0
var daily_love: int = 0
var dialogue_choice_points: int = -1

func _ready() -> void:
	new_game()

func new_game() -> void:
	day = 1
	customer_position = 0
	love.clear()
	completed.clear()
	daily_correct = 0
	daily_wrong = 0
	daily_love = 0
	dialogue_choice_points = -1
	for character_id in GameData.CHARACTERS:
		if GameData.CHARACTERS[character_id]["romance"]:
			love[character_id] = 0
			
func reset_dialogue_choice() -> void:
	dialogue_choice_points = -1
	
func set_dialogue_choice(points: int) -> void:
	dialogue_choice_points = clampi(points, 0, 2)
	
func relationship_route(character_id: String, additional_points: int = 0) -> String:
	if not love.has(character_id):
		return "neutral"
	var projected_score: int = int(love[character_id]) + additional_points
	if projected_score >= GameData.ENDING_GOOD_MIN:
		return "good"
	if projected_score >= GameData.ENDING_NEUTRAL_MIN:
		return "neutral"
	return "bad"

func current_encounter() -> Dictionary:
	return GameData.encounter_at(day, customer_position)

func complete_encounter(order: Dictionary, intro_points: int, pickup_points: int) -> Dictionary:
	var encounter: Dictionary = current_encounter()
	if encounter.is_empty():
		push_error("Current encounter not found")
		return {}
	var id: String = encounter["id"]
	if completed.has(id):
		push_error("Encounter has already been completed: " + id)
		return {}
	var expected: Array = encounter["order"]
	var correct: bool = (
		order.get("product", "") == expected[0]
		and order.get("color", "") == expected[1]
		and GameData.canonical_design(str(order.get("design", ""))) == GameData.canonical_design(str(expected[2]))
	)
	var character_id: String = encounter["character"]
	var is_romance: bool = GameData.CHARACTERS[character_id]["romance"]
	var points: int = clampi(intro_points + pickup_points, 0, 4) if correct and is_romance else 0
	if correct:
		daily_correct += 1
	else:
		daily_wrong += 1
	daily_love += points
	if is_romance:
		love[character_id] += points
		love_changed.emit(character_id, love[character_id])
	var result := {"id": id, "character": character_id, "correct": correct, "points": points}
	completed[id] = result
	encounter_finished.emit(result)
	customer_position += 1
	return result

func has_more_customers_today() -> bool:
	return customer_position < GameData.DAYS[day - 1].size()

func best_character() -> String:
	var best: int = 0
	var winners: Array[String] = []
	for character_id in love:
		var value: int = love[character_id]
		if value > best:
			best = value
			winners = [character_id]
		elif value == best and value > 0:
			winners.append(character_id)
	return winners[0] if winners.size() == 1 else ""

func day_summary() -> Dictionary:
	return {
		"day": day,
		"correct": daily_correct,
		"wrong": daily_wrong,
		"love_gained": daily_love,
		"best": best_character(),
		"love": love.duplicate(true)
	}

func finish_day() -> Dictionary:
	var summary := day_summary()
	day_finished.emit(summary)
	return summary

func go_to_next_day() -> bool:
	if day >= GameData.MAX_DAYS:
		return false
	day += 1
	customer_position = 0
	daily_correct = 0
	daily_wrong = 0
	daily_love = 0
	return true

func final_ending() -> Dictionary:
	var character_id := best_character()
	if character_id == "":
		return {"character": "", "type": "solo", "points": 0, "id": "solo"}
	var score: int = love[character_id]
	var ending_type := "bad"
	if score >= GameData.ENDING_GOOD_MIN:
		ending_type = "good"
	elif score >= GameData.ENDING_NEUTRAL_MIN:
		ending_type = "neutral"
	return {
		"character": character_id, "type": ending_type, "points": score,
		"id": character_id + "_" + ending_type
	}

func finish_game() -> Dictionary:
	var ending := final_ending()
	game_finished.emit(ending)
	return ending
