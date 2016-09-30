
local get_item_group = minetest.get_item_group

local multiblock = {}

-- Returns a different number of values depending on the type.
--   For simple matches ("nodename"), returns "simple" as the first value, and
--   the node name as the second (may be blank or a group)
--
--   For normal captures ("capturename?nodename"), returns "capture" as the first
--   value, the node name, then the capture name (may be blank)
--
--   For strict captures ("capturename!nodename") returns "strict" as the first
--   value, the node name, then the capture name (not blank)
--
--   If invalid, returns nil.
local function parse_node_pattern(node_pattern)
	-- Simple
	if node_pattern:find("^[^!%?]*$") then
		return "simple", node_pattern
	end

	-- Normal capture
	local _, _, cap_name, node_name = node_pattern:find("^([^!%?]*)%?([^!%?]*)$")
	if cap_name then
		return "capture", node_name, cap_name
	end

	-- Strict capture
	local _, _, cap_name, node_name = node_pattern:find("^([^!%?]+)!([^!%?]*)$")
	if cap_name then
		return "strict", node_name, cap_name
	end

	error("Bad node pattern: " .. node_pattern)
end


-- Returns a boolean, stating whether the node name is equal to the other node
-- name (or in the group, if the other name is a group)
local function node_is_or_in_group(node_or_group, node_name)
	local _, _, group_name = node_or_group:find("^group:(.+)")
	if not group_name then
		return node_or_group == node_name or node_or_group == ""
	else
		local group_val = get_item_group(node_name, group_name)
		return group_val ~= 0
	end
end


-- Matches a single node. If failed, returns false. If succeeded, returns
-- true and possibly two more values. If it is a simple match, no extra
-- values are provided. Otherwise a capture name is also returned.
--
-- The third argument is a table from the names of already-matched strict
-- captures to node names. If this is the first match for a strict capture, it
-- will modify the map to include the new node name.
local function match_node(node_pattern, node_name, strict_map)
	local pat_type, node_or_group, cap_name = parse_node_pattern(node_pattern)
	if not node_is_or_in_group(node_or_group, node_name) then
		return false
	end

	if pat_type == "simple" then
		return true
	end

	-- Else, we have a possible capture
	if pat_type == "capture" then
		return true, cap_name
	end

	-- Strict capture
	if pat_type == "strict" then
		local existing = strict_map[cap_name]
		if not existing then
			strict_map[cap_name] = node_name
			return true, cap_name
		elseif existing == node_name then
			return true, cap_name
		else
			return false
		end
	end

	-- Invalid pattern
	error("Invalid node pattern: " .. node_pattern)
end


-- Attempts to match a given pattern, placing the center of the pattern at
-- the given center, which is a position vector. Returns nil on failure and
-- a capture table on success.
function multiblock.match(pattern, center)
	local pat_center = pattern.center
	local size = pattern.size
	local min_p = vector.add(vector.subtract(center, pat_center), {x=1,y=1,z=1})
	local max_p = vector.subtract(vector.add(min_p, size), {x=1,y=1,z=1})

	local flipped_size = {x = size.x, y = size.z, z = size.y}
	local flipped_max = vector.subtract(flipped_size, {x=1,y=1,z=1})
	local flipped_va = VoxelArea:new{MinEdge = {x=0, y=0, z=0}, MaxEdge = flipped_max}

	local vm = VoxelManip(min_p, max_p)
	
	local strict_map = {}
	local data = pattern.pattern
	local captures = {}

	for i, node_pattern in ipairs(data) do
		local flipped_pos = flipped_va:position(i)
		local rel_pos = {x=flipped_pos.x, y=flipped_pos.z, z=flipped_pos.y}
		local pos = vector.add(rel_pos, min_p)
		local node = vm:get_node_at(pos)

		-- Patterns are formatted as rows of x in squares of z in a cube
		-- of y

		local succ, cap_name = match_node(node_pattern, node.name, strict_map)
		if not succ then return nil end

		if cap_name then
			local cap_array = captures[cap_name]
			if not cap_array then
				cap_array = {}
				captures[cap_name] = cap_array
			end

			node.pos = pos
			table.insert(cap_array, node)
		end
	end

	return captures
end


return multiblock
