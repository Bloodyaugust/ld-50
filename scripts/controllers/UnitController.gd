extends Node2D

const LEVEL_0:PackedScene = preload("res://scenes/level-0.tscn")

var _drawing_selection:bool = false
var _drawing_selection_start:Vector2

func _draw():
  if _drawing_selection:
    var _size:Vector2 = get_global_mouse_position() - _drawing_selection_start
    draw_rect(Rect2(_drawing_selection_start, _size), Color.green, false)

func _on_end_drawing_selection() -> void:
  var _mouse_global:Vector2 = get_global_mouse_position()
  var _rect_start:Vector2 = Vector2(min(_mouse_global.x, _drawing_selection_start.x), min(_mouse_global.y, _drawing_selection_start.y))
  var _selection_rect:Rect2 = Rect2(_rect_start, (get_global_mouse_position() - _drawing_selection_start).abs())
  var _units:Array = get_tree().get_nodes_in_group("units")
  var _selected_units:Array = []

  for _unit in _units:
    if _unit.team == 0 && _selection_rect.has_point(_unit.global_position):
      _selected_units.append(_unit)

  _drawing_selection = false
  Store.set_state("unit_selection", _selected_units)
  print("drawing ended")
  print(Store.state.unit_selection)

func _on_store_state_changed(state_key:String, substate) -> void:
  match state_key:
    "game":
      match substate:
        GameConstants.GAME_STARTING:
          var _level = LEVEL_0.instance()

          get_tree().get_root().add_child(_level)
          Store.set_state("game", GameConstants.GAME_IN_PROGRESS)

func _unhandled_input(event:InputEvent):
  if Store.state.game == GameConstants.GAME_IN_PROGRESS:
    if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
      if event.is_pressed():
        print("drawing started")
        _drawing_selection = true
        _drawing_selection_start = get_global_mouse_position()
        Store.set_state("attack_move_command_modifier", false)
      else:
        _on_end_drawing_selection()

    if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT && Store.state.level.point_inside_playable_area(get_global_mouse_position()):
      if Store.state.unit_selection.size() && !event.is_pressed():
        if Store.state.attack_move_command_modifier:
          CommandController.add_command(CommandController.create_command_attack_move(Store.state.unit_selection, get_global_mouse_position()))
        else:
          CommandController.add_command(CommandController.create_command_move(Store.state.unit_selection, get_global_mouse_position()))

    if event is InputEventKey && event.is_action_released("attack_move"):
      if Store.state.unit_selection.size():
        Store.set_state("attack_move_command_modifier", !Store.state.attack_move_command_modifier)

func _process(delta):
  update()

func _ready():
  Store.connect("state_changed", self, "_on_store_state_changed")

  z_index = 10
