local gui = require("__gui-modules__.gui")

---@param color string
---@return GuiElemModuleDef
local function create_button(color)
	return {
		type="sprite-button",
		tags={color=color},
		sprite = "item/"..color.."-pipe"
	}
end

gui.new{
	window_def = {
		namespace = "pipe-placer",
		root = "left",
		version = 1,
		definition = {
			type = "frame", direction = "vertical",
			caption = {"pipe-placer.title"},
			children = {
				{type = "label", caption = {"pipe-placer.default"}},
				{
					type = "table", name = "default",
					column_count = 9,
					children = {
						{type="sprite-button", sprite="item/pipe"},
						{type="sprite-button", sprite="item/pipe"},
					}
				},
				{type = "label", caption = {"pipe-placer.colors"}},
				{
					type = "table", name = "colors",
					column_count = 9,
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
					column_count = 9,
					children = {}
				}
			}
		}
	},
	state_setup = function (state)
		local fluid_table = state.elems.fluids
		if not fluid_table.valid then
			error("Elems in global have become invalid somehow")
			return
		end

		fluid_table.clear()
		local fluids = {}

    for _, fluid in pairs(game.fluid_prototypes) do
			local prototype_name = fluid.name .. "-pipe"
			if game.entity_prototypes[prototype_name] then
					table.insert(fluids, create_button(fluid.name))
			end
		end

		state.gui.add("pipe-placer", fluid_table, fluids, true)
		state.root.visible = true
	end
} --[[@as newWindowParams]]

return {}