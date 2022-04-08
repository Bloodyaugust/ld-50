extends Node2D

enum AI_TYPES {
  NORMAL
 }

const AI_SCRIPTS:Array = [
  preload("res://scripts/ai/normal.gd")
 ]

export(AI_TYPES) var ai_type
export var team:int

onready var _brain = find_node("Brain")

func _ready():
  _brain.set_script(AI_SCRIPTS[ai_type])
