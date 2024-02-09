local common = {}

common.ignored_rail_neighbors = util.list_to_map { "straight-rail", "curved-rail", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }
common.inserter_distance = 3

return common