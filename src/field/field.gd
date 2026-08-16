extends Node2D

const PLAYER_HEALTH_SCENE := preload("res://src/field/combat/field_health.tscn")
const PLAYER_HIT_BOX_SCENE := preload("res://src/field/combat/field_hit_box.tscn")

## The cutscene that will play on starting a new game.
@export var opening_cutscene: Cutscene

## A PlayerController that will be dynamically assigned to whichever Gamepiece the player currently
## controls.
@export var player_controller: PackedScene

## 조종 중인 Gamepiece에 자동으로 붙일 실시간 필드 공격 컴포넌트입니다.
@export var player_attack: PackedScene

## The first gamepiece that the player will control. This may be null and assigned via an
## introductory cutscene instead.
@export var player_default_gamepiece: Gamepiece


func _ready() -> void:
	randomize()
	
	# Assign proper controllers to player gamepieces whenever they change.
	Player.gamepiece_changed.connect(
		func _on_player_gp_changed() -> void:
			var new_gp: = Player.gamepiece
			Camera.gamepiece = new_gp
	
			# 이전 조종 캐릭터에 남은 컨트롤러와 공격 컴포넌트를 정리합니다.
			for controller in get_tree().get_nodes_in_group(PlayerController.GROUP):
				controller.queue_free()
			for attack in get_tree().get_nodes_in_group(FieldComboAttack.GROUP):
				attack.queue_free()
			
			if new_gp:
				var new_controller = player_controller.instantiate()
				assert(new_controller is PlayerController, "The Field game state requires a valid
					 PlayerController set in the editor!")
				
				new_gp.add_child(new_controller)
				new_controller.is_active = true
				_ensure_player_field_health(new_gp)

				if player_attack:
					var new_attack := player_attack.instantiate()
					assert(new_attack is FieldComboAttack,
						"Field.player_attack must instantiate a FieldComboAttack.")
					new_gp.add_child(new_attack)
	)
	
	Player.gamepiece = player_default_gamepiece
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will
	# initiate combat.
	CombatEvents.combat_initiated.connect(func(): hide())
	CombatEvents.combat_finished.connect(func(_is_victory): show())
	
	Camera.scale = scale
	Camera.make_current()
	Camera.reset_position()
	
	if opening_cutscene:
		opening_cutscene.run.call_deferred()


func _ensure_player_field_health(gamepiece: Gamepiece) -> void:
	if not gamepiece.has_node("FieldHealth"):
		var health := PLAYER_HEALTH_SCENE.instantiate() as FieldHealth
		health.max_health = 12
		gamepiece.add_child(health)
	if gamepiece.follower.has_node("FieldHitBox"):
		return
	var hit_box := PLAYER_HIT_BOX_SCENE.instantiate() as FieldHitBox
	hit_box.team = &"player"
	hit_box.health_path = NodePath("../../FieldHealth")
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	(hit_box.get_node("CollisionShape2D") as CollisionShape2D).shape = shape
	gamepiece.follower.add_child(hit_box)
