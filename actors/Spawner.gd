extends Node2D

const SPAWN_INTERVAL:float = 1.5
const UNIT_SCENE:PackedScene = preload("res://actors/Unit.tscn")

export var team:int

var _time_to_spawn:float

func _on_after_unit_spawn(unit:Node2D) -> void:
  CommandController.add_command(CommandController.create_command_move([unit], global_position + Vector2(0, 50)))

func _process(delta):
  _time_to_spawn -= delta
  
  if _time_to_spawn <= 0:
    var _new_unit:Node2D = UNIT_SCENE.instance()
    
    _new_unit.global_position = (GDUtil.random_in_unit_circle() * 15) + global_position - Vector2(0, 20)
    _new_unit.team = team
    
    get_tree().get_root().add_child(_new_unit)
    
    call_deferred("_on_after_unit_spawn", _new_unit)
    _time_to_spawn = SPAWN_INTERVAL

func _ready():
  _time_to_spawn = SPAWN_INTERVAL
