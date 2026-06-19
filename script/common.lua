local common = {}

common.ignored_rail_neighbors = util.list_to_map {
    "straight-rail", "curved-rail", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon",
    "curved-rail-a", "curved-rail-b", "half-diagonal-rail",
    "legacy-curved-rail", "legacy-straight-rail",
}
common.inserter_distance = 3
common.render_layer = 191 -- 1 layer above the default layer "arrow" (190)

return common