class_name EnemyCat
extends Gamepiece


signal recruit_requested(enemy)
signal weakened #약화되기 전에 영입 불가능 그거 위해서 ...

enum State {
	NEUTRAL,
	HOSTILE,
	WEAKENED,
	RECRUITED
}
var is_recruited: bool = false
@export var species_id := "basic_cat"

@export_range(1,100,1)
var recruit_health_threshold := 2

var state: State=State.NEUTRAL


@onready var field_health := $FieldHealth as FieldHealth

@onready var recruit_interaction := (
	$RecruitInteraction as Interaction
)

@onready var interaction_popup := (
	$InteractionPopup as InteractionPopup
)

func _ready() -> void:
	# EnemyCat overrides Gamepiece._ready(), so explicitly retain the base
	# registration and idle-processing setup.
	super._ready()
	if is_queued_for_deletion():
		return
	field_health.health_changed.connect(
		_on_health_changed #왜 오류? 1
	)
	field_health.health_depleted.connect(
		_on_health_depleted #왜 오류? 2
	)
	
	#처음에 전투 아이콘
	interaction_popup.emote =(
		InteractionPopup.EmoteTypes.COMBAT
	)
	
	interaction_popup.is_active=true
	
	#약화전 영입 불가
	recruit_interaction.is_active=false
	
func receive_field_damage(
	damage:int,
	source:Node=null
)->void:
	if state == State.RECRUITED:
		return
	if state == State.WEAKENED:
		return
	if state == State.NEUTRAL:
		state=State.HOSTILE #왜 이렇게 했지?
		
	field_health.take_damage(
		damage,
		source
	)
		
func is_combat_target() -> bool:
	return(
		not is_recruited
		and state != State.WEAKENED
		and field_health.health > 0
	)
	
func can_recruit() -> bool:
	return(
		not is_recruited
		and state == State.WEAKENED
	)
	
#이거 시스템 맘에 안들긴 함. 한번 손봐야할듯
func recruit() -> void:
	if not can_recruit():
		print(
			"영입 실패 - 약해지지않았음"
		)
		return

	is_recruited = true
	state = State.RECRUITED
	
	recruit_interaction.is_active=false
	interaction_popup.is_active=false

	print("ENEMY CAT RECRUIT REQUEST : ", name)

	recruit_requested.emit(self)


func _on_health_changed(
	current: int,
	_previous: int,
	_maximum: int
) -> void:

	if is_recruited:
		return

	if current <= recruit_health_threshold:
		_enter_weakened_state()


func _on_health_depleted(
	_source: Node
) -> void:

	if is_recruited:
		return

	# 영입 대상이 죽어버리지 않게 1 HP로 복구
	# 이코드도 한번 유심히 관찰해야할듯 충분히 오류를 불러일이킬수있을거같아
	field_health.set_health(1)

	_enter_weakened_state()


func _enter_weakened_state() -> void:
	if state == State.WEAKENED:
		return

	state = State.WEAKENED

	recruit_interaction.is_active = true

	interaction_popup.emote = (
		InteractionPopup.EmoteTypes.EXCLAMATION
	)

	interaction_popup.is_active = true

	weakened.emit()

	print(
		"ENEMY WEAKENED : ",
		name,
		" | HP=",
		field_health.health
	)
