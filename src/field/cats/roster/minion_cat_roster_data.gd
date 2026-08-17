class_name MinionCatRosterData
extends Resource

@export var cats: Array[MinionCatData] = []
@export var unlocked_species: PackedStringArray = ["basic_cat"]
@export var unlocked_work: PackedStringArray = ["FISHING"]
@export var tuna_cans := 0
@export var mackerels := 0
@export var salmons := 0
@export var reputation := 0
@export var items: Dictionary = {
	"catnip": 0,
	"training_treat": 0,
	"bond_badge": 0,
}
