local event_handler = require("event_handler") --[[@as event_handler_lib]]

event_handler.add_libraries{
	require("__gui-modules__.gui"),
	require("interface.selector"),
	require("interface.cursor_handler"),
	require("compatibility.automatic-underground-pipe-connectors")
}