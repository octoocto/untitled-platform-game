class_name SelectLights
extends MenuSelection

var label_on  = "[on] off"
var label_off = "on [off]"

var lights_enabled = true

func get_label(): return "lights"

func get_extra():
    if lights_enabled:
        return label_on
    return label_off

func set_lights(menu, lights):
    lights_enabled = lights
    for node in menu.get_tree().get_nodes_in_group("lights"):
        node.visible = lights_enabled

func on_left(menu):
    set_lights(menu, !lights_enabled)

func on_right(menu):
    set_lights(menu, !lights_enabled)
