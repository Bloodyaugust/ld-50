extends Node2D

signal command_do(command)

enum COMMAND_TYPES {
  MOVE
}

func add_command(command:Dictionary) -> void:
  emit_signal("command_do", command)

func create_command_move(units:Array, target:Vector2) -> Dictionary:
  return {
    "type": COMMAND_TYPES.MOVE,
    "units": units,
    "target": target
  }
