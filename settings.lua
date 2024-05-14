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
    {
        type = "bool-setting",
        name = "fci-on-hover-mode",
        setting_type = "runtime-global",
        default_value = false,
        order = "c",
    },
    {
        type = "string-setting",
        name = "fci-ignored-entities",
        setting_type = "runtime-global",
        default_value = "",
        allow_blank = true,
        auto_trim = true,
        order = "d",
    },
}
