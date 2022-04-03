extends KinematicBody2D

export var attack_range:float
export var attack_interval:float
export var damage:float
export var health:float
export var move_speed:float
export var team:int

var alive:bool = true

var _attack_target
var _health:float
var _distance_frames:Array = []
var _move_target:Vector2
var _moving:bool
var _time_to_attack:float

func _draw():
  if Store.state.debug:
    draw_arc(Vector2.ZERO, attack_range, 0, PI * 2, 16, Color.red)

func _is_valid_target(potential_target) -> bool:
  return GDUtil.reference_safe(potential_target) && potential_target.alive && potential_target.team != team && potential_target.global_position.distance_to(global_position) <= attack_range

func _on_command_do(command:Dictionary) -> void:
  match command.type:
    CommandController.COMMAND_TYPES.MOVE:
      if self in command.units:
        _move_target = command.target
        _moving = true
        _distance_frames = []

    CommandController.COMMAND_TYPES.DAMAGE:
      if self == command.target:
        _health -= command.data.damage

func _physics_process(delta):
  if alive && _moving:
    var _direction_vector:Vector2 = global_position.direction_to(_move_target)

    move_and_slide(_direction_vector * move_speed)

    _distance_frames.append(global_position)
    if _distance_frames.size() > 64:
      _distance_frames.pop_front()

    var _total_distance:float = 0
    for i in range(1, _distance_frames.size()):
      _total_distance += _distance_frames[i].distance_to(_distance_frames[i - 1])

    if _distance_frames.size() >= 16 && _total_distance / _distance_frames.size() < (move_speed * delta) / 2:
      _moving = false

    if global_position.distance_to(_move_target) <= move_speed * delta:
      _moving = false

func _process(delta):
  if alive:
    if _health <= 0:
      alive = false
      queue_free()

  if alive:
    _time_to_attack -= delta

    if !_is_valid_target(_attack_target):
      _attack_target = null

      var _units = get_tree().get_nodes_in_group("units")

      for _unit in _units:
        if _is_valid_target(_unit):
          _attack_target = _unit
          break

    if _time_to_attack <= 0 && _is_valid_target(_attack_target):
      CommandController.add_command(CommandController.create_command_damage({
        "damage": damage
      }, _attack_target))
      _time_to_attack = attack_interval
      
  if Store.state.debug:
    update()

func _ready():
  CommandController.connect("command_do", self, "_on_command_do")

  _health = health
