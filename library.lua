local library = {}

---@type string[]
local handled = {
	"pipe",
	"pipe-to-ground",
	"pump",
	"storage-tank",
}

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

return library