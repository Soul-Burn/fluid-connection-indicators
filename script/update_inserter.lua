require("util")
local math2d = require("math2d")
local common = require("common")

local function draw_inserter_indicator(entity, direction)

    local params = {
        tint = { 1.0, 0.0, 0.0 },
        only_in_alt_mode = true,
        surface = entity.surface,
        force = entity.force,
        orientation = 0.5,
        orientation_target = entity.position,
        x_scale = 0.8,
        y_scale = 0.8,
    }

    local target_position
    local offset

    if direction == "pickup" then
        params.sprite = "utility/indication_line"
        target_position = entity.pickup_position
        offset = 2.55
    else
        params.sprite = "utility/indication_arrow"
        target_position = entity.drop_position
        if entity.type == "mining-drill" then
            params.x_scale = 1
            params.y_scale = 1
            params.orientation_target = nil
            params.orientation = entity.orientation
            offset = 3.3
        else
            offset = 2.25
        end
    end

    local direction_vector = math2d.position.subtract(target_position, entity.position)
    params.target = math2d.position.subtract(
        target_position,
        math2d.position.divide_scalar(direction_vector, offset * math2d.position.vector_length(direction_vector))
    )

    return rendering.draw_sprite(params)
end

local function same_tile(vec1, vec2)
    return math.floor(vec1.x) == math.floor(vec2.x) and math.floor(vec1.y) == math.floor(vec2.y)
end

local function pos_to_tile_bb(pos)
    return { { math.floor(pos.x) + 0.1, math.floor(pos.y) + 0.1 }, { math.ceil(pos.x) - 0.1, math.ceil(pos.y) - 0.1 } }
end

local entity_types_with_inventory = util.list_to_map {
    "artillery-turret", "beacon", "boiler", "burner-generator", "container", "logistic-container", "infinity-container",
    "assembling-machine", "rocket-silo", "furnace", "lab", "linked-container", "market", "reactor", "roboport",
    "linked-belt", "loader-1x1", "loader", "splitter", "transport-belt", "underground-belt", "ammo-turret",
    "lane-splitter",
    -- Space age entities
    "agricultural-tower", "asteroid-collector", "cargo-landing-pad", "fusion-reactor", "space-platform-hub",
}

for key in pairs(common.ignored_rail_neighbors) do
    entity_types_with_inventory[key] = true
end

local function valid_position(entity, direction, serving_type)
    local position = entity[direction .. "_position"]
    local other_position_name = direction == "pickup" and "drop_position" or "pickup_position"
    local has_nonblocking_entity = false
    local surface = entity.surface
    for _, neighbor in pairs(surface.find_entities_filtered { area = pos_to_tile_bb(position) }) do
        if entity_types_with_inventory[neighbor.type] or neighbor.burner then
            return true
        end
        if neighbor.name == "item-on-ground" or neighbor.name == "character" then
            has_nonblocking_entity = true
        end
    end
    if has_nonblocking_entity or surface.can_place_entity { name = "pipe", position = position } then
        local area = math2d.bounding_box.create_from_centre(position, 2 * common.inserter_distance)
        for _, inserter in pairs(surface.find_entities_filtered { type = serving_type, area = area }) do
            if same_tile(position, inserter[other_position_name]) then
                return true
            end
        end
    end
    if same_tile(entity.position, position) then
        return true
    end
    return false
end

local function update_inserter(indicators, entity)
    if not entity.drop_position or entity.type == "entity-ghost" then
        return false
    end

    if not valid_position(entity, "drop", "inserter") then
        table.insert(indicators, draw_inserter_indicator(entity, "drop"))
    end

    if entity.type == "inserter" and not valid_position(entity, "pickup", { "inserter", "mining-drill" }) then
        table.insert(indicators, draw_inserter_indicator(entity, "pickup"))
    end

    return true
end

return update_inserter
