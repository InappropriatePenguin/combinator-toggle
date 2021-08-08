global.mod_settings = {}

function get_player_settings(player_index)
    local player_options = {
        combinator = settings.get_player_settings(player_index)["combinator-toggle-combinator-setting"].value,
        power_switch = settings.get_player_settings(player_index)["combinator-toggle-power-switch-setting"].value,
        locomotive = settings.get_player_settings(player_index)["combinator-toggle-locomotive-setting"].value
    }

    return player_options
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function (event)
    local player_index = event.player_index
    global.mod_settings = global.mod_settings or {}
    global.mod_settings[player_index] = get_player_settings(player_index)
end)

function play_sound_effect(entity, state, sounds)
    local sound_path = state and sounds["on"] or sounds["off"]
    entity.surface.play_sound({position=entity.position, path=sound_path})
end

function on_keypress(event)
    local player_index = event.player_index
    local player = game.players[player_index]
    local entity = player.selected
    local sound_paths = {
        on="utility/upgrade_selection_ended",
        off="utility/upgrade_selection_started",
        failed="utility/cannot_build"}
    local sound_paths_switch = {
        on="utility/upgrade_selection_ended",
        off="utility/wire_pickup",
    }

    global.mod_settings = global.mod_settings or {}
    global.mod_settings[player_index] = global.mod_settings[player_index] or get_player_settings(player_index)

    if entity and entity.valid then
        if player.can_reach_entity(entity) and player.force.name == entity.force.name then
            -- toggle if selected entity is of "constant-combinator" type
            if entity.type == "constant-combinator" and global.mod_settings[player.index]['combinator'] then
                local control = entity.get_or_create_control_behavior()
                control.enabled = not control.enabled
                play_sound_effect(entity, control.enabled, sound_paths)
            elseif entity.type == "power-switch" and global.mod_settings[player.index]['power_switch'] then
                entity.power_switch_state = not entity.power_switch_state
                play_sound_effect(entity, entity.power_switch_state, sound_paths_switch)
            -- toggle if selected entity is a train
            elseif entity.type == "locomotive" and global.mod_settings[player.index]['locomotive'] then
                entity.train.manual_mode = not entity.train.manual_mode
                play_sound_effect(entity, entity.train.manual_mode, sound_paths)
            end
        else
            entity.surface.play_sound({position=entity.position, path=sound_paths["failed"]})
        end
    end
end

script.on_event("combinator-toggle-key", on_keypress)
