# PuzzleManager.gd - Add this as an Autoload singleton
extends Node

# Store the 9x9 puzzle solution (81 cells)
var puzzle_solution: Array[bool] = []

# Track which sections have been revealed (0, 1, 2 for the 3 vertical sections)
var revealed_sections: Array[int] = []

# Track which chests have had their puzzles solved
var solved_chests: Dictionary = {}

# Initialize puzzle on first load
func _ready():
	if puzzle_solution.is_empty():
		generate_puzzle()

func generate_puzzle():
	puzzle_solution.clear()
	for i in range(81):
		puzzle_solution.append(randi() % 2 == 0)
	print("=== PUZZLE GENERATED ===")
	print("Solution: ", puzzle_solution)

func reveal_section(section_index: int):
	if section_index not in revealed_sections:
		revealed_sections.append(section_index)
		revealed_sections.sort()
		print("=== SECTION ", section_index, " REVEALED ===")
		print("Total revealed sections: ", revealed_sections.size())

func is_section_revealed(section_index: int) -> bool:
	return section_index in revealed_sections

func get_revealed_count() -> int:
	return revealed_sections.size()

func reveal_all():
	for i in range(3):
		reveal_section(i)

func reset_solved_chest():
	solved_chests = {}

func reset_puzzle():
	generate_puzzle()
	revealed_sections.clear()
	print("=== PUZZLE RESET ===")

# New functions for tracking puzzle completion per chest
func mark_chest_puzzle_solved(chest_id: String):
	solved_chests[chest_id] = true
	print("=== CHEST PUZZLE SOLVED: ", chest_id, " ===")

func is_chest_puzzle_solved(chest_id: String) -> bool:
	return solved_chests.get(chest_id, false)
