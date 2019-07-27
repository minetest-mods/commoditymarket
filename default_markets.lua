local default_modpath = minetest.get_modpath("default")
if not default_modpath then return end

local gold_coins_required = false

local default_items = {"default:axe_bronze","default:axe_diamond","default:axe_mese","default:axe_steel","default:axe_steel","default:axe_stone","default:axe_wood","default:pick_bronze","default:pick_diamond","default:pick_mese","default:pick_steel","default:pick_stone","default:pick_wood","default:shovel_bronze","default:shovel_diamond","default:shovel_mese","default:shovel_steel","default:shovel_stone","default:shovel_wood","default:sword_bronze","default:sword_diamond","default:sword_mese","default:sword_steel","default:sword_stone","default:sword_wood", "default:blueberries", "default:book", "default:bronze_ingot", "default:clay_brick", "default:clay_lump", "default:coal_lump", "default:copper_ingot", "default:copper_lump", "default:diamond", "default:flint", "default:gold_ingot", "default:gold_lump", "default:iron_lump", "default:mese_crystal", "default:mese_crystal_fragment", "default:obsidian_shard", "default:paper", "default:steel_ingot", "default:stick", "default:tin_ingot", "default:tin_lump", "default:acacia_tree", "default:acacia_wood", "default:apple", "default:aspen_tree", "default:aspen_wood", "default:blueberry_bush_sapling", "default:bookshelf", "default:brick", "default:bronzeblock", "default:bush_sapling", "default:cactus", "default:clay", "default:coalblock", "default:cobble", "default:copperblock", "default:desert_cobble", "default:desert_sand", "default:desert_sandstone", "default:desert_sandstone_block", "default:desert_sandstone_brick", "default:desert_stone", "default:desert_stone_block", "default:desert_stonebrick", "default:diamondblock", "default:dirt", "default:glass", "default:goldblock", "default:gravel", "default:ice", "default:junglegrass", "default:junglesapling", "default:jungletree", "default:junglewood", "default:ladder_steel", "default:ladder_wood", "default:large_cactus_seedling", "default:mese", "default:mese_post_light", "default:meselamp", "default:mossycobble", "default:obsidian", "default:obsidian_block", "default:obsidian_glass", "default:obsidianbrick", "default:papyrus", "default:pine_sapling", "default:pine_tree", "default:pine_wood", "default:sand", "default:sandstone", "default:sandstone_block", "default:sandstonebrick", "default:sapling", "default:silver_sand", "default:silver_sandstone", "default:silver_sandstone_block", "default:silver_sandstone_brick", "default:snow", "default:snowblock", "default:steelblock", "default:stone", "default:stone_block", "default:stonebrick", "default:tinblock", "default:tree", "default:wood",}

------------------------------------------------------------------------------
if minetest.settings:get_bool("commoditymarket_enable_kings_market") then
local kings_def = {
	description = "King's Market",
	long_description = "The largest and most accessible market for the common man, the King's Market uses gold coins as its medium of exchange (or the equivalent in gold ingots - 1000 coins to the ingot). However, as a respectable institution of the surface world, the King's Market operates only during the hours of daylight. The purchase and sale of swords and explosives is prohibited in the King's Market.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "Au",
	allow_item = function(item)
		if item:sub(1,13) == "default:sword" or item:sub(1,4) == "tnt:" then
			return false
		end
		return true
	end,
	inventory_limit = 100000,
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
	can_dig = function(pos, player)
		if player and minetest.check_player_privs(player, "server") then
			return true
		end
		return false
	end,
})
end
-------------------------------------------------------------------------------

if minetest.settings:get_bool("commoditymarket_enable_night_market") then
local night_def = {
	description = "Night Market",
	long_description = "When the sun sets and the stalls of the King's Market close, other vendors are just waking up to share their wares. The Night Market is not as voluminous as the King's Market but accepts a wider range of wares. It accepts the same gold coinage of the realm.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "Au",
	inventory_limit = 10000,
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
	can_dig = function(pos, player)
		if player and minetest.check_player_privs(player, "server") then
			return true
		end
		return false
	end,
})
end
-------------------------------------------------------------------------------
if minetest.settings:get_bool("commoditymarket_enable_caravan_market", true) then
-- "Trader's Caravan" - small-capacity market that players can build

local caravan_def = {
	description = "Trader's Caravan",
	long_description = "Unlike most markets that have well-known fixed locations that travelers congregate to, the network of Trader's Caravans is fluid and dynamic in their locations. A Trader's Caravan can show up anywhere, make modest trades, and then be gone the next time you visit them. These caravans accept gold and gold coins as a currency.",
	currency = {
		["default:gold_ingot"] = 1000,
		["commoditymarket:gold_coins"] = 1
	},
	currency_symbol = "Au",
	inventory_limit = 1000,
	initial_items = default_items,
}

gold_coins_required = true

minetest.register_craft({
	output = "commoditymarket:caravan_market",
	recipe = {
		{'', "default:gold_ingot", ''},
		{'group:wood', "default:chest_locked", 'group:wood'},
		{'group:wood', 'group:wood', 'group:wood'},
	}
})

commoditymarket.register_market("caravan", caravan_def)

minetest.register_node("commoditymarket:caravan_market", {
	description = "Trader's Caravan",
	_doc_items_longdesc = caravan_def.long_description,
	tiles = {"default_chest_top.png","default_chest_top.png",
		"default_chest_side.png^commoditymarket_caravan.png","default_chest_side.png^commoditymarket_caravan.png",
		"commoditymarket_empty_shelf.png","default_chest_side.png^commoditymarket_trade.png",},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("caravan", clicker:get_player_name())	
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
	currency_symbol = "cC",
	inventory_limit = 1000,
}

commoditymarket.register_market("goblin", goblin_def)

minetest.register_node("commoditymarket:goblin_market", {
	description = goblin_def.description,
	_doc_items_longdesc = goblin_def.long_description,
	tiles = {"default_chest_top.png","default_chest_top.png",
		"default_chest_side.png","default_chest_side.png",
		"commoditymarket_empty_shelf.png","default_chest_side.png^commoditymarket_goblin.png",},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 1,},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		commoditymarket.show_market("goblin", clicker:get_player_name())	
	end,
	can_dig = function(pos, player)
		if player and minetest.check_player_privs(player, "server") then
			return true
		end
		return false
	end,
})
end
--------------------------------------------------------------------------------

if minetest.settings:get_bool("commoditymarket_enable_under_market") then
local undermarket_def = {
	description = "Undermarket",
	long_description = "Deep in the bowels of the world, below even the goblin-infested warrens and ancient delvings of the dwarves, dark and mysterious beings once dwelled. A few still linger to this day, and facilitate barter for those brave souls willing to travel in their lost realms. The Undermarket uses Mese chips as a currency - twenty chips to the Mese fragment. Though traders are loathe to physically break Mese crystals up into units that small, as it renders it useless for other purposes.",
	currency = {
		["default:mese"] = 9*9*20,
		["default:mese_crystal"] = 9*20,
		["default:mese_crystal_fragment"] = 20
	},
	currency_symbol = "\u{20A5}",
	inventory_limit = 10000,
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
	can_dig = function(pos, player)
		if player and minetest.check_player_privs(player, "server") then
			return true
		end
		return false
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