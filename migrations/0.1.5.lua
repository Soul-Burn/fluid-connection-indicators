for item in pairs(global) do
    table.insert(global, item)
end
global.update_all = true
if not global.scheduler then
    global.scheduler = {
        areas_to_update = {},
        after_tick = 0,
    }
end
if not global.indicators then
    global.indicators = {}
end
