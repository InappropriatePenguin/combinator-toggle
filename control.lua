global.mod_settings = {}

MOD_PREFIX = "combinator-toggle-"

NAMES = {
    inputs = {combinator_toggle = MOD_PREFIX .. "key"},
    settings = {
        combinator = MOD_PREFIX .. "combinator-setting",
        power_switch = MOD_PREFIX .. "power-switch-setting",
        locomotive = MOD_PREFIX .. "locomotive-setting"
    }
}

function update_player_settings(player_index)
    global.mod_settings[player_index] = {
        combinator = settings.get_player_settings(player_index)[NAMES.settings.combinator].value,
        power_switch = settings.get_player_settings(player_index)[NAMES.settings.power_switch].value,
        locomotive = settings.get_player_settings(player_index)[NAMES.settings.locomotive].value
    }
end

function update_single_setting(event)
    if not event.player_index then return end

    local player_index = event.player_index

    -- get all of this player's settings if they have no mod_settings table
    if not global.mod_settings[player_index] then
        update_player_settings(player_index)
        return
    end

    for key, setting in pairs(NAMES.settings) do
        if event.setting == setting then
            global.mod_settings[player_index][key] = settings.get_player_settings(player_index)[setting].value
        end
    end
end

function play_sound_effect(entity, state, sounds)
    local sound_path = state and sounds.on or sounds.off
    entity.surface.play_sound({position=entity.position, path=sound_path})
end

function create_flying_text(player, entity, state, texts)
    local text = state and texts.on or texts.off
    player.create_local_flying_text({text=text, position=entity.position})
end

function on_keypress(event)
    local player_index = event.player_index
    local player = game.players[player_index]
    local entity = player.selected

    local sound_paths = {
        combinator = {on="utility/upgrade_selection_ended", off="utility/upgrade_selection_started"},
        power_switch = {on="utility/upgrade_selection_ended", off="utility/wire_pickup"},
        failed = "utility/cannot_build"
    }

    local texts = {
        combinator = {on={"combinator-toggle.on"}, off={"combinator-toggle.off"}},
        locomotive = {on={"combinator-toggle.manual"}, off={"combinator-toggle.automatic"}}
    }

    if not global.mod_settings[player_index] then update_player_settings(player_index) end
    if not entity or not entity.valid then return end

    if player.can_reach_entity(entity) and player.force.name == entity.force.name then
        local player_settings = global.mod_settings[player_index]
        -- toggle if selected entity is of "constant-combinator" type
        if entity.type == "constant-combinator" and player_settings.combinator then
            local control = entity.get_or_create_control_behavior()
            control.enabled = not control.enabled
            play_sound_effect(entity, control.enabled, sound_paths.combinator)
            create_flying_text(player, entity, control.enabled, texts.combinator)
        -- toggle if selected entity is a power switch
        elseif entity.type == "power-switch" and player_settings.power_switch then
            entity.power_switch_state = not entity.power_switch_state
            play_sound_effect(entity, entity.power_switch_state, sound_paths.power_switch)
            create_flying_text(player, entity, entity.power_switch_state, texts.combinator)
        -- toggle if selected entity is a train
        elseif entity.type == "locomotive" and player_settings.locomotive then
            entity.train.manual_mode = not entity.train.manual_mode
            play_sound_effect(entity, entity.train.manual_mode, sound_paths.combinator)
            create_flying_text(player, entity, entity.train.manual_mode, texts.locomotive)
        end
    else
        player.play_sound({path=sound_paths.failed})
    end
end

script.on_event(NAMES.inputs.combinator_toggle, on_keypress)
script.on_event(defines.events.on_runtime_mod_setting_changed, update_single_setting)
