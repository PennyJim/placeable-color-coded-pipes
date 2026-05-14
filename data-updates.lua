local ccp_constants = require("__color-coded-pipes__.scripts.constants")
local item_prototypes = data.raw["item"]

for _, entity in pairs(ccp_constants.base_entities) do
	for color in pairs(ccp_constants.pipe_colors) do
		local prototype = item_prototypes[color.."-color-coded-"..entity.name]
		if not prototype then goto continue end

		prototype.flags = prototype.flags or {}
		for _, flag in pairs(prototype.flags) do
			if flag == "only-in-cursor" then goto continue end
		end
		prototype.flags[#prototype.flags+1] = "only-in-cursor"

    ::continue::
	end
end