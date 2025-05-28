if not script.active_mods["automatic-underground-pipe-connectors"] then
	return {} -- Skip file if the relevant mod is not enabled
end

---@type event_handler
local handler = {events={}}



local function add_color_coded_undergrounds()
	---@type PipeLookup
	local new_pipes = {}
	for _, lookup in pairs{
		prototypes.fluid,
		{
			["red"]=true,
			["orange"]=true,
			["yellow"]=true,
			["green"]=true,
			["blue"]=true,
			["purple"]=true,
			["pink"]=true,
			["black"]=true,
			["white"]=true
		}
	} do
		for base in pairs(lookup) do
			local pipe_name = base.."-color-coded-pipe"
			local underground_name = base.."-color-coded-pipe-to-ground"
			if prototypes.entity[pipe_name] and prototypes.entity[underground_name] then
				new_pipes[underground_name] = {
					entity = pipe_name,
					item = "pipe",
				}
			end
		end
	end

	remote.call("automatic-underground-pipe-connectors", "add_undergrounds", new_pipes)
end

handler.on_init = add_color_coded_undergrounds
handler.on_configuration_changed = add_color_coded_undergrounds

return handler