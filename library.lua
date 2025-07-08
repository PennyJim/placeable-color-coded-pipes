local ccp_constants = require("__color-coded-pipes__.scripts.constants")
local library = {}

---@generic A
---@generic B
---@param tab table<A,B>
---@return table<B,A>
function library.invert_table(tab)
	---@cast tab table<any,any>
	---@type table<any,any>
	local inverted = {}
	for key, value in pairs(tab) do
		inverted[value] = key
	end
	return inverted
end

---@type string[]
local handled = {}
for index, entity in pairs(ccp_constants.base_entities) do
	handled[index] = entity.name
end

---A mapping from colored item to color
---@type table<string,string>
local colored_items = {}
---A mapping from colored item to item
---@type table<string,string>
local root_items = {}

for _, base in pairs(handled) do
	colored_items[base] = "default_color"
	root_items[base] = base

	for color in pairs(ccp_constants.pipe_colors) do
		local colored_base = color.."-color-coded-"..base
		colored_items[colored_base] = color
		root_items[colored_base] = base

		if not prototypes.item[colored_base] then
			log(colored_base.." doesn't exist despite Color Coded Pipes implying it should")
		end
	end
end

---@type string[]
local base_colors, color_index = {}, 0
local base_color_order = ccp_constants.color_order
---@type string[]
local fluid_colors, fluid_index = {}, 0
---@type table<string,string>
local fluid_color_order = {}
for color in pairs(ccp_constants.pipe_colors) do
	if not base_color_order[color] then
		fluid_index = fluid_index + 1
		fluid_colors[fluid_index] = color

		local fluid = prototypes.fluid[color]
		local order = fluid.group.order .. fluid.group.name
		order = order .. fluid.subgroup.order .. fluid.subgroup.name
		order = order .. fluid.order .. fluid.name
		fluid_color_order[color] = order
	else
		color_index = color_index + 1
		base_colors[color_index] = color
	end
end

table.sort(base_colors, function (a, b)
	return base_color_order[a] < base_color_order[b]
end)
table.sort(fluid_colors, function (a, b)
	return fluid_color_order[a] < fluid_color_order[b]
end)

library.colors = base_colors
library.fluids = fluid_colors
library.color_indexies = library.invert_table(base_colors)--[[@as table<string,int>]]
library.fluid_indexies = library.invert_table(fluid_colors)--[[@as table<string,int>]]

---@param given_item string
---@return string root_item
---@return string color
function library.get_root_item(given_item)
	return root_items[given_item], colored_items[given_item]
end

---@param stack LuaItemStack?
---@return boolean valid
function library.valid_stack(stack)
	return stack and stack.valid and stack.valid_for_read or false
end

---@param stack LuaItemStack
function library.set_item_name(stack, new_name)
	return stack.set_stack{
		name = new_name,
		count = stack.count,
		health = stack.health,
		quality = stack.quality,
		spoil_percent = stack.spoil_percent,
	}
end
---@param player LuaPlayer
---@param new_name string
function library.set_cursor_name(player, new_name)
	local cursor = player.cursor_stack
	if library.valid_stack(cursor) then
		---@cast cursor -?
		library.set_item_name(cursor, new_name)
	else
		local ghost = player.cursor_ghost or {}
		player.cursor_ghost = {
			name = new_name,
			quality = ghost.quality
		}
	end
end

return library