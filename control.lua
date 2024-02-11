require("util")
local flib_bb = require("__flib__/bounding-box")
local update_inserter = require("script/update_inserter")
local update_fluid_entity = require("script/update_fluid_entity")
local common = require("script/common")

local types_to_update = {
    "inserter", "boiler", "assembling-machine", "furnace", "rocket-silo", "fluid-turret", "generator", "mining-drill",
    "offshore-pump", "pump", "storage-tank",
}

local function ensure_global()
    if not global.scheduler then
        global.scheduler = {
            areas_to_update = {},
            after_tick = 0,
        }
    end
    if not global.indicators then
        global.indicators = {}
    end
end

local function replace_sprites(entity, indicators)
    if global.indicators[entity.unit_number] then
        for _, indicator in pairs(global.indicators[entity.unit_number]) do
            rendering.destroy(indicator)
        end
    end
    global.indicators[entity.unit_number] = next(indicators) and indicators or nil
end

local function schedule_update_area(area)
    global.scheduler.after_tick = game.tick
    table.insert(global.scheduler.areas_to_update, area)
end

local function schedule_update_entity(entity)
    schedule_update_area { entity.surface, entity.bounding_box }
end

local function update_single_entity(entity, force_update)
    if not entity.valid then
        return
    end
    local indicators = {}
    local updated = force_update or false
    local fluid_mode = settings.global["fci-fluid-entities"].value
    if fluid_mode ~= "off" then
        updated = update_fluid_entity(indicators, entity, fluid_mode == "lite") or updated
    end
    if settings.global["fci-inserters"].value then
        updated = update_inserter(indicators, entity) or updated
    end
    if updated then
        replace_sprites(entity, indicators)
    end
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
    schedule_update_area(game.surfaces[old_surface_index], flib_bb.recenter_on(entity.bounding_box, old_position))
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

local function handle_scheduled_updates(scheduler)
    if game.tick > scheduler.after_tick then
        for _, area in pairs(scheduler.areas_to_update) do
            if area[1].valid then
                for _, neighbor in pairs(area[1].find_entities(flib_bb.resize(area[2], common.inserter_distance))) do
                    update_single_entity(neighbor)
                end
            end
        end
        scheduler.areas_to_update = {}
    end
end

local function handle_opened_entity()
    for _, player in pairs(game.players) do
        if player.opened and player.opened_gui_type == defines.gui_type.entity and player.opened.valid then
            schedule_update_entity(player.opened)
        end
    end
end

local function iterate_all()
    for _, indicators in pairs(global.indicators) do
        for _, indicator in pairs(indicators) do
            rendering.destroy(indicator)
        end
    end
    global.indicators = {}

    local forces = {}
    for _, force in pairs(game.forces) do
        if #force.players > 0 then
            table.insert(forces, force)
        end
    end

    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered { force = forces, type = types_to_update }) do
            update_single_entity(entity, true)
        end
    end
end

script.on_init(function()
    ensure_global()
    register_dollies()
    global.update_all = true
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
    if global.update_all then
        iterate_all()
        global.update_all = nil
    end
    handle_scheduled_updates(global.scheduler)
    handle_opened_entity()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting:match("^fci%-") then
        iterate_all()
    end
end)
