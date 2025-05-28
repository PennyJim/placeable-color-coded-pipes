local library = {}

---@type string[]
local handled = {
	"pipe",
	"pipe-to-ground",
	"pump",
	"storage-tank",
}

--- Borrowed from Color Coded Pipes directly 1.3.0
if script.active_mods["pipe_plus"] then
	table.insert(handled, "pipe-to-ground-2")
	table.insert(handled, "pipe-to-ground-3")
end
if script.active_mods["Flow Control"] then
	table.insert(handled, "pipe-elbow")
	table.insert(handled, "pipe-junction")
	table.insert(handled, "pipe-straight")
end
if script.active_mods["StorageTank2_2_0"] then
	table.insert(handled, "storage-tank2")
end
if script.active_mods["zithorian-extra-storage-tanks-port"] then
	table.insert(handled, "fluid-tank-1x1")
	table.insert(handled, "fluid-tank-2x2")
	table.insert(handled, "fluid-tank-3x4")
	table.insert(handled, "fluid-tank-5x5")
end

---@type table<string,string>
local colored_items = {}
---@type table<string,string>
local root_items = {}
for name, value in pairs(prototypes.get_item_filtered{
	{filter = "place-result", elem_filters = {
		{filter = "type", type = "pipe"},
		{filter = "type", type = "pipe-to-ground"},
		{filter = "type", type = "pump"},
		{filter = "type", type = "storage-tank"},
	}}
}) do
	local color, base_type = name:match("^(.+)%-color%-coded%-(.+)$")
	if color then
		colored_items[name] = color
		root_items[name] = base_type
	end
end

for _, base_type in pairs(handled) do
	colored_items[base_type] = "default_color"
	root_items[base_type] = base_type
end

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