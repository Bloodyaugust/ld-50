extends Node2D

const UPDATE_INTERVAL:float = 1.0

var _parent:Node = get_parent()
var _update_timer:float = 0

func _init() -> void:
  _parent = get_parent()
  print("init called on ai")

func _process(delta):
  print("ai updating")
  if Store.state[Store.get_team_key(_parent.team)].alive:
    _update_timer -= delta

    if _update_timer <= 0:
      var _units = get_tree().get_nodes_in_group("units")
      var _own_units = []
      var _enemy_kings = []
      
      for _unit in _units:
        if _unit.team == _parent.team:
          _own_units.append(_unit)
        elif _unit.has_group("kings"):
          _enemy_kings.append("kings")

      CommandController.add_command(CommandController.create_command_attack_move(_own_units, _enemy_kings[0].global_position))
      _update_timer = UPDATE_INTERVAL
