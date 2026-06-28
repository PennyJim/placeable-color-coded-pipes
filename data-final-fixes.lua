if not mods["the-one-mod-with-underground-bits"] then return end

for pipe_name, pipe in pairs(data.raw["pipe"]) do
	if pipe_name:find("tomwub%-") then
		---@type data.ItemToPlace[]
		local placeable_by = {
			{item = pipe_name, count = 1},
			{item = "pipe", count = 1},
		}
		pipe.placeable_by = placeable_by
	end
end