---@type table<string, data.ModBoolSettingPrototype>
local bool_settings = data.raw["bool-setting"]

for _, name in pairs{
	"color-coded-pipes-show-rainbow-recipes",
	"color-coded-pipes-show-fluid-recipes",
	"color-coded-pipes-show-pride-recipes",
	"color-coded-pipes-regroup-recipes",
} do
	local setting = bool_settings[name]
	setting.forced_value = false
	setting.hidden = true
end

-- This settings doesn't make sense with the above ones forced false
data.raw["string-setting"]["color-coded-pipes-recipe-ingredients"].hidden = true

-- Replace the pride recipes toggle with my own.
data:extend{
	{
		type = "bool-setting",
		name = "placeable-color-coded-pipes-show-pride-pipes",
		setting_type = "startup", -- This.. this could be a runtime setting. I don't want to deal with it changing though
		default_value = false,
	}
}