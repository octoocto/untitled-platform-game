extends RunnerState
class_name AttackState

const OFFSET: Vector2 = Vector2(120, -16)
var HitEffect = preload("res://scenes/particles/hit_effect.tscn")

var attack_f
var attack_u
var attack_d

var sprite  # ref to active attack sprite
var hitbox  # ref to active attack hitbox

var hit_detected: bool = false
var is_grounded: bool = true

func on_init():
    
    attack_f = runner.get_node("attack_f")
    attack_u = runner.get_node("attack_u")
    attack_d = runner.get_node("attack_d")

    attack_f.connect("area_shape_entered", self, "on_area_enter")
    attack_u.connect("area_shape_entered", self, "on_area_enter")
    attack_d.connect("area_shape_entered", self, "on_area_enter")

func on_start(_state_name):

    var axis = buffer.get_action_axis()

    if axis.x > 0:
        runner.facing = Direction.RIGHT
    elif axis.x < 0:
        runner.facing = Direction.LEFT

    if round(axis.y) == -1: # aiming up
        sprite = attack_u.get_node("sprite")
        hitbox = attack_u.get_node("hitbox")
    elif not runner.is_on_floor() and round(axis.y) == 1: # aiming down
        sprite = attack_d.get_node("sprite")
        hitbox = attack_d.get_node("hitbox")
    else:
        sprite = attack_f.get_node("sprite")
        hitbox = attack_f.get_node("hitbox")

    match runner.facing:
        Direction.RIGHT:
            sprite.position = sprite.position.abs()
            hitbox.position = hitbox.position.abs()
            sprite.flip_h = false
        Direction.LEFT:
            sprite.position = sprite.position.abs() * Vector2(-1, 1)
            hitbox.position = hitbox.position.abs() * Vector2(-1, 1)
            sprite.flip_h = true

    if round(axis.y) == -1:  # flip y position when facing up
        sprite.position *= Vector2(1, -1)
        hitbox.position *= Vector2(1, -1)

    sprite.frame = 0
    sprite.playing = true
    runner.sprite.animation = "attack"
    runner.sprite.frame = 0

    hitbox.disabled = false
    hit_detected = false
    is_grounded = runner.is_on_floor()

    # runner.camera.screen_shake(16.0, 0.5)

func on_update(delta):

    if tick <= 5:
        hitbox.disabled = false
    else:
        hitbox.disabled = true

    if runner.is_on_floor():
        runner.apply_friction(delta)

    if (0.3 <= time and time <= 0.5) or not hit_detected:
        runner.apply_gravity(delta)

    if time >= 0.5 or (is_grounded and not runner.is_on_floor()):
        reset_state()

func get_shape(area, area_shape):
    return area.shape_owner_get_shape(area.shape_find_owner(area_shape), area_shape)

func on_area_enter(_area_id, area: Area2D, area_shape, _local_shape):
    if not hit_detected:
        runner.velocity.y = 0  # cancel vertical momentum
        runner.airjumps_left = 1  # restore jump
        hit_detected = true
        runner.stun(0.1)

        # effects
        var shape = hitbox.shape
        var contacts = shape.collide_and_get_contacts(
            hitbox.global_transform,
            get_shape(area, area_shape),
            area.global_transform)

        if len(contacts):
            var effect = HitEffect.instance()    
            effect.position = (contacts[0] / 4).floor() * 4
            effect.frame = 0
            $"/root/World".add_child(effect)

        print("num contacts: %s" % [contacts])
        if not runner.no_damage:
            if runner.camera:
                runner.camera.screen_shake(16.0, 0.5)
            runner.play_sound("hit", -10)

func on_end():
    hitbox.disabled = true
    sprite.frame = 4  # hide sprite