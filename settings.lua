data:extend {
    {
        type = "string-setting",
        name = "fci-fluid-entities",
        setting_type = "runtime-global",
        default_value = "lite",
        allowed_values = {"off", "lite", "full" },
        order = "a",
    },
    {
        type = "bool-setting",
        name = "fci-inserters",
        setting_type = "runtime-global",
        default_value = true,
        order = "b",
    },
}
