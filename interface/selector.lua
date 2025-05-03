local gui = require("__gui-modules__.gui")
local lib = require("__placeable-color-coded-pipes__/library")

---@class WindowState.color_selector : modules.WindowState
---@field visible boolean
---@field selected LuaGuiElement
---@field item string?
---@field cur_item string?

---@param color string
---@return modules.GuiElemDef
local function create_button(color)
	return {
		args = {
			type="sprite-button",
			style = "color_coded_button",
			tags={color=color},
			sprite = "item/"..color.."-color-coded-pipe",
		},
		handler = "selector"
	}
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
					children = {
						create_button("red"),
						create_button("orange"),
						create_button("yellow"),
						create_button("green"),
						create_button("blue"),
						create_button("purple"),
						create_button("pink"),
						create_button("black"),
						create_button("white"),
					}
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

    for _, fluid in pairs(prototypes.fluid) do
			local prototype_name = fluid.name .. "-color-coded-pipe"
			if prototypes.entity[prototype_name] then
				table.insert(fluids, create_button(fluid.name))
			end
		end

		if not state.selected or not state.selected.valid then
			local default_color = state.elems.default_color
			default_color.toggled = true
			state.selected = default_color
		end

		state.gui.add(script.mod_name, fluid_table, fluids)
		state.visible = false
		state.root.visible = false
		state.elems.default.children[2].enabled = false
	end,
	handlers = {
		["selector"] = function (state, elem)
			if state.selected == elem then return end

			state.selected.toggled = false
			elem.toggled = true
			state.selected = elem
			if elem.name ~= "default_color"
			and elem.name ~= "dynamic_toggle" then
				state.cur_item = elem.tags.color.."-color-coded-"..state.item
			else
				state.cur_item = state.item
			end

			local cursor_stack = state.player.cursor_stack
			if lib.valid_stack(cursor_stack) then
				---@cast cursor_stack -?
				cursor_stack.set_stack{
					name = state.cur_item,
					count = cursor_stack.count,
					health = cursor_stack.health
				}
			else
				state.player.cursor_ghost = state.cur_item
			end
		end
	} --[[@as table<any, fun(state:WindowState.color_selector,elem:LuaGuiElement,event:EventData.GuiEvents)>]]
} --[[@as newWindowParams]]

return {}