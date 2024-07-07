local gui = require("__gui-modules__.gui")

---@class WindowState.color_selector : WindowState
---@field visible boolean
---@field selected LuaGuiElement

---@param color string
---@return GuiElemModuleDef
local function create_button(color)
	return {
		type="sprite-button",
		style = "color_coded_button",
		tags={color=color},
		sprite = "item/"..color.."-pipe",
		handler = "selector"
	}
end

gui.new{
	window_def = {
		namespace = script.mod_name,
		root = "left",
		version = 1,
		definition = {
			type = "frame", direction = "vertical",
			caption = {"pipe-placer.title"},
			children = {
				{type = "label", caption = {"pipe-placer.default"}},
				{
					type = "table", name = "default",
					column_count = 6, style = "color_coded_pipes_table",
					children = {
						{
							type="sprite-button",
							name = "default_color",
							style = "color_coded_button",
							sprite="item/pipe",
							handler = "selector"
						},
						{
							type="sprite-button",
							name = "dynamic_toggle",
							style = "color_coded_button",
							sprite="item/pipe",
							handler = "selector"
						},
					}
				},
				{type = "label", caption = {"pipe-placer.colors"}},
				{
					type = "table", name = "colors",
					column_count = 6, style = "color_coded_pipes_table",
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
				{type = "label", caption = {"pipe-placer.fluids"}},
				{
					type = "table", name = "fluids",
					column_count = 6, style = "color_coded_pipes_table",
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
		---@type GuiElemModuleDef[]
		local fluids = {}

    for _, fluid in pairs(game.fluid_prototypes) do
			local prototype_name = fluid.name .. "-pipe"
			if game.entity_prototypes[prototype_name] then
					table.insert(fluids, create_button(fluid.name))
			end
		end

		if not state.selected or not state.selected.valid then
			local default_color = state.elems.default_color
			default_color.toggled = true
			state.selected = default_color
		end

		state.gui.add(script.mod_name, fluid_table, fluids, true)
		state.visible = false
		state.root.visible = false
	end,
	handlers = {
		["selector"] = function (state, elem)
			if state.selected == elem then return end

			state.selected.toggled = false
			elem.toggled = true
			state.selected = elem
		end
	} --[[@as table<any, fun(state:WindowState.color_selector,elem:LuaGuiElement,event:GuiEventData)>]]
} --[[@as newWindowParams]]

return {}