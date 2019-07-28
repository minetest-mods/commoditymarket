-- Inventory formspec
-------------------------------------------------------------------------------------

local inventory_comp = function(invitem1, invitem2) return invitem1.item < invitem2.item end

local get_account_formspec = function(market, account)
	local formspec = {
		"size[10,10]",
		"tabheader[0,0;tabs;"..market.def.description..",Your Inventory,Market Orders;2;false;true]",
		"tablecolumns[text;text,align=center;text;text,align=center]",
		"table[0,0;9.9,4;inventory;",
		"Item,Quantity,Item,Quantity"
	}

	local inventory = {}
	local inventory_count = 0
	for item, quantity in pairs(account.inventory) do
		table.insert(inventory, {item=item, quantity=quantity})
		inventory_count = inventory_count + quantity
	end
	table.sort(inventory, inventory_comp)
	local i = 1
	while i <= #inventory do
		local n = #formspec+1
		formspec[n] = "," .. inventory[i].item
		formspec[n+1] = "," .. inventory[i].quantity
		i = i + 1
		if inventory[i] then
			formspec[n+2] = "," .. inventory[i].item
			formspec[n+3] = "," .. inventory[i].quantity
		end
		i = i + 1
	end	
	
	formspec[#formspec+1] = "]container[1.1,4.5]list[detached:commoditymarket:"..market.name..";add;0,0;1,1;]"
		.."label[1,0;Drop items here to\nadd to your account]"
		.."listring[current_player;main]listring[detached:commoditymarket:"..market.name..";add]"
		
	if market.def.inventory_limit then
		formspec[#formspec+1] = "label[3,0;Inventory limit:\n"..inventory_count.."/"..market.def.inventory_limit.."]"
	end
	formspec[#formspec+1] = "label[4.9,0;Balance:\n"..market.def.currency_symbol .. account.balance .."]"
		.."field[6.1,0.25;1,1;withdrawamount;;]"
		.."field_close_on_enter[withdrawamount;false]"
		.."button[6.7,0;1.2,1;withdraw;Withdraw]"
		.."container_end[]"
	
	formspec[#formspec+1] = "container[1.1,5.75]list[current_player;main;0,0;8,1;]"..
			"list[current_player;main;0,1.25;8,3;8]container_end[]"

	return table.concat(formspec)
end

-- Market formspec
--------------------------------------------------------------------------------------------------------

local compare_market_item = function(mkt1, mkt2) return mkt1.item < mkt2.item end
local compare_market_desc = function(mkt1, mkt2)
	local def1 = minetest.registered_items[mkt1.item] or {}
	local def2 = minetest.registered_items[mkt2.item] or {}
	return (def1.description or "Unknown Item") < (def2.description or "Unknown Item")
end
local compare_buy_volume = function(mkt1, mkt2) return mkt1.buy_volume > mkt2.buy_volume end
local compare_buy_max = function(mkt1, mkt2)
	return ((mkt1.buy_orders[#mkt1.buy_orders] or {}).price or -2^30) > ((mkt2.buy_orders[#mkt2.buy_orders] or {}).price or -2^30)
end
local compare_sell_volume = function(mkt1, mkt2) return mkt1.sell_volume > mkt2.sell_volume end
local compare_sell_min = function(mkt1, mkt2)
	return ((mkt1.sell_orders[#mkt1.sell_orders] or {}).price or 2^31) < ((mkt2.sell_orders[#mkt2.sell_orders] or {}).price or 2^31)
end
local compare_last_price = function(mkt1, mkt2) return (mkt1.last_price or 2^31) < (mkt2.last_price or 2^31) end

local sort_marketlist = function(item_list, account)
	local sort_by = account.sort_markets_by_column or 1
	--	"Item,Description,#00FF00,Buy Vol,Buy Max,#FF0000,Sell Vol,Sell Min,Last Price"
	if sort_by == 1 then
		table.sort(item_list, compare_market_item)
	elseif sort_by == 2 then
		table.sort(item_list, compare_market_desc)
	elseif sort_by == 4 then
		table.sort(item_list, compare_buy_volume)
	elseif sort_by == 5 then
		table.sort(item_list, compare_buy_max)
	elseif sort_by == 7 then
		table.sort(item_list, compare_sell_volume)
	elseif sort_by == 8 then
		table.sort(item_list, compare_sell_min)
	elseif sort_by == 9 then
		table.sort(item_list, compare_last_price)
	end
end

local make_marketlist = function(market, account)
	local market_list = {}
	local search_filter = account.search or ""
	for item, row in pairs(market.orders_for_items) do
		if (search_filter == "" or string.find(item, search_filter)) then
			if account.filter_participating == "true" then
				local found = false
				for _, order in ipairs(row.buy_orders) do
					if account == order.account then
						found = true
						break
					end
				end
				if not found then
					for _, order in ipairs(row.sell_orders) do
						if account == order.account then
							found = true
							break
						end
					end
				end
				if found then
					table.insert(market_list, row)
				end
			else	
				table.insert(market_list, row)
			end
		end
	end
	sort_marketlist(market_list, account)
	return market_list
end

local get_market_formspec = function(market, account)
	local selected = account.selected
	local formspec = {
		"size[10,10]",
		"tabheader[0,0;tabs;"..market.def.description..",Your Inventory,Market Orders;3;false;true]",
		"tablecolumns[text;"
			.."text;"
			.."color,span=2;"
			.."text,align=right,tooltip=Number of items there's demand for in the market;"
			.."text,align=right,tooltip=Maximum price being offered to buy one of these;"
			.."color,span=2;"
			.."text,align=right,tooltip=Number of items available for sale in the market;"
			.."text,align=right,tooltip=Minimum price being demanded to sell one of these;"
			.."text,align=right,tooltip=Price paid for one of these the last time one was sold]",
		"table[0,0;9.9,5;summary;",
		"Item,Description,#00FF00,Buy Vol,Buy Max,#FF0000,Sell Vol,Sell Min,Last Price"
	}

	local selected_idx
	local selected_row
	
	local market_list = make_marketlist(market, account)
	
	-- Show list of item market summaries
	for i, row in ipairs(market_list) do
		local item_display = row.item
		if item_display:len() > 20 then
			item_display = item_display:sub(1,18).."..."
		end
		local n = #formspec+1
		formspec[n] = "," .. item_display
		local def = minetest.registered_items[row.item] or {}
		local desc_display = def.description or "Unknown Item"
		if desc_display:len() > 20 then
			desc_display = desc_display:sub(1,18).."..."
		end
		formspec[n+1] = "," .. desc_display
		formspec[n+2] = ",#00FF00"
		formspec[n+3] = "," .. row.buy_volume
		formspec[n+4] = "," .. ((row.buy_orders[#row.buy_orders] or {}).price or "-")
		formspec[n+5] = ",#FF0000"
		formspec[n+6] = "," .. row.sell_volume
		formspec[n+7] = "," .. ((row.sell_orders[#row.sell_orders] or {}).price or "-")
		formspec[n+8] = "," .. (row.last_price or "-")
		
		-- we happen to be processing the row that matches the item this player has selected. Record that.
		if selected == row.item then
			selected_row = row
			selected_idx = i + 1
		end

	end
	-- a row that's visible is marked as the selected item, so make it selected in the formspec
	if selected_row then
		formspec[#formspec+1] = ";"..selected_idx 
	end
	formspec[#formspec+1] = "]"

	-- search field
	formspec[#formspec+1] =	"container[2.5,5]field_close_on_enter[search_filter;false]"
		.."field[0,0.85;2.5,1;search_filter;;"..minetest.formspec_escape(account.search or "").."]"
		.."image_button[2.25,0.6;0.8,0.8;commoditymarket_search.png;apply_search;]"
		.."checkbox[1.77,0;filter_participating;My orders;".. account.filter_participating .."]"
		.."tooltip[search_filter;Enter substring to search item identifiers for]"
		.."tooltip[apply_search;Apply search to outputs]"
		.."container_end[]"

	-- if a visible item market is selected, show the orders for it in detail
	if selected_row then
		local current_time = minetest.get_gametime()
		-- player inventory for this item and for currency
		formspec[#formspec+1] = "label[0.1,5.1;"..selected.."\nIn inventory: "
			.. tostring(account.inventory[selected] or 0) .."\nBalance: "..market.def.currency_symbol..account.balance .."]"
		
		-- buy/sell controls
		formspec[#formspec+1] = "container[6,5]"
		formspec[#formspec+1] = "button[0,0.5;1,1;buy;Buy]field[1.3,0.85;1,1;quantity;Quantity;]field[2.3,0.85;1,1;price;Price;]button[3,0.5;1,1;sell;Sell]"
			.."field_close_on_enter[quantity;false]field_close_on_enter[price;false]"
		formspec[#formspec+1] = "container_end[]"

		-- table of buy and sell orders
		formspec[#formspec+1] = "tablecolumns[color;text;"
			.."text,align=right,tooltip=The price per item in this order;"
			.."text,align=right,tooltip=The total amount of items in this particular order;"
			.."text,align=right,tooltip=The total amount of items available at this price accounting for the other orders also currently being offered;"
			.."text,tooltip=The name of the player who placed this order;"
			.."text,align=right,tooltip=How many days ago this order was placed]"
		formspec[#formspec+1] = "table[0,6.5;9.9,3.5;orders;#FFFFFF,Order,Price,Quantity,Total Volume,Player,Days Old"
		local sell_volume = selected_row.sell_volume
		for i, sell in ipairs(selected_row.sell_orders) do
			formspec[#formspec+1] = ",#FF0000,Sell,"..sell.price..","..sell.quantity..","..sell_volume
				..","..sell.account.name..","..math.floor((current_time-sell.timestamp)/86400)
			sell_volume = sell_volume - sell.quantity
		end
		local buy_volume = 0
		local buy_orders = selected_row.buy_orders
		local buy_count = #buy_orders
		-- Show buy orders in reverse order
		for i = buy_count, 1, -1  do
			buy = buy_orders[i]
			buy_volume = buy_volume + buy.quantity
			formspec[#formspec+1] = ",#00FF00,Buy,"..buy.price..","..buy.quantity..","..buy_volume
				..","..buy.account.name..","..math.floor((current_time-buy.timestamp)/86400)
		end
		formspec[#formspec+1] = "]"
	else
		formspec[#formspec+1] = "label[0.1,5.1;Select an item to view or place orders]"
	end
	return table.concat(formspec)
end

-------------------------------------------------------------------------------------
-- Information formspec

--{item=item, quantity=quantity, price=price, purchaser=purchaser, seller=seller, timestamp = minetest.get_gametime()}
local log_to_string = function(market, log_entry)
	local purchaser_name
	if log_entry.purchaser == log_entry.seller then
		purchaser_name = "themself"
	else
		purchaser_name = log_entry.purchaser.name
	end
	return "On day " .. math.ceil(log_entry.timestamp/86400) .. " " .. log_entry.seller.name .. " sold " .. log_entry.quantity .. " "
		.. log_entry.item .. " to " .. purchaser_name .. " at " .. market.def.currency_symbol .. log_entry.price
end


local get_info_formspec = function(market, account)
	local formspec = {
		"size[10,10]",
		"tabheader[0,0;tabs;"..market.def.description..",Your Inventory,Market Orders;1;false;true]",
		"textarea[0.5,0.5;9.5,1.5;;Description:;"..market.def.long_description.."]",
		"textarea[0.5,2.5;9.5,6;;Your Recent Purchases and Sales:;",
	}
	if next(account.log) then
		for _, log_entry in ipairs(account.log) do
			formspec[#formspec+1] = log_to_string(market, log_entry) .. "\n"
		end
	else
		formspec[#formspec+1] = "No logged activites in this market yet"
	end
	formspec[#formspec+1] = "]"
	
	return table.concat(formspec)
end

---------------------------------------------------------------------------------------

commoditymarket.get_formspec = function(market, account)
	local tab = account.tab
	if tab == 1 then
		return get_info_formspec(market, account)
	elseif tab == 2 then
		return get_account_formspec(market, account)
	else
		return get_market_formspec(market, account)
	end
end

------------------------------------------------------------------------------------
-- Handling recieve_fields


local add_to_player_inventory = function(name, item, amount)
	local playerinv = minetest.get_inventory({type="player", name=name})
	local not_full = true
	while amount > 0 and not_full do
		local stack = ItemStack(item .. " " .. amount)
		amount = amount - stack:get_count()
		local leftover = playerinv:add_item("main", stack)
		if leftover:get_count() > 0 then
			amount = amount + leftover:get_count()
			return amount
		end
	end
	return amount
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local formname_split = formname:split(":")

	if formname_split[1] ~= "commoditymarket" then
		return false
	end
	
	local market = commoditymarket.registered_markets[formname_split[2]]
	if not market then
		return false
	end

	local name = formname_split[3]
	if name ~= player:get_player_name() then
		return false
	end

	local account = market:get_account(name)
	local something_changed = false
	
	if fields.tabs then
		account.tab = tonumber(fields.tabs)
		something_changed = true
	end
	
	-- player clicked on an item in the market summary table
	if fields.summary then
		local summaryevent = minetest.explode_table_event(fields.summary)
		if summaryevent.type == "DCL" or summaryevent.type == "CHG" then
			if summaryevent.row == 1 then
				-- header clicked, sort by column
				account.sort_markets_by_column = summaryevent.column 
			else
				-- item clicked, recreate the list to find out which one
				local marketlist = make_marketlist(market, account)
				local selected = marketlist[summaryevent.row-1]
				if selected then
					account.selected = selected.item
				end
			end
		elseif summaryevent.type == "INV" then
			account.selected = nil
		end
		something_changed = true
	end
	
	if fields.orders then
		local ordersevent = minetest.explode_table_event(fields.orders)
		if ordersevent.type == "DCL" then
			local selected_idx = ordersevent.row - 1 -- account for header
			local selected_row = market.orders_for_items[account.selected] -- sell orders come first
			local sell_orders = selected_row.sell_orders
			local sell_order_count = #sell_orders
			local selected_order
			if selected_idx <= sell_order_count then -- if the index is within the range of sell orders, 
				selected_order = sell_orders[selected_idx]
				if selected_order.account == account then -- and the order belongs to the current player,
					market:cancel_sell(account.selected, selected_order) -- cancel it
					something_changed = true
				end
			else
				-- otherwise we're in the buy group, shift the index up by sell_order_count and reverse index order
				local buy_orders = selected_row.buy_orders
				local buy_orders_count = #buy_orders
				selected_order = buy_orders[buy_orders_count - (selected_idx - sell_order_count - 1)]
				if selected_order.account == account then
					market:cancel_buy(account.selected, selected_order)
					something_changed = true
				end
			end
		end
	end

	if fields.buy then
		local quantity = tonumber(fields.quantity)
		local price = tonumber(fields.price)
		if price ~= nil and quantity ~= nil then
			market:buy(name, account.selected, quantity, price)
			something_changed = true
		end
	end
	if fields.sell then
		local quantity = tonumber(fields.quantity)
		local price = tonumber(fields.price)
		if price ~= nil and quantity ~= nil then
			market:sell(name, account.selected, quantity, price)
			something_changed = true
		end
	end

	-- player clicked in their inventory table, may need to give him his stuff back 
	if fields.inventory then
		local invevent = minetest.explode_table_event(fields.inventory)
		if invevent.type == "DCL" then
			local index = invevent.row*2 + math.ceil(invevent.column/2) - 4
			local account = market:get_account(name)
			local inventory = {}
			for item, quantity in pairs(account.inventory) do
				table.insert(inventory, {item=item, quantity=quantity})
			end
			table.sort(inventory, inventory_comp)
			if inventory[index] then
				local item = inventory[index].item
				local amount = account.inventory[item]
				local remaining = add_to_player_inventory(name, item, amount)
				if remaining == 0 then
					account.inventory[item] = nil
				else
					account.inventory[item] = remaining
				end
				if remaining ~= amount then
					something_changed = true
				end
			end
		end
	end

	if fields.withdraw or fields.key_enter_field == "withdrawamount" then
		local withdrawvalue = tonumber(fields.withdrawamount)
		if withdrawvalue then 
			local account = market:get_account(name)
			withdrawvalue = math.min(withdrawvalue, account.balance)
			for _, currency in ipairs(market.def.currency_ordered) do
				this_unit_amount = math.floor(withdrawvalue/currency.amount)
				if this_unit_amount > 0 then
					local remaining = add_to_player_inventory(name, currency.item, this_unit_amount)
					local value_given = (this_unit_amount - remaining) * currency.amount					
					account.balance = account.balance - value_given
					withdrawvalue = withdrawvalue - value_given
					something_changed = true
				end			
			end
		end
	end
	
	if fields.search_filter then
		local value = string.lower(fields.search_filter)
		if account.search ~= value then
			account.search = value
		end
	end

	if (fields.filter_participating == "true" and account.filter_participating == "false") or
		(fields.filter_participating == "false" and account.filter_participating == "true") then
		account.filter_participating = fields.filter_participating
		something_changed = true
	end
				
	if fields.apply_search or fields.key_enter_field == "search_filter" then
		something_changed = true
	end
	
	if something_changed then
		minetest.show_formspec(name, formname, market:get_formspec(account))
	end
end)
