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

local denied_types = util.list_to_map { "pipe", "pipe-to-ground", "fluid-turret" }

local tints = {
    error = { 1.0, 0.0, 0.0 },
    warning = { 1.0, 1.0, 0.0 },
    good = { 0.0, 1.0, 0.0 },
    ignored = { 0.5, 0.5, 0.5 },
}

local function calculate_any_connected(pipe_connection, ignored_entity)
    for _, conn in pairs(pipe_connection) do
        if conn.target and conn.target.owner ~= ignored_entity then
            return true
        end
    end
    return false
end

local function calculate_tint(entity, conn, ignored_entity, any_connected, filter)
    if conn.target and conn.target.owner ~= ignored_entity then
        if conn.flow_direction == "input-output" then
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

    local indication_level = any_connected and 1 or 2
    local neighbor = entity.surface.find_entities_filtered { position = conn.target_position, limit = 1 }[1]
    if neighbor and neighbor ~= ignored_entity then
        indication_level = indication_level + 1 + (#neighbor.fluidbox > 0 and 1 or 0)
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

local function update_entity(entity, ignored_entity)
    if denied_types[entity.type] or #entity.fluidbox == 0 then
        return
    end
    local fb = entity.fluidbox
    delete_sprites(entity)
    local indicators = {}
    global.indicators[entity.unit_number] = indicators
    for i = 1, #fb do
        local any_connected = calculate_any_connected(fb.get_pipe_connections(i), ignored_entity)
        local filter = fb.get_filter(i)
        for _, conn in pairs(fb.get_pipe_connections(i)) do
            local tint = calculate_tint(entity, conn, ignored_entity, any_connected, filter)
            if tint then
                table.insert(indicators, draw_indicator(entity, conn, tint))
            end
        end
    end
end

local function enlarge_box(bb, r)
    return { math2d.position.subtract(bb.left_top, { r, r }), math2d.position.add(bb.right_bottom, { r, r }) }
end

local function update_neighbors(entity, ignore_me)
    local ignored_entity = ignore_me and entity or nil
    for _, neighbor in pairs(entity.surface.find_entities_filtered { area = enlarge_box(entity.bounding_box, 1) }) do
        if neighbor ~= entity then
            update_entity(neighbor, ignored_entity)
        end
    end
end

local function built(event)
    ---@type LuaEntity
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.unit_number then
        return
    end
    update_entity(entity)
    update_neighbors(entity)
end

local function removed(event)
    local entity = event.entity
    if not entity or not entity.unit_number then
        return
    end
    delete_sprites(entity)
    global.indicators[entity.unit_number] = nil
    update_neighbors(entity, true)
end

script.on_init(function()
    global.indicators = {}
    for _, force in pairs(game.forces) do
        if #force.players > 0 then
            for _, surface in pairs(game.surfaces) do
                for _, entity in pairs(surface.find_entities_filtered { force = force }) do
                    update_entity(entity)
                end
            end
        end
    end
end)

for _, event in pairs { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" } do
    script.on_event(defines.events[event], built)
end

for _, event in pairs { "on_entity_died", "on_player_mined_entity", "on_robot_mined_entity", "script_raised_destroy" } do
    script.on_event(defines.events[event], removed)
end

script.on_event(defines.events.on_player_rotated_entity, built)
