local library = {}

---@type string[]
local handled = {
	"pipe",
	"pipe-to-ground",
	"pump",
	"storage-tank",
}
---@type table<string,string>
local matching_items = {}
for _, key in pairs(handled) do
	matching_items[key:gsub("-","%%-").."$"] = key
end

---@type table<string,string|false>
local root_items = {}
---@param given_item string
---@return string|false
function library.get_root_item(given_item)
	-- Get cached
	if root_items[given_item] ~= nil then
		return root_items[given_item]
	end

	-- Process
	for match, root_item in pairs(matching_items) do
		if given_item:match(match) then
			root_items[given_item] = root_item
			return root_item
		end
	end

	-- No item found
	root_items[given_item] = false
	return false
end

---@param stack LuaItemStack?
---@return boolean valid
function library.valid_stack(stack)
	return stack and stack.valid and stack.valid_for_read or false
end

return library