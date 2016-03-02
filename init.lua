
local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

multiblock = dofile(modpath .. "multiblock.lua")

if minetest.get_modpath("default") then
	dofile(modpath .. "test.lua")
end
