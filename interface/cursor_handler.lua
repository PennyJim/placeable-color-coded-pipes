---@type event_handler
local cursor_handler = {events = {}}
local events = cursor_handler.events
local gui = require("__gui-modules__.gui")
local lib = require("library")
local Selector = require("interface.selector")

---@param state WindowState.color_selector
---@param inventory LuaInventory
---@return boolean did_clear
local function clear_colored_from_inventory(state, inventory)
	-- Fetch the stack of the cleared item
	local old_item = inventory.find_item_stack(state.cur_item)
	-- Check if it exists
	if not lib.valid_stack(old_item) then return false end

	-- Uncolor it if it does
	---@cast old_item -?
	lib.set_item_name(old_item, state.item)

	return true
end

local transport = {
	["transport-belt"] = true,
	["underground-belt"] = true,
	["splitter"] = true,
	["loader"] = true,
	["loader-1x1"] = true,
	["linked-belt"] = true,
	["lane-splitter"] = true,
}

---@param state WindowState.color_selector
---@param entity LuaEntity|LuaPlayer
local function clear_colored_from_entity(state, entity)
	local entity_type = entity.object_name == "LuaEntity" and entity.type or false

	if transport[entity_type] then
		-- Process a transport belt
		for i = 1, entity.get_max_transport_line_index() do
			local line = entity.get_transport_line(i)
			if line and line.get_item_count(state.cur_item) > 0 then
				for i = 1, #line do
					local stack = line[i]
					if stack.name == state.cur_item then
						lib.set_item_name(line[i], state.item)
					end
				end
			end
		end


	else
		-- Process the inventories
		for i = 1, entity.get_max_inventory_index() do
			---@diagnostic disable-next-line: param-type-mismatch
			local inventory = entity.get_inventory(i)
			if inventory then
				clear_colored_from_inventory(state, inventory)
			end
		end
	end
end

---@param state WindowState.color_selector
---@param player LuaPlayer
local function clear_player_colored(state, player)
	local selected = player.selected
	if not selected then goto notselected end
	-- We must have just placed it
	if selected.name == state.cur_item then goto notselected end -- Make this a return for that reason?
	clear_colored_from_entity(state, selected)

	::notselected::

	local opened = player.opened
	if not opened then goto notopened end
	if type(opened) ~= "userdata" then goto notopened end
	if opened.object_name ~= "LuaEntity" then goto notopened end
	clear_colored_from_entity(state, opened)

	::notopened::

	clear_colored_from_entity(state, player)
end

---@param state WindowState.color_selector
local function color_cleared(state)
	local player = state.player
	local inv = player.get_main_inventory()

	if inv and not clear_colored_from_inventory(state, inv) then

		-- Didn't clear from inventory, restock the cursor.
		local more_items = inv.find_item_stack(state.item)
		if lib.valid_stack(more_items) then
			---@cast more_items -?
			if player.cursor_stack.transfer_stack(more_items) then
				lib.set_item_name(player.cursor_stack, state.cur_item)
			end
		end
	end

	clear_player_colored(state, player)

	state.cur_item = nil
	state.item = nil
	state.visible = false
	state.root.visible = false
end

-- --MARK: Fast transfer
-- events[defines.events.on_player_fast_transferred] = function (event)
-- 	if not event.from_player then return end

-- 	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
-- 	if not state.cur_item then return end

-- 	clear_colored_from_entity(state, event.entity)
-- end
--MARK: Dropped item
events[defines.events.on_player_dropped_item] = function (event)
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	if not state.cur_item then return end

	local stack = event.entity.stack
	if stack.name == state.cur_item then
		lib.set_item_name(stack, state.item)
	end
end

--MARK: Cursor changed
events[defines.events.on_player_cursor_stack_changed] = function (event)
	---@type WindowState.color_selector
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	local player = state.player

	local cursor_stack = player.cursor_stack
	local cursor_ghost = player.cursor_ghost --[[@as LuaItemPrototype]]
	local cursor_valid = lib.valid_stack(cursor_stack)

	if not cursor_valid and not cursor_ghost then
		if state.visible then
			color_cleared(state)
		end
		return
	end

	-- MARK: Remove item transfers
	if state.cur_item then
		clear_player_colored(state, player)
	end

	---@type string
	local stack_name
	if not cursor_valid then
		stack_name = cursor_ghost.name--[[@as LuaItemPrototype]].name
	else
		---@cast cursor_stack -?
		stack_name = cursor_stack.name
	end

	---@type string|false
	local base_name = lib.get_root_item(stack_name)
	if state.item == base_name then return end

	-- Clear the inventory of the old item
	-- For they might have just picked up a different one
	if state.visible then
		color_cleared(state)
	end

	-- Not an item we care to act on
	if not base_name then return end

	state.item = base_name
	Selector.update_sprites(state, base_name)

	local selected = state.selected
	---@type string
	local new_item
	if selected.name == "default_color" then
		new_item = base_name
	elseif selected.name == "dynamic_toggle" then
		-- Choose the proper color somehow?
	else
		new_item = selected.tags.color.."-color-coded-"..base_name
	end
	state.cur_item = new_item

	if not cursor_valid then
		player.cursor_ghost = new_item
	else
		---@cast cursor_stack -?
		lib.set_item_name(cursor_stack, new_item)
	end

	if not state.visible then
		-- Add window
		state.visible = true
		state.root.visible = true
	end
end

return cursor_handler