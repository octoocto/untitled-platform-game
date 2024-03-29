#================================================================================
# A sound manager that contains and plays various character sounds.
#================================================================================

extends Node2D

@onready var sounds = {
    "walk": preload("res://assets/sounds/walking.ogg"),
    "dash": preload("res://assets/sounds/dash.ogg"),
    "jump": preload("res://assets/sounds/jump.ogg"),
    "land": preload("res://assets/sounds/land.ogg"),
    "hit":  preload("res://assets/sounds/hit_sound.mp3"),
    "attack":  preload("res://assets/sounds/attack.wav"),
}

@onready var players = {}

func _ready():
    for sound in sounds:
        players[sound] = AudioStreamPlayer.new()
        players[sound].stream = sounds[sound]
        add_child(players[sound])

func play(sound_name, volume_db = 0.0, pitch_scale = 1.0, loop = false, force = true):
    var player = players[sound_name]

    if player.stream is AudioStreamWAV:
        if loop:
            player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        else:
            player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    else:
        player.stream.loop = loop

    player.volume_db = volume_db
    player.pitch_scale = pitch_scale
    if force or not player.playing:
        player.play()


func stop(sound_name):
    players[sound_name].playing = false
