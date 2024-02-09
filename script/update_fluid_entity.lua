require("util")
local math2d = require("math2d")
local common = require("common")

local tints = {
    error = { 1.0, 0.0, 0.0 },
    warning = { 1.0, 1.0, 0.0 },
    good = { 0.0, 1.0, 0.0 },
    ignored = { 0.5, 0.5, 0.5 },
}

local function draw_fluid_indicator(entity, conn, tint)
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

local function neighbor_is_ignored(entity, neighbor)
    return entity.type == "pump" and common.ignored_rail_neighbors[neighbor.type]
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

local function update_fluid_entity(indicators, entity)
    local fb = entity.fluidbox
    if denied_types[entity.type] or #fb == 0 then
        return false
    end
    for i = 1, (entity.type == "fluid-turret" and 1 or #fb) do
        local any_connected = calculate_any_connected(fb.get_pipe_connections(i))
        local filter = fb.get_filter(i)
        for _, conn in pairs(fb.get_pipe_connections(i)) do
            local tint = calculate_tint(entity, conn, any_connected[conn.flow_direction], filter)
            if tint then
                table.insert(indicators, draw_fluid_indicator(entity, conn, tint))
            end
        end
    end
    return true
end

return update_fluid_entity
