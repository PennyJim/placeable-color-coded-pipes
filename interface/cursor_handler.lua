---@type event_handler
local cursor_handler = {events = {}}
---@cast cursor_handler.events -?
local events = cursor_handler.events
local gui = require("__gui-modules__.gui")
local lib = require("library")
local Selector = require("interface.selector")

---@param state WindowState.color_selector
local function restore_cursor_items(state)
	if not state.need_restoration then return end
	---@cast state WindowState.color_selector.item
	if state.item_count <= 0 then return end

	local player = state.player
	local cursor_stack = player.cursor_stack
	if not cursor_stack then return end
	local cursor_valid = lib.valid_stack(cursor_stack)
	local inv = player.get_main_inventory()
	---@cast inv -?

	local inserted = inv.insert{
		name = lib.get_refill_item(state.cur_item),
		count = state.item_count,
		quality = state.quality,
	}

	-- Something obstructing the cursor. Put it back
	-- Also borrowed from Actual Underground Pipes (tomwub)
	if inserted ~= state.item_count then
		state.item_count = state.item_count - inserted

		-- Done conditionally so it doesn't notify the player for no reason
		if cursor_valid and player.can_insert{
			name = cursor_stack.name,
			count = cursor_stack.count,
			quality = cursor_stack.quality.name,
		} then
			player.clear_cursor()
		end

		cursor_stack.set_stack{
			name = state.cur_item,
			count = state.item_count,
			quality = state.quality,
		}
	end
end

---@param state WindowState.color_selector
local function color_cleared(state)
	restore_cursor_items(state)
	state.cur_item = nil
	state.quality = nil
	state.item = nil
	state.item_count = nil
	state.need_restoration = nil
	state.visible = false
	state.root.visible = false
end

--MARK: Interface updation
---@param state WindowState.color_selector
---@param item string
---@param color? string
local function update_item(state, item, quality, color)
	state.item = item
	state.quality = quality
	Selector.update_items(state, item)

	local has_set = false
	if color then
		has_set = Selector.select_color(state, color)
	end

	if not has_set then
		Selector.set_item(state, item)
	end

	if not state.visible then
		-- Add window
		state.visible = true
		state.root.visible = true
	end
end

---@param state WindowState.color_selector.item
local function refill_cursor(state)
	local player = state.player
	---@cast player.cursor_ghost -?
	---@cast player.cursor_stack -?
	local inv = player.get_main_inventory()
	---@cast inv -?
	
	---@cast inv.index -?
	local refill_item = lib.get_refill_item(state.cur_item)
	local stack, stack_index = inv.find_item_stack{
		name = refill_item,
		quality = player.cursor_ghost.quality,
	}
	if not stack then
		state.item_count = 0
		return
	end ---@cast stack_index -?

	lib.set_item_name(stack, state.cur_item)
	state.item_count = stack.count
	player.cursor_stack.transfer_stack(stack)
	player.hand_location = {
		inventory = inv.index,
		slot = stack_index,
	}
end

--MARK: Cursor changed
events[defines.events.on_player_cursor_stack_changed] = function (event)
	---@type WindowState.color_selector
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	local player = state.player

	local cursor_stack = player.cursor_stack
	local cursor_ghost = player.cursor_ghost --[[@as ItemIDAndQualityIDPair]]
	local cursor_valid = lib.valid_stack(cursor_stack)
	---@cast cursor_ghost.quality LuaQualityPrototype
	
	if not cursor_valid and not cursor_ghost then
		if state.visible then
			color_cleared(state)
		end
		return
	end

	---@type string
	local stack_name
	---@type data.QualityID
	local stack_quality
	if not cursor_valid then
		stack_name = cursor_ghost.name--[[@as LuaItemPrototype]].name
		stack_quality = cursor_ghost.quality.name
	else
		---@cast cursor_stack -?
		stack_name = cursor_stack.name
		stack_quality = cursor_stack.quality.name
	end

	local base_name = lib.get_root_item(stack_name)
	-- Not an item we care to act on
	if not base_name then return end

	---@type uint
	local item_count
	---@type true?
	local need_restoration
	if state.item_count == -1 then
		refill_cursor(state)
		return
	elseif cursor_valid then
		---@cast cursor_stack -?
		item_count = cursor_stack.count
		need_restoration = cursor_stack.prototype.flags["only-in-cursor"]
	else
		item_count = 0
	end

	-- Already was selected
	if state.cur_item == stack_name then
		if state.quality ~= stack_quality then
			restore_cursor_items(state)
			state.quality = stack_quality
		end
		state.item_count = item_count
		state.need_restoration = need_restoration
		return
	end

	---HACK: hard-coded fix for Actual Underground Pipes
	if state.cur_item and not ({
		["tomwub-"..stack_name] = true,
		[stack_name:sub(8)] = true,
	})[state.cur_item] then
		restore_cursor_items(state)
	end
	state.item_count = item_count
	state.need_restoration = need_restoration

	update_item(state, base_name, stack_quality)
end

---MARK: Accessory Events

events[defines.events.on_player_pipette] = function (event)
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	local selected = state.player.selected
	if not selected then return log("How did the player pipette without selecting the entity??") end

	local root, color = lib.get_root_item(selected.name)
	if not root then return end

	update_item(state, root, selected.quality, color)
end

events[defines.events.on_built_entity] = function (event)
	---@type WindowState.color_selector
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	if not state.visible then return end
	if not state.item_count or state.item_count == 0 then return end -- Might be able to rely on count existing if its visible
	---@cast state WindowState.color_selector.item
	local player = state.player
	---@cast player.cursor_ghost -?

	---@cast player.cursor_ghost.name LuaItemPrototype

	if player.is_cursor_empty() then
		---@type ItemIDAndQualityIDPair
		player.cursor_ghost = {
			name = state.cur_item,
			quality = event.entity.quality
		}
		state.item_count = -1
	elseif player.cursor_ghost and player.cursor_ghost.name.name == state.cur_item then
		state.item_count = -1
	end
end

---MARK: Cycling

---@param state WindowState.color_selector
---@param change int
local function cycle(state, change)
	local name = state.selected.name

	local index = lib.color_indexies[name]
	local array = lib.colors
	if not index then
		index = lib.fluid_indexies[name]
		array = lib.fluids
	end
	if not index then return end

	local size = #array
	index = (index + change) % size
	if index == 0 then
		index = size
	end

	Selector.select_color(state, array[index]--[[@cast -?]])
end

---@param event EventData.CustomInputEvent
events[script.get_event_id("color-coded-linked-cycle-blueprint-forwards")] = function (event)
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	if not state.visible then return end
	cycle(state, 1)
end
---@param event EventData.CustomInputEvent
events[script.get_event_id("color-coded-linked-cycle-blueprint-backwards")] = function (event)
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	if not state.visible then return end
	cycle(state, -1)
end

return cursor_handler