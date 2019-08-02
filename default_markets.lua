local default_modpath = minetest.get_modpath("default")
if not default_modpath then return end

local gold_coins_required = false

local default_items = {"default:axe_bronze","default:axe_diamond","default:axe_mese","default:axe_steel","default:axe_steel","default:axe_stone","default:axe_wood","default:pick_bronze","default:pick_diamond","default:pick_mese","default:pick_steel","default:pick_stone","default:pick_wood","default:shovel_bronze","default:shovel_diamond","default:shovel_mese","default:shovel_steel","default:shovel_stone","default:shovel_wood","default:sword_bronze","default:sword_diamond","default:sword_mese","default:sword_steel","default:sword_stone","default:sword_wood", "default:blueberries", "default:book", "default:bronze_ingot", "default:clay_brick", "default:clay_lump", "default:coal_lump", "default:copper_ingot", "default:copper_lump", "default:diamond", "default:flint", "default:gold_ingot", "default:gold_lump", "default:iron_lump", "default:mese_crystal", "default:mese_crystal_fragment", "default:obsidian_shard", "default:paper", "default:steel_ingot", "default:stick", "default:tin_ingot", "default:tin_lump", "default:acacia_tree", "default:acacia_wood", "default:apple", "default:aspen_tree", "default:aspen_wood", "default:blueberry_bush_sapling", "default:bookshelf", "default:brick", "default:bronzeblock", "default:bush_sapling", "default:cactus", "default:clay", "default:coalblock", "default:cobble", "default:copperblock", "default:desert_cobble", "default:desert_sand", "default:desert_sandstone", "default:desert_sandstone_block", "default:desert_sandstone_brick", "default:desert_stone", "default:desert_stone_block", "default:desert_stonebrick", "default:diamondblock", "default:dirt", "default:glass", "default:goldblock", "default:gravel", "default:ice", "default:junglegrass", "default:junglesapling", "default:jungletree", "default:junglewood", "default:ladder_steel", "default:ladder_wood", "default:large_cactus_seedling", "default:mese", "default:mese_post_light", "default:meselamp", "default:mossycobble", "default:obsidian", "default:obsidian_block", "default:obsidian_glass", "default:obsidianbrick", "default:papyrus", "default:pine_sapling", "default:pine_tree", "default:pine_wood", "default:sand", "default:sandstone", "default:sandstone_block", "default:sandstonebrick", "default:sapling", "default:silver_sand", "default:silver_sandstone", "default:silver_sandstone_block", "default:silver_sandstone_brick", "default:snow", "default:snowblock", "default:steelblock", "default:stone", "default:stone_block", "default:stonebrick", "default:tinblock", "default:tree", "default:wood",}

------------------------------------------------------------------------------
-- King's Market

if minetest.settings:get_bool("commoditymarket_enable_kings_market") then
local kings_def = {
	description = "King's Market",
	long_description = "The largest and most accessible market for the common man, the King's Market uses gold coins as its medium of exchange (or the equivalent in gold ingots - 1000 coins to the ingot). However, as a respectable institution of the surface world, the King's Market operates only during the hours of daylight. The purchase and sale of swords and explosives is prohibited in the King's Market. Gold coins are represented by a '☼' symbol.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "☼", -- "\u{263C}" Alchemical symbol for gold
	allow_item = function(item)
		if item:sub(1,13) == "default:sword" or item:sub(1,4) == "tnt:" then
			return false
		end
		return true
	end,
	inventory_limit = 100000,
	--sell_limit =, -- no sell limit for the King's Market
	initial_items = default_items,
}

gold_coins_required = true

commoditymarket.register_market("kings", kings_def)

minetest.register_node("commoditymarket:kings_market", {
	description = "King's Market",
	_doc_items_longdesc = "",
	tiles = {"default_chest_top.png","default_chest_top.png",
		"default_chest_side.png","default_chest_side.png",
		"commoditymarket_empty_shelf.png","default_chest_side.png^commoditymarket_crown.png",},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local timeofday =  minetest.get_timeofday()
		if timeofday > 0.2 and timeofday < 0.8 then
			commoditymarket.show_market("kings", clicker:get_player_name())
		else
			minetest.chat_send_player(clicker:get_player_name(), "At this time of day the King's Market is closed.")
		end
	end,
})
end
-------------------------------------------------------------------------------
-- Night Market

if minetest.settings:get_bool("commoditymarket_enable_night_market") then
local night_def = {
	description = "Night Market",
	long_description = "When the sun sets and the stalls of the King's Market close, other vendors are just waking up to share their wares. The Night Market is not as voluminous as the King's Market but accepts a wider range of wares. It accepts the same gold coinage of the realm, one thousand coins to the gold ingot.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "☼", --"\u{263C}"
	inventory_limit = 10000,
	--sell_limit =, -- no sell limit for the Night Market
	initial_items = default_items,
}

gold_coins_required = true

commoditymarket.register_market("night", night_def)

minetest.register_node("commoditymarket:night_market", {
	description = night_def.description,
	_doc_items_longdesc = night_def.long_description,
	tiles = {"default_chest_top.png","default_chest_top.png",
		"default_chest_side.png","default_chest_side.png",
		"commoditymarket_empty_shelf.png","default_chest_side.png^commoditymarket_moon.png",},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local timeofday =  minetest.get_timeofday()
		if timeofday < 0.2 or timeofday > 0.8 then
			commoditymarket.show_market("night", clicker:get_player_name())
		else
			minetest.chat_send_player(clicker:get_player_name(), "At this time of day the Night Market is closed.")
		end
	end,
})
end

-------------------------------------------------------------------------------
if minetest.settings:get_bool("commoditymarket_enable_caravan_market", true) then
-- "Trader's Caravan" - small-capacity market that players can summon

local time_until_caravan = 120 -- caravan arrives in two minutes
local dwell_time = 600 -- caravan leaves ten minutes after last usage

local caravan_def = {
	description = "Trader's Caravan",
	long_description = "Unlike most markets that have well-known fixed locations that travelers congregate to, the network of Trader's Caravans is fluid and dynamic in their locations. A Trader's Caravan can show up anywhere, make modest trades, and then be gone the next time you visit them. These caravans accept gold and gold coins as a currency (one gold ingot to one thousand gold coins exchange rate). Any reasonably-wealthy person can create a signpost marking a location where Trader's Caravans will make a stop.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "☼", --"\u{263C}"
	inventory_limit = 1000,
	sell_limit = 1000,
	initial_items = default_items,
}

gold_coins_required = true

minetest.register_craft({
	output = "commoditymarket:caravan_post",
	recipe = {
		{'group:wood', 'group:wood', ''},
		{'group:wood', "default:gold_ingot", ''},
		{'group:wood', "default:chest_locked", ''},
	}
})

commoditymarket.register_market("caravan", caravan_def)

minetest.register_node("commoditymarket:caravan_market", {
	description = "Trader's Caravan",
	_doc_items_longdesc = caravan_def.long_description,
	
	drawtype = "mesh",
	mesh = "commoditymarket_wagon.obj",
	tiles = {
		{ name = "commoditymarket_door_wood.png", backface_culling = true }, -- door
		{ name = "default_wood.png", backface_culling = true }, -- base wood
		{ name = "default_fence_rail_wood.png", backface_culling = true }, -- wheel sides
		{ name = "default_coal_block.png", backface_culling = true }, -- wheel tyre
		{ name = "commoditymarket_shingles_wood.png", backface_culling = true }, -- roof
		{ name = "default_junglewood.png", backface_culling = true }, -- corner wood
		},
    collision_box = {
		type = "fixed",
        fixed = {
            {-0.75, -0.5, -1.25, 0.75, 1.5, 1.25},
        },
    },
	selection_box = {
		type = "fixed",
        fixed = {
            {-0.75, -0.5, -1.25, 0.75, 1.5, 1.25},
        },
    },

	paramtype2 = "facedir",
	drop = "",
	groups = {choppy = 2, oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("caravan", clicker:get_player_name())
		local timer = minetest.get_node_timer(pos)
		timer:start(dwell_time)
	end,
	on_timer = function(pos, elapsed)
		local node = minetest.get_node(pos)
		local facedir = node.param2
		local dir = minetest.facedir_to_dir(facedir)
		local target = vector.add(pos, vector.multiply(dir,-3))
		local target_node = minetest.get_node(target)
		if target_node.name == "commoditymarket:caravan_post" then
			local meta = minetest.get_meta(target)
			meta:set_string("infotext", "Right-click to summon another caravan")
		end
		minetest.set_node(pos, {name="air"})
		minetest.sound_play("commoditymarket_register_closed", {
			pos = pos,
			gain = 1.0,  -- default
			max_hear_distance = 32,  -- default, uses an euclidean metric
		})
	end,
})

-- This one doesn't delete itself, server admins can place a permanent instance of it that way. Maybe inside towns next to bigger stationary markets.
minetest.register_node("commoditymarket:caravan_market_permanent", {
	description = "Trader's Caravan",
	_doc_items_longdesc = caravan_def.long_description,
	
	drawtype = "mesh",
	mesh = "commoditymarket_wagon.obj",
	tiles = {
		{ name = "commoditymarket_door_wood.png", backface_culling = true }, -- door
		{ name = "default_wood.png", backface_culling = true }, -- base wood
		{ name = "default_fence_rail_wood.png", backface_culling = true }, -- wheel sides
		{ name = "default_coal_block.png", backface_culling = true }, -- wheel tyre
		{ name = "commoditymarket_shingles_wood.png", backface_culling = true }, -- roof
		{ name = "default_junglewood.png", backface_culling = true }, -- corner wood
		},
    collision_box = {
		type = "fixed",
        fixed = {
            {-0.75, -0.5, -1.25, 0.75, 1.5, 1.25},
        },
    },
	selection_box = {
		type = "fixed",
        fixed = {
            {-0.75, -0.5, -1.25, 0.75, 1.5, 1.25},
        },
    },

	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("caravan", clicker:get_player_name())
	end,
})

-- is a 5x5 area centered around pos clear of obstruction and has usable ground?
local is_suitable_caravan_space = function(pos)
	-- walkable ground?
	for x = pos.x - 2, pos.x + 2, 1 do
		for z = pos.z - 2, pos.z + 2, 1 do
			local node = minetest.get_node({x=x, y=pos.y-1, z=z})
			local node_def = minetest.registered_nodes[node.name]
			if node_def == nil or node_def.walkable ~= true then return false end
		end
	end
	-- air in the rest?
	for y = pos.y, pos.y+2, 1 do
		for x = pos.x - 2, pos.x + 2, 1 do
			for z = pos.z - 1, pos.z + 1, 1 do
				local node = minetest.get_node({x=x, y=y, z=z})
				if node.name ~= "air" then return false end
			end
		end
	end
	return true
end

minetest.register_node("commoditymarket:caravan_post", {
	description = "Trading Post",
	_long_items_longdesc = "This post signals passing caravan traders that customers can be found here, and signals to customers that caravan traders can be found here. If no caravan is present, right-click to summon one.",
	tiles = {"commoditymarket_sign.png^[transformR90", "commoditymarket_sign.png^[transformR270",
		"commoditymarket_sign.png^commoditymarket_caravan_sign.png", "commoditymarket_sign.png^commoditymarket_caravan_sign.png^[transformFX",
		"commoditymarket_sign_post.png", "commoditymarket_sign_post.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	inventory_image = "commoditymarket_caravan_sign_inventory.png",
	paramtype= "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
        type = "fixed",
        fixed = {
			{-0.125,-0.5,-0.5,0.125,2.0625,-0.25},
			{-0.0625,1.4375,-0.25,0.0625,2.0,0.5},
		},
    },
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(1.0)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local timer = minetest.get_node_timer(pos)
		timer:start(1.0)
	end,
	on_timer = function(pos, elapsed)
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		if node.name ~=  "commoditymarket:caravan_post" then
			return -- the node was removed
		end
		local facedir = node.param2
		local dir = minetest.facedir_to_dir(facedir)
		local target = vector.add(pos, vector.multiply(dir,3))

		local target_node = minetest.get_node(target)
		if target_node.name == "commoditymarket:caravan_market" then
			-- It's already here somehow, shut down timer.
			meta:set_string("infotext", "")
			meta:set_float("wait_time", 0)
			return
		end
		
		local is_suitable_space = is_suitable_caravan_space(target)
			
		if not is_suitable_space then
			meta:set_string("infotext", "Indicated parking area isn't suitable.\nA 5x5 open space with solid ground\nis required for a caravan.")
			meta:set_float("wait_time", 0)
			local timer = minetest.get_node_timer(pos)
			timer:start(1.0)
			return
		end
		
		local wait_time = (meta:get_float("wait_time") or 0) + elapsed
		meta:set_float("wait_time", wait_time)
		if wait_time < time_until_caravan then
			meta:set_string("infotext", "Caravan summoned\nETA: " .. math.floor(time_until_caravan - wait_time) .. " seconds.")
			local timer = minetest.get_node_timer(pos)
			timer:start(1.0)
			return
		end
		
		-- spawn the caravan. We've already established that the target pos is clear.
		minetest.set_node(target, {name="commoditymarket:caravan_market", param2=facedir})
		minetest.sound_play("commoditymarket_register_opened", {
			pos = target,
			gain = 1.0,  -- default
			max_hear_distance = 32,  -- default, uses an euclidean metric
		})
		local timer = minetest.get_node_timer(target)
		timer:start(dwell_time)
		meta:set_string("infotext", "")
		meta:set_float("wait_time", 0)
	end,
})
end

-------------------------------------------------------------------------------
-- "Goblin Exchange"
if minetest.settings:get_bool("commoditymarket_enable_goblin_market") then

local goblin_def = {
	description = "Goblin Exchange",
	long_description = "One does not usually associate Goblins with the sort of sophistication that running a market requires. Usually one just associates Goblins with savagery and violence. But they understand the principle of tit-for-tat exchange, and if approached correctly they actually respect the concepts of ownership and debt. However, for some peculiar reason they understand this concept in the context of coal lumps. Goblins deal in the standard coal lump as their form of currency, conceptually divided into 100 coal centilumps (though Goblin brokers prefer to \"keep the change\" when giving back actual coal lumps).",
	currency = {
		["default:coal_lump"] = 100
	},
	currency_symbol = "¢", --"\u{00A2}" cent symbol
	inventory_limit = 1000,
	--sell_limit =, -- no sell limit
}

commoditymarket.register_market("goblin", goblin_def)

minetest.register_node("commoditymarket:goblin_market", {
	description = goblin_def.description,
	_doc_items_longdesc = goblin_def.long_description,
	tiles = {"default_chest_top.png^(default_coal_block.png^[opacity:128)","default_chest_top.png^(default_coal_block.png^[opacity:128)",
		"default_chest_side.png^(default_coal_block.png^[opacity:128)","default_chest_side.png^(default_coal_block.png^[opacity:128)",
		"commoditymarket_empty_shelf.png^(default_coal_block.png^[opacity:128)","default_chest_side.png^(default_coal_block.png^[opacity:128)^commoditymarket_goblin.png",},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("goblin", clicker:get_player_name())	
	end,
})
end
--------------------------------------------------------------------------------

if minetest.settings:get_bool("commoditymarket_enable_under_market") then
local undermarket_def = {
	description = "Undermarket",
	long_description = "Deep in the bowels of the world, below even the goblin-infested warrens and ancient delvings of the dwarves, dark and mysterious beings once dwelled. A few still linger to this day, and facilitate barter for those brave souls willing to travel in their lost realms. The Undermarket uses Mese chips ('₥') as a currency - twenty chips to the Mese fragment. Though traders are loathe to physically break Mese crystals up into units that small, as it renders it useless for other purposes.",
	currency = {
		["default:mese"] = 9*9*20,
		["default:mese_crystal"] = 9*20,
		["default:mese_crystal_fragment"] = 20
	},
	currency_symbol = "₥", --"\u{20A5}" mill sign
	inventory_limit = 10000,
	--sell_limit =, -- no sell limit
}

commoditymarket.register_market("under", undermarket_def)

minetest.register_node("commoditymarket:under_market", {
	description = undermarket_def.description,
	_doc_items_longdesc = undermarket_def.long_description,
	tiles = {"commoditymarket_under_top.png","commoditymarket_under_top.png",
		"commoditymarket_under.png","commoditymarket_under.png","commoditymarket_under.png","commoditymarket_under.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_stone_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("under", clicker:get_player_name())	
	end,
})
end
------------------------------------------------------------------

if gold_coins_required then
minetest.register_craftitem("commoditymarket:gold_coins", {
	description = "Gold Coins",
	inventory_image = "commoditymarket_gold_coins.png",
	stack_max = 1000,
})
end