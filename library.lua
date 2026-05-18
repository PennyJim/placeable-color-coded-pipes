local ccp_constants = require("__color-coded-pipes__.scripts.constants")
local library = {}

---@type table<string,Color>
local pipe_colors = ccp_constants.rgb_colors
if settings.startup["placeable-color-coded-pipes-show-pride-pipes"].value then
	pipe_colors = ccp_constants.pipe_colors
else
	for fluid_color in pairs(ccp_constants.fluid_to_color_map--[[@as table<string,string>]]) do
		pipe_colors[fluid_color] = ccp_constants.pipe_colors[fluid_color]
	end
end

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

local function default_naming_pattern(color, base)
	return color.."-color-coded-"..base, base
end

---@type string[]
local handled = {}
---A mapping from root item, into a function that'll convert the color and item into a colored item and refill item
---@type table<string,fun(color:string,base:string):string,string>
local naming_pattern = {}

for index, entity in pairs(ccp_constants.base_entities) do
	handled[index] = entity.name
	naming_pattern[entity.name] = default_naming_pattern
end


if script.active_mods["the-one-mod-with-underground-bits"] then
	handled[#handled+1] = "tomwub-pipe"
	naming_pattern["tomwub-pipe"] = function (color, _)
		return "tomwub-"..color.."-color-coded-pipe", "pipe"
	end
end

---A mapping from colored item to color
---@type table<string,string>
local colored_items = {}
---A mapping from colored item to item
---@type table<string,string>
local root_items = {}
---A mapping from colored item to refill item
---@type table<string,string>
local refill_items = {}

for _, base in pairs(handled) do
	local _, refill = naming_pattern[base]("", base)
	colored_items[base] = "default_color"
	root_items[base] = base
	refill_items[base] = refill

	for color in pairs(pipe_colors) do
		local colored_base, refill = naming_pattern[base](color, base)
		colored_items[colored_base] = color
		root_items[colored_base] = base
		refill_items[colored_base] = refill

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
for color in pairs(pipe_colors) do
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

---@param colored_item string
---@return string refill_item
function library.get_refill_item(colored_item)
	return refill_items[colored_item]
end

---@param root_item string
---@param color string
---@return string colored_item
---@return string refill_item
function library.get_colored_item(root_item, color)
	return naming_pattern[root_item](color, root_item)
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