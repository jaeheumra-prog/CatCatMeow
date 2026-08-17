@tool
## A simple inventory implementation that includes all item types and data within the class.
class_name Inventory extends Resource

const SavePathDefinitions = preload("res://src/data/save_paths.gd")
const SaveIO = preload("res://src/data/save_manager.gd")

## All item types available to add or remove from the inventory.
enum ItemTypes { KEY, COIN, BOMB, RED_WAND, BLUE_WAND, GREEN_WAND }

#TODO: I expect we'll want to have a proper inventory definition somewhere. Some folks advocate for
# spreadsheets, but whatever it is should probably integrate with the editor so that level designers
# can easily pick from items from a dropdown list, or something similar.
## Icons associated with the [member ItemTypes].
const ICONS: = {
	ItemTypes.KEY: preload("res://assets/items/key.atlastex"),
	ItemTypes.COIN: preload("res://assets/items/coin.atlastex"),
	ItemTypes.BOMB: preload("res://assets/items/bomb.atlastex"),
	ItemTypes.RED_WAND: preload("res://assets/items/wand_red.atlastex"),
	ItemTypes.BLUE_WAND: preload("res://assets/items/wand_blue.atlastex"),
	ItemTypes.GREEN_WAND: preload("res://assets/items/wand_green.atlastex"),
}

## Emitted when the count of a given item type changes.
signal item_changed(type: ItemTypes)

# Keep track of what is in the inventory. Dictionary keys are an ItemType, values are the amount.
@export var _items: = {}


func _init() -> void:
	for item_name in ItemTypes:
		_items[ItemTypes[item_name]] = 0


## Load the [Inventory] from file or create a new resource, if it was missing. Godot caches calls, 
## so this can be used every time needed.
static func restore() -> Inventory:
	if Engine.is_editor_hint():
		return null

	var save_path := _get_save_path()
	if FileAccess.file_exists(save_path):
		var inventory := SaveIO.load_resource(save_path, ResourceLoader.CACHE_MODE_REUSE) as Inventory
		if inventory:
			return inventory
		push_error("Inventory 저장 파일을 읽지 못해 덮어쓰지 않고 빈 데이터로 실행합니다: %s" % save_path)
		return Inventory.new()
	
	# Either there is no inventory associated with this profile or the file itself could not be
	# loaded. Either way, a new inventory resource must be created.
	var new_inventory: = Inventory.new()
	new_inventory.save()
	return new_inventory


## Increment the count of a given item by one, adding it to the inventory if it does not exist.
func add(item_type: ItemTypes, amount: = 1) -> void:
	# Note that adding negative numbers is possible. Prevent having a total of negative items.
	# NPC: "You cannot have negative potatoes."
	var old_amount: = _items.get(item_type, 0) as int
	_items[item_type] = maxi(old_amount+amount, 0)
	
	item_changed.emit(item_type)


## Decrement the count of a given item by one.
## The item will be removed entirely if there are none remaining. Removing an item that is not
## posessed will do nothing.
func remove(item_type: ItemTypes, amount: = 1) -> void:
	add(item_type, -amount)


## Returns the number of a certain item type posessed by the player.
func get_item_count(item_type: ItemTypes) -> int:
	return _items.get(item_type, 0)


## Returns the icon associated with a given item type.
static func get_item_icon(item_type: ItemTypes) -> Texture:
	return ICONS.get(item_type, null)


## Write the inventory contents to the disk.
func save() -> void:
	var error := SaveIO.save_resource(self, _get_save_path())
	if error != OK:
		push_error("Inventory 저장 실패: %d" % error)


static func _get_save_path() -> String:
	var save_path := SavePathDefinitions.get_inventory_path()
	if SavePathDefinitions.is_development_build():
		var migration_error := SaveIO.migrate_legacy_save(
			SavePathDefinitions.LEGACY_INVENTORY,
			save_path,
			SavePathDefinitions.LEGACY_INVENTORY_BACKUP
		)
		if migration_error != OK:
			push_error("Inventory 기존 개발 저장 이전 실패: %d" % migration_error)
	return save_path
