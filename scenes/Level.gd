extends Node2D

export var _playable_rect:Rect2

func point_inside_playable_area(point:Vector2) -> bool:
  return _playable_rect.has_point(to_local(point))

func _ready():
  Store.set_state("level", self)
