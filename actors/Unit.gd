extends KinematicBody2D
export var move_speed:float

var _distance_frames:Array = []
var _move_target:Vector2
var _moving:bool

func _on_command_do(command:Dictionary) -> void:
  match command.type:
    CommandController.COMMAND_TYPES.MOVE:
      if self in command.units:
        _move_target = command.target
        _moving = true
        _distance_frames = []

func _physics_process(delta):
  if _moving:
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

func _ready():
  CommandController.connect("command_do", self, "_on_command_do")
