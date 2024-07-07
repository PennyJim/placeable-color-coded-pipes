---@type event_handler
local place_handler = {events = {}}
local events = place_handler.events

local colorable_entities = {
	["entity-ghost"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true,
	["pump"] = true,
	["storage-tank"] = true,
}

events[defines.events.on_built_entity] = function (event)
	local entity = event.created_entity
	local name = entity.name
	if not colorable_entities[name] then return end
	if name == "entity-ghost" and not colorable_entities[entity.ghost_name] then return	end
	---@type WindowState.color_selector
	local state = global[script.mod_name][event.player_index]

	local color_button = state.selected
	if color_button.name == "default_color" then return end
	local color = color_button.tags.color

	if name == "entity-ghost" then
		local surface = entity.surface
		local position = entity.position
		local direction = entity.direction
		local force = entity.force
		local ttl = entity.time_to_live
		name = entity.ghost_name
		entity.destroy{raise_destroy = false}
		
		local new_entity = surface.create_entity{
			name = "entity-ghost",
			inner_name = color.."-"..name,
			position = position,
			direction = direction,
			force = force,
			player = state.player,
			expires = false
		}
		if new_entity then
			new_entity.time_to_live = ttl
		end

	else
		--MARK: Place Colored Entity
		local new_entity = entity.surface.create_entity{
			name = color.."-"..name,
			position = entity.position,
			direction = entity.direction,
			force = entity.force,
			fast_replace = true,
			spill = false,
			fluidbox = entity.fluidbox, -- Necessary for on_built?
		}
		if new_entity then
			new_entity.last_user = state.player
		end
	end
end

---@param stack LuaItemStack?
---@return boolean valid
local function valid_stack(stack)
	return stack and stack.valid and stack.valid_for_read or false
end

events[defines.events.on_player_cursor_stack_changed] = function (event)
	---@type WindowState.color_selector
	local state = global[script.mod_name][event.player_index]
	local player = state.player
	local cursor_stack = player.cursor_stack
	local cursor_ghost = player.cursor_ghost --[[@as LuaItemPrototype]]
	local cursor_valid = valid_stack(cursor_stack)

	if not cursor_valid and not cursor_ghost then
		if state.visible then
			state.item = nil
			state.visible = false
			state.root.visible = false
		end
		return
	end

	---@type string
	local name
	if not cursor_valid then
		-- remove color prefix if it exists
		local ghost_name = cursor_ghost.name
		if not colorable_entities[ghost_name] then
			for item in pairs(colorable_entities) do
				if ghost_name:match(item.."$") then
					name = item
				end
			end
			if not name then
				if state.visible then
					state.item = nil
					state.visible = false
					state.root.visible = false
				end
				return
			end
		else
			name = ghost_name
		end
	else
		---@cast cursor_stack LuaItemStack
		name = cursor_stack.name
	end

	if not colorable_entities[name] then
		-- Remove window
		if state.visible then
			state.item = nil
			state.visible = false
			state.root.visible = false
		end
		return
	end

	if state.item == name then return end
	state.item = name

	local selected = state.selected
	if selected.name ~= "default_color" then
		if selected.name == "dynamic_toggle" then
			-- Choose the proper color somehow?
		else
			player.cursor_ghost = selected.tags.color.."-"..name
		end
	end

	if not state.visible then
		-- Add window
		state.visible = true
		state.root.visible = true
	end
end

return place_handler