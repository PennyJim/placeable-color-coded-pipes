local gui = require("__gui-modules__.gui")
local lib = require("__placeable-color-coded-pipes__/library")

---@class WindowState.color_selector : modules.WindowState
---@field visible boolean
---@field selected LuaGuiElement
---@field rendered_item string
---@field item string?
---@field cur_item string?

---@param color string
---@return modules.GuiElemDef
local function create_button(color)
	return {
		args = {
			name = color,
			type="sprite-button",
			style = "color_coded_button",
			tags={color=color},
			sprite = "item/"..color.."-color-coded-pipe",
		},
		handler = "selector"
	}
end

---@param state WindowState.color_selector
---@param base_item string
function set_item(state, base_item)
	local selected = state.selected
	---@type string
	local new_item
	if selected.name == "default_color" then
		new_item = base_item
	elseif selected.name == "dynamic_toggle" then
		-- Choose the proper color somehow?
	else
		new_item = selected.tags.color.."-color-coded-"..base_item
	end

	state.cur_item = new_item
	lib.set_cursor_name(state.player, new_item)
end

---@param state WindowState.color_selector
---@param elem LuaGuiElement
---@return boolean did_set
local function set_color(state, elem)
	if state.selected == elem then return false end

	-- Swap the element toggled
	state.selected.toggled = false
	elem.toggled = true
	state.selected = elem

	if state.item then
		set_item(state, state.item)
		return true
	else
		return false
	end
end

---@type modules.GuiElemDef[]
local color_buttons = {}
for index, color in pairs(lib.colors) do
	color_buttons[index] = create_button(color)
end

gui.new{
	window_def = {
		namespace = script.mod_name,
		root = "left",
		version = 1,
		definition = {
			args = {
				type = "frame", direction = "vertical",
				caption = {"pipe-placer.title"},
			},
			children = {
				{args = {type = "label", caption = {"pipe-placer.default"}}},
				{
					args = {
						type = "table", name = "default",
						column_count = 6, style = "color_coded_pipes_table",
					},
					children = {
						{
							args = {
								type="sprite-button",
								name = "default_color",
								style = "color_coded_button",
								sprite="item/pipe",
							},
							handler = "selector"
						},
						{
							args = {
								type="sprite-button",
								name = "dynamic_toggle",
								style = "color_coded_button",
								sprite="item/pipe",
							},
							handler = "selector"
						},
					}
				},
				{args = {type = "label", caption = {"pipe-placer.colors"}}},
				{
					args = {
						type = "table", name = "colors",
						column_count = 6, style = "color_coded_pipes_table",
					},
					children = color_buttons
				},
				{args = {type = "label", caption = {"pipe-placer.fluids"}}},
				{
					args = {
						type = "table", name = "fluids",
						column_count = 6, style = "color_coded_pipes_table",
					},
					children = {}
				}
			}
		}
	},
	---@param state WindowState.color_selector
	state_setup = function (state)
		local fluid_table = state.elems.fluids
		if not fluid_table.valid then
			error("Elems in global have become invalid somehow")
			return
		end

		fluid_table.clear()
		---@type modules.GuiElemDef[]
		local fluids = {}
    for index, fluid in pairs(lib.fluids) do
			fluids[index] = create_button(fluid)
		end

		if not state.selected or not state.selected.valid then
			local default_color = state.elems.default_color
			default_color.toggled = true
			state.selected = default_color
		end

		state.gui.add(script.mod_name, fluid_table, fluids)
		state.visible = false
		state.root.visible = false
		state.rendered_item = state.rendered_item or "pipe"
		state.elems["dynamic_toggle"].enabled = false
	end,
	handlers = {
		["selector"] = function(state, elem) set_color(state, elem) end -- To mask the returns
	} --[[@as table<any, fun(state:WindowState.color_selector,elem:LuaGuiElement,event:EventData.GuiEvents)>]]
} --[[@as newWindowParams]]

local Selector = {}

---@param state WindowState.color_selector
---@param item string
function Selector.update_sprites(state, item)
	if state.rendered_item == item then return end
	state.rendered_item = item

	local elems = state.elems

	elems.default_color.sprite = "item/" .. item
	elems.dynamic_toggle.sprite = "item/" .. item

	for _, elem in pairs(elems) do
		local tags = elem.tags
		if tags.color then
			elem.sprite = "item/".. tags.color .. "-color-coded-" .. item
		end
	end
end

---@param state WindowState.color_selector
---@param color string
---@return boolean did_set
function Selector.select_color(state, color)
	local elem = state.elems[color]
	if not elem then error("Invalid color: "..color) end

	return set_color(state, elem)
end

Selector.set_item = set_item

return Selector