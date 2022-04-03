extends KinematicBody2D

enum UNIT_STATES {
  IDLE,
  MOVING,
  ATTACKING,
  ATTACK_MOVING
}

export var unit_data:Resource
export var team:int

var alive:bool = true

onready var _animation_player:AnimationPlayer = find_node("AnimationPlayer")
onready var _sprite:Sprite = find_node("Sprite")
onready var _state_label:Label = find_node("State")

var _attack_target
var _health:float
var _distance_frames:Array = []
var _last_command
var _state:int
var _time_to_attack:float

func _do_attack_move() -> void:
  _distance_frames = []
  _state = UNIT_STATES.ATTACK_MOVING

func _do_move() -> void:
  _distance_frames = []
  _state = UNIT_STATES.MOVING

func _draw():
  if Store.state.debug:
    draw_arc(Vector2.ZERO, unit_data.attack_range, 0, PI * 2, 16, Color.red)

  if self in Store.state.unit_selection:
    draw_arc(Vector2.ZERO, 25, 0, PI * 2, 16, Color.green)

func _is_valid_target(potential_target) -> bool:
  return GDUtil.reference_safe(potential_target) && potential_target.alive && potential_target.team != team && potential_target.global_position.distance_to(global_position) <= unit_data.attack_range

func _on_command_do(command:Dictionary) -> void:
  match command.type:
    CommandController.COMMAND_TYPES.ATTACK_MOVE:
      if self in command.units:
        _last_command = command
        _do_attack_move()

    CommandController.COMMAND_TYPES.MOVE:
      if self in command.units:
        _last_command = command
        _do_move()

    CommandController.COMMAND_TYPES.DAMAGE:
      if self == command.target:
        _health -= command.data.damage

func _physics_process(delta):
  if alive && (_state == UNIT_STATES.MOVING || _state == UNIT_STATES.ATTACK_MOVING):
    var _direction_vector:Vector2 = global_position.direction_to(_last_command.target)

    move_and_slide(_direction_vector * unit_data.move_speed)

    _distance_frames.append(global_position)
    if _distance_frames.size() > 64:
      _distance_frames.pop_front()

    var _total_distance:float = 0
    for i in range(1, _distance_frames.size()):
      _total_distance += _distance_frames[i].distance_to(_distance_frames[i - 1])

    if _distance_frames.size() >= 16 && _total_distance / _distance_frames.size() < (unit_data.move_speed * delta) / 4:
      _state = UNIT_STATES.IDLE
      if _last_command.type == CommandController.COMMAND_TYPES.MOVE:
        _last_command = null
        return

    if global_position.distance_to(_last_command.target) <= unit_data.move_speed * delta:
      _state = UNIT_STATES.IDLE
      _last_command = null

  if alive && _state == UNIT_STATES.IDLE:
    move_and_slide(Vector2(0, sin(Time.get_ticks_msec())) / 16)

func _process(delta):
  var _advance_animation:bool = false

  if alive:
    if _health <= 0:
      alive = false
      queue_free()

  if alive:
    _time_to_attack -= delta

    if _state == UNIT_STATES.IDLE || _state == UNIT_STATES.ATTACK_MOVING:
      if !_is_valid_target(_attack_target):
        _attack_target = null

        var _units = get_tree().get_nodes_in_group("units")

        for _unit in _units:
          if _is_valid_target(_unit):
            _attack_target = _unit
            break

      if _is_valid_target(_attack_target):
        _state = UNIT_STATES.ATTACKING
      else:
        _state = UNIT_STATES.IDLE

    if _state == UNIT_STATES.ATTACKING:
      if !_is_valid_target(_attack_target):
        _state = UNIT_STATES.IDLE

    match _state:
      UNIT_STATES.ATTACKING:
        if _time_to_attack <= 0 && _is_valid_target(_attack_target):
          _animation_player.play("attack")
          CommandController.add_command(CommandController.create_command_damage({
            "damage": unit_data.damage
          }, _attack_target))
          _time_to_attack = unit_data.attack_interval

      UNIT_STATES.IDLE:
        if _last_command:
          match _last_command.type:
            CommandController.COMMAND_TYPES.ATTACK_MOVE:
              _do_attack_move()
            CommandController.COMMAND_TYPES.MOVE:
              _do_move()
        else:
          if _animation_player.current_animation != "idle":
            _advance_animation = true
          _animation_player.play("idle")

    match _state:
      UNIT_STATES.MOVING:
        if _animation_player.current_animation != "move":
          _advance_animation = true
        _animation_player.play("move")

      UNIT_STATES.ATTACK_MOVING:
        if _animation_player.current_animation != "move":
          _advance_animation = true
        _animation_player.play("move")

    if _advance_animation:
      _animation_player.advance(rand_range(0.0, 0.25) * _animation_player.current_animation_length)
    
  if Store.state.debug:
    _state_label.visible = true
    match _state:
      UNIT_STATES.ATTACK_MOVING:
        _state_label.text = "AM"
      UNIT_STATES.MOVING:
        _state_label.text = "M"
      UNIT_STATES.IDLE:
        _state_label.text = "I"
      UNIT_STATES.ATTACKING:
        _state_label.text = "A"
  else:
    _state_label.visible = false

  update()

func _ready():
  CommandController.connect("command_do", self, "_on_command_do")

  _health = unit_data.health
  _sprite.texture = unit_data.sprite
  _state = UNIT_STATES.IDLE

  for _group in unit_data.groups:
    add_to_group(_group)

  _animation_player.play("idle")
