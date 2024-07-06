local styles = data.raw["gui-style"]["default"]
-- *Directly* Inspired from textplates
styles.color_coded_pipes_table = {
	type = "table_style",
	cell_spacing = 1,
	horizontal_spacing = 1,
	vertical_spacing = 1,
}
styles.color_coded_button = {
	type = "button_style",
	parent = "button",
	minimal_width = 40,
	minimal_height = 40,
	padding = 0
}