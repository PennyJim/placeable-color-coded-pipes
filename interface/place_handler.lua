---@type event_handler
local place_handler = {events = {}}
local events = place_handler.events

local colorable_entities = {
	["entity-ghost"] = true,
	["pipe"] = true,
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


return place_handler