require("util")
local math2d = require("math2d")
local update_fluid_entity = require("script/update_fluid_entity")

local function replace_sprites(entity, indicators)
    if global.indicators[entity.unit_number] then
        for _, indicator in pairs(global.indicators[entity.unit_number]) do
            rendering.destroy(indicator)
        end
    end
    global.indicators[entity.unit_number] = next(indicators) and indicators or nil
end

local function schedule_update_area(area)
    if not global.areas_to_update then
        global.areas_to_update = {}
    end
    global.after_tick = game.tick
    table.insert(global.areas_to_update, area)
end

local function schedule_update_entity(entity)
    schedule_update_area { entity.surface, entity.bounding_box }
end

local function update_single_entity(entity)
    local indicators = {}
    if update_fluid_entity(indicators, entity) then
        replace_sprites(entity, indicators)
    end
end

local function enlarge_box(bb, r)
    return { math2d.position.subtract(bb.left_top, { r, r }), math2d.position.add(bb.right_bottom, { r, r }) }
end

local function built(event)
    ---@type LuaEntity
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.unit_number then
        return
    end
    schedule_update_entity(entity)
end

local function removed(event)
    local entity = event.entity
    if not entity or not entity.unit_number then
        return
    end
    replace_sprites(entity, {})
    schedule_update_entity(entity)
end

local function teleported(entity, old_surface_index, old_position)
    local dims = math2d.position.subtract(entity.bounding_box.right_bottom, entity.bounding_box.left_top)
    schedule_update_area(game.surfaces[old_surface_index], math2d.bounding_box.create_from_centre(old_position, dims.x, dims.y))
    schedule_update_area(entity.surface, entity.bounding_box)
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

for _, event in pairs { "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive", "on_player_rotated_entity" } do
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
        schedule_update_entity(event.entity)
    end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    schedule_update_entity(event.destination)
end)

script.on_event(defines.events.on_tick, function()
    if global.areas_to_update and global.after_tick and game.tick > global.after_tick then
        for _, area in pairs(global.areas_to_update) do
            if area[1].valid then
                for _, neighbor in pairs(area[1].find_entities(enlarge_box(area[2], 1))) do
                    update_single_entity(neighbor)
                end
            end
        end
        global.areas_to_update = {}
    end
    for _, player in pairs(game.players) do
        if player.opened and player.opened.valid then
            schedule_update_entity(player.opened)
        end
    end
end)
