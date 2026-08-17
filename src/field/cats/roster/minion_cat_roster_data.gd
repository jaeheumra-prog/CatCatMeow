class_name MinionCatRosterData
extends Resource

@export var cats: Array[MinionCatData] = []

@export var active_minion_id :="" #현재 출전 냥이

@export var unlocked_species: PackedStringArray = ["basic_cat"]
@export var unlocked_work: PackedStringArray = ["FISHING"]

@export var tuna_cans := 0 #참치캔
@export var mackerels := 0 #고등어
@export var salmons := 0 #연어
@export var reputation := 0
@export var items: Dictionary = {
	"catnip": 0,
	"training_treat": 0,
	"bond_badge": 0,
}
