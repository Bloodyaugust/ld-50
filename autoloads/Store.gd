extends Node

signal state_changed(state_key, substate)

var persistent_store:PersistentStore
var state: Dictionary = {
  "client_view": "",
  "game": "",
  "unit_selection": [],
  "debug": false,
  "attack_move_command_modifier": false,
  "level": null
 }

func add_player(team:int, ai:bool) -> String:
  var _store_key:String = get_team_key(team)

  set_state(_store_key, {
    "team": team,
    "unit_count": 0,
    "alive": true,
    "ai": ai
  })

  return _store_key

func get_team_key(team:int) -> String:
  return "player-%d" % team

func start_game() -> void:
  set_state("client_view", ClientConstants.CLIENT_VIEW_NONE)
  set_state("unit_selection", [])

  for _key in state.keys():
    if "player-" in _key:
      state.erase(_key)

  add_player(0, false)
  add_player(1, true)
  add_player(2, true)
  add_player(3, true)

  set_state("game", GameConstants.GAME_STARTING)

func save_persistent_store() -> void:
  if ResourceSaver.save(ClientConstants.CLIENT_PERSISTENT_STORE_PATH, persistent_store) != OK:
    print("Failed to save persistent store")

func set_state(state_key: String, new_state) -> void:
  state[state_key] = new_state
  emit_signal("state_changed", state_key, state[state_key])
  print("State changed: ", state_key, " -> ", state[state_key])

func set_team_state(team:int, sub_key:String, substate) -> void:
  var _store_key:String = get_team_key(team)
  var _team_object:Dictionary = state[_store_key]

  _team_object[sub_key] = substate

  set_state(_store_key, _team_object)
  
func _initialize():
  set_state("client_view", ClientConstants.CLIENT_VIEW_SPLASH)
  set_state("game", GameConstants.GAME_OVER)
  set_state("unit_selection", [])

func _ready():
  if Directory.new().file_exists(ClientConstants.CLIENT_PERSISTENT_STORE_PATH):
    persistent_store = load(ClientConstants.CLIENT_PERSISTENT_STORE_PATH)

  if !persistent_store:
    persistent_store = PersistentStore.new()
    save_persistent_store()

  call_deferred("_initialize")
