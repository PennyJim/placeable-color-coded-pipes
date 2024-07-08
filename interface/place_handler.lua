---@type event_handler
local place_handler = {events = {}}
local events = place_handler.events
local gui = require("__gui-modules__.gui")
local lib = require("__placeable-color-coded-pipes__/library")

events[defines.events.on_player_cursor_stack_changed] = function (event)
	---@type WindowState.color_selector
	local state = gui.get_state(script.mod_name, event.player_index) --[[@as WindowState.color_selector]]
	local player = state.player

	local cursor_stack = player.cursor_stack
	local cursor_ghost = player.cursor_ghost --[[@as LuaItemPrototype]]
	local cursor_valid = lib.valid_stack(cursor_stack)

	if not cursor_valid and not cursor_ghost then
		if state.visible then
			local inv = player.get_main_inventory()
			if inv then -- FIXME: Doesn't clean items dropped or stashed into inventories
				local old_item = inv.find_item_stack(state.cur_item)
				if lib.valid_stack(old_item) then
					---@cast old_item -?
					old_item.set_stack{
						name = state.item,
						count = old_item.count,
						health = old_item.health
					}
				end
			end

			state.cur_item = nil
			state.item = nil
			state.visible = false
			state.root.visible = false
		end
		return
	end

	---@type string|false
	local name
	if not cursor_valid then
		name = lib.get_root_item(cursor_ghost.name)
	else
		---@cast cursor_stack -?
		name = lib.get_root_item(cursor_stack.name)
	end

	if state.item == name then return end
	if not name then
		-- Remove window
		if state.visible then
			state.item = nil
			state.visible = false
			state.root.visible = false
		end
		return
	end

	state.item = name

	local selected = state.selected
	---@type string
	local new_item
	if selected.name == "default_color" then
		new_item = name
	elseif selected.name == "dynamic_toggle" then
		-- Choose the proper color somehow?
	else
		new_item = selected.tags.color.."-"..name
	end
	state.cur_item = new_item

	if not cursor_valid then
		player.cursor_ghost = new_item
	else
		---@cast cursor_stack -?
		cursor_stack.set_stack{
			name = new_item,
			count = cursor_stack.count,
			health = cursor_stack.health
		}
	end

	if not state.visible then
		-- Add window
		state.visible = true
		state.root.visible = true
	end
end

return place_handler