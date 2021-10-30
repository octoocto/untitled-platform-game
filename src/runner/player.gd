extends Runner

var GhostPlayer = preload("res://scenes/GhostPlayer.tscn")

var initial_conditions = null
var replay_frames = {}

# frames where the player's pos and vel are stored,
# used to check for ghost replay deviation
var pos_frames = {}
var fix_interval = 20

var ghost = null

func _ready():
    connect("walking", Sound, "play", ["walk", -20, 0.8, true, false])
    connect("stop_walking", Sound, "stop", ["walk"])
    connect("jump", Sound, "play", ["jump", -10, 1, false])
    connect("land", Sound, "play", ["land", -20])
    connect("hit", Sound, "play", ["hit", -10])
    connect("dash", Sound, "play", ["walk", -20, 0.8, false, true])

func pre_process(delta):


    # needed as sometimes the walking sound does not stop
    if state_name != "running":
        Sound.stop("walk")

    if Game.game_paused:
        return

    if Input.is_action_just_pressed("reset"):
        player_restart()
        return

    # camera panning
    if is_on_floor():
        var camera_offset = Vector2(0, 0)
        var down_held_time = buffer.get_time_held("key_down")
        var up_held_time = buffer.get_time_held("key_up")

        if down_held_time and buffer.get_action_strength("key_down") > 0.9:  # pan down
            # print("down held: %0.2f" % down_held_time)
            camera_offset = lerp(
                Vector2(0, 0), Vector2(0, 80),
                ease(clamp((down_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
            )
        elif up_held_time and buffer.get_action_strength("key_up") > 0.9:  # pan up
            # print("up held: %0.2f" % up_held_time)
            camera_offset = lerp(
                Vector2(0, 0), Vector2(0, -80),
                ease(clamp((up_held_time - 1.0) / 0.5, 0.0, 1.0), -2.8)
            )

        Game.get_camera().set_offset(camera_offset)

    # record initial conditions (position, velocity, etc.)
    if tick == 0:
        initial_conditions = get_current_conditions()

    if tick % fix_interval == 0:
        pos_frames[tick] = [position, velocity]

    # replay recording
    for key in ["key_up", "key_down", "key_left", "key_right", "key_jump", "key_dodge", "grapple", "shoot"]:
        var value = Input.get_action_strength(key)
        buffer.update_action(key, value)

    replay_frames[tick] = buffer.input_map.duplicate()

    get_node("/root/Main/debug/DebugInfo").text = "speed: %3.2f (x=%3.2f, y=%3.2f)\nstate: %s" % [velocity.length(), velocity.x, velocity.y, state_name]

# Do an animated restart
func player_restart():

    # pause during fadeout
    yield(Game.pause_and_fade_out(0.2), "completed")

    # reset level
    Game.restart_level()

    # unpause after fadein
    yield(Game.fade_in_and_unpause(0.2), "completed")

func restart():

    # send replay data to ghost if better complete time
    if Game.is_best_time():
        if ghost == null:
            create_ghost()

        # update ghost replay
        ghost.init(initial_conditions, replay_frames.duplicate(true), pos_frames.duplicate(true))
    else:
        if ghost != null:
            ghost.restart()

    # reset player to start point
    .restart()

    # clear replay data
    replay_frames = {}
    pos_frames = {}


func respawn(pos):

    # pause during fadeout
    yield(Game.pause_and_fade_out(0.2), "completed")

    .respawn(pos)

    # unpause after fadein
    yield(Game.fade_in_and_unpause(0.2), "completed")

func create_ghost():

    print("creating new ghost")
    ghost = GhostPlayer.instance()
    get_parent().add_child(ghost)
    