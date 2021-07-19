local function on_keypress(event)
    local player = game.players[event.player_index]
    local entity = player.selected
    local sound_paths = {on="utility/upgrade_selection_ended",
        off="utility/upgrade_selection_started"}

    -- validate entity, player reach and force
    if entity and entity.valid and player.can_reach_entity(entity) and player.force.name == entity.force.name then
        -- toggle if selected entity is of "constant-combinator" type
        if entity.type == "constant-combinator" then
            local control = entity.get_or_create_control_behavior()
            control.enabled = not control.enabled

            -- choose sound cue based on new combinator state
            local sound_path = control.enabled and sound_paths["on"] or sound_paths["off"]
            entity.surface.play_sound({position=entity.position, path=sound_path})
        end
    end
end

script.on_event("combinator-toggle-key", on_keypress)