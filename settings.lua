---@type table<string, data.ModBoolSettingPrototype>
local bool_settings = data.raw["bool-setting"]

for _, name in pairs{
	"color-coded-pipes-show-rainbow-recipes",
	"color-coded-pipes-show-fluid-recipes",
	"color-coded-pipes-regroup-recipes",
} do
	local setting = bool_settings[name]
	setting.forced_value = false
	setting.hidden = true
end

-- This settings doesn't make sense with the above ones forced false
data.raw["string-setting"]["color-coded-pipes-recipe-ingredients"].hidden = true