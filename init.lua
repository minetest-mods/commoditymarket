commoditymarket = {}

local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP.."/formspecs.lua")
dofile(MP.."/market.lua")
dofile(MP.."/default_markets.lua")

minetest.register_chatcommand("market.show", {
	params = "marketname",
	privs = {server=true},
	decription = "show market formspec",
	func = function(name, param)
		local market = commoditymarket.registered_markets[param]
		if market == nil then return end
		local formspec = market:get_formspec(market:get_account(name))
		minetest.show_formspec(name, "commoditymarket:"..param..":"..name, formspec)
	end,
})
