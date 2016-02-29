
local pattern = {
	size = {x=5, y=2, z=5},
	center = {x=3, y=2, z=3},
	pattern = {
		"default:cobble", "default:cobble", "default:cobble", "default:cobble", "default:cobble",
		"default:cobble", "default:cobble", "default:cobble", "default:cobble", "default:cobble",
		"default:cobble", "default:cobble", "default:cobble", "default:cobble", "default:cobble",
		"default:cobble", "default:cobble", "default:cobble", "default:cobble", "default:cobble",
		"default:cobble", "default:cobble", "default:cobble", "default:cobble", "default:cobble",

		"?air", "?air", "?air", "?air", "?air",
		"?air", "mat!", "mat!", "mat!", "?air",
		"?air", "mat!", "multiblock:test_core", "mat!", "?air",
		"?air", "mat!", "mat!", "mat!", "?air",
		"?air", "?air", "?air", "?air", "?air",
	},
}
		

minetest.register_node("multiblock:test_core", {
	description = "Test Core",
	tiles = {"default_cactus_top.png", "default_cactus_top.png", "default_cactus_side.png"},
	groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local captures = multiblock.match(pattern, pos)
		if not captures then
			minetest.chat_send_player(clicker:get_player_name(), "Match failed.")
			return
		end

		local mat = captures.mat[1]

		for i, capture in ipairs(captures[""]) do
			minetest.place_node(capture.pos, mat)
		end
	end,
})
