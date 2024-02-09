require("util")
local math2d = require("math2d")

local function delete_sprites(entity)
    for _, indicator in pairs(global.indicators[entity.unit_number] or {}) do
        rendering.destroy(indicator)
    end
end

local function draw_indicator(entity, conn, tint)
    return rendering.draw_sprite {
        sprite = conn.flow_direction == "input-output" and "fci-flow-arrow-both-ways" or "fci-flow-arrow",
        tint = tint,
        target = math2d.position.divide_scalar(math2d.position.add(conn.position, conn.target_position), 2),
        orientation_target = (conn.flow_direction == "input" and math2d.position.add or math2d.position.subtract)(
            conn.position, math2d.position.subtract(conn.position, conn.target_position)
        ),
        only_in_alt_mode = true,
        surface = entity.surface,
        force = entity.force,
    }
end

local tints = {
    error = { 1.0, 0.0, 0.0 },
    warning = { 1.0, 1.0, 0.0 },
    good = { 0.0, 1.0, 0.0 },
    ignored = { 0.5, 0.5, 0.5 },
}

local function calculate_any_connected(pipe_connection)
    local connected = { input = false, output = false, ["input-output"] = false }
    for _, conn in pairs(pipe_connection) do
        if conn.target then
            connected[conn.flow_direction] = true
        end
    end
    return connected
end

local denied_types = util.list_to_map { "pipe", "pipe-to-ground" }
local ignored_pump_neighbors = util.list_to_map { "straight-rail", "curved-rail", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }

local function neighbor_is_ignored(entity, neighbor)
    return entity.type == "pump" and ignored_pump_neighbors[neighbor.type]
end

local function calculate_tint(entity, conn, any_connected, filter)
    if conn.target then
        if conn.flow_direction == "input-output" and not denied_types[conn.target.owner.type] then
            local target_flow_direction = conn.target.get_pipe_connections(conn.target_fluidbox_index)[conn.target_pipe_connection_index].flow_direction
            if target_flow_direction ~= "input-output" or conn.target.owner.unit_number > entity.unit_number then
                return nil
            end
        end

        if filter then
            local target_filter = conn.target.get_filter(conn.target_fluidbox_index)
            if target_filter and target_filter.name ~= filter.name then
                return tints.error
            end
        end
        return tints.good
    end

    local indication_level = 2
    if not entity.surface.can_place_entity { name = "pipe", position = conn.target_position } then
        for _, neighbor in pairs(entity.surface.find_entities_filtered { position = conn.target_position }) do
            if neighbor and not neighbor_is_ignored(entity, neighbor) then
                indication_level = 3
                if #neighbor.fluidbox > 0 then
                    indication_level = 4
                    break
                end
            end
        end
    end
    if any_connected then
        indication_level = indication_level - 1
    end
    local ignored = conn.flow_direction ~= "input-output" and tints.ignored or nil
    local levels = {
        ignored,
        any_connected and ignored or nil,
        tints.warning,
        tints.error,
    }
    return levels[indication_level]
end

local function update_single_entity(entity)
    local fb = entity.fluidbox
    if denied_types[entity.type] or #fb == 0 then
        return
    end
    delete_sprites(entity)
    local indicators = {}
    global.indicators[entity.unit_number] = indicators
    for i = 1, (entity.type == "fluid-turret" and 1 or #fb) do
        local any_connected = calculate_any_connected(fb.get_pipe_connections(i))
        local filter = fb.get_filter(i)
        for _, conn in pairs(fb.get_pipe_connections(i)) do
            local tint = calculate_tint(entity, conn, any_connected[conn.flow_direction], filter)
            if tint then
                table.insert(indicators, draw_indicator(entity, conn, tint))
            end
        end
    end
end

local function enlarge_box(bb, r)
    return { math2d.position.subtract(bb.left_top, { r, r }), math2d.position.add(bb.right_bottom, { r, r }) }
end

local function update_area(surface, bounding_box)
    for _, neighbor in pairs(surface.find_entities(enlarge_box(bounding_box, 1))) do
        update_single_entity(neighbor)
    end
end

local function update_entity_area(entity)
    update_area(entity.surface, entity.bounding_box)
end

local function built(event)
    ---@type LuaEntity
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.unit_number then
        return
    end
    update_entity_area(entity, 1)
end

local function schedule_update(entity)
    if not global.areas_to_update then
        global.areas_to_update = {}
    end
    table.insert(global.areas_to_update, { entity.surface, entity.bounding_box })
end

local function removed(event)
    local entity = event.entity
    if not entity or not entity.unit_number then
        return
    end
    delete_sprites(entity)
    global.indicators[entity.unit_number] = nil
    schedule_update(entity)
end

local function teleported(entity, old_surface_index, old_position)
    local dims = math2d.position.subtract(entity.bounding_box.right_bottom, entity.bounding_box.left_top)
    update_area(game.surfaces[old_surface_index], math2d.bounding_box.create_from_centre(old_position, dims.x, dims.y))
    update_area(entity.surface, entity.bounding_box)
end

local function register_dollies()
    local pd = remote.interfaces["PickerDollies"]
    if pd and pd["dolly_moved_entity_id"] then
        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), function(event)
            teleported(event.moved_entity, event.moved_entity.surface.index, event.start_pos)
        end)
    end
end

script.on_init(function()
    register_dollies()
    global.areas_to_update = {}
    global.indicators = {}
    for _, force in pairs(game.forces) do
        if #force.players > 0 then
            for _, surface in pairs(game.surfaces) do
                for _, entity in pairs(surface.find_entities_filtered { force = force }) do
                    update_single_entity(entity)
                end
            end
        end
    end
end)

script.on_load(function()
    register_dollies()
end)

for _, event in pairs { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" } do
    script.on_event(defines.events[event], built)
end

for _, event in pairs { "on_entity_died", "on_player_mined_entity", "on_robot_mined_entity", "script_raised_destroy" } do
    script.on_event(defines.events[event], removed)
end

script.on_event(defines.events.script_raised_teleported, function(event)
    teleported(event.entity, event.old_surface_index, event.old_position)
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.entity then
        update_entity_area(event.entity)
    end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    update_entity_area(event.destination)
end)

script.on_event(defines.events.on_tick, function()
    if global.areas_to_update then
        for _, area in pairs(global.areas_to_update) do
            if area[1].valid then
                update_area(area[1], area[2])
            end
        end
        global.areas_to_update = {}
    end
    for _, player in pairs(game.players) do
        if player.opened and player.opened.valid then
            update_entity_area(player.opened)
        end
    end
end)

script.on_event(defines.events.on_player_rotated_entity, built)
