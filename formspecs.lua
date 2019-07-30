local get_icon = function(item)
	local def = minetest.registered_items[item]
	if def then
		local inventory_image = def.inventory_image
		if inventory_image and inventory_image ~= "" then
			return inventory_image
		else
			local tiles = def.tiles
			local tilecount = #tiles
			-- Textures of node; +Y, -Y, +X, -X, +Z, -Z
			local selected_tile = tiles[math.min(5,tilecount)]
			if type(selected_tile) == "string" then
				return selected_tile
			end
			local tile_name = selected_tile.name
			if tile_name then
				return tile_name
			end			
		end
	end
	return "unknown_item.png"
end

local get_item_description = function(item)
	local def = minetest.registered_items[item]
	if def then
		return def.description:gsub("\n", " ")
	end
	return "Unknown Item"
end



-- Inventory formspec
-------------------------------------------------------------------------------------

local inventory_item_comp = function(invitem1, invitem2) return invitem1.item < invitem2.item end
local inventory_desc_comp = function(invitem1, invitem2) return invitem1.description < invitem2.description end

local get_account_formspec = function(market, account)
	local show_itemnames = account.show_itemnames == "true"

	local inventory = {}
	local inventory_count = 0
	for item, quantity in pairs(account.inventory) do
		local icon = get_icon(item)
		table.insert(inventory, {item=item, quantity=quantity, icon=icon, description=get_item_description(item)})
		inventory_count = inventory_count + quantity
	end
	if show_itemnames then
		table.sort(inventory, inventory_item_comp)
	else
		table.sort(inventory, inventory_desc_comp)
	end

	local formspec = {
		"size[10,10]",
		"tabheader[0,0;tabs;"..market.def.description..",Your Inventory,Market Orders;2;false;true]"
	}
	formspec[#formspec+1] = "tablecolumns[image"
	for i=1, #inventory, 2 do
		formspec[#formspec+1] = ","..i.."="..inventory[i].icon
	end
	if show_itemnames then
		formspec[#formspec+1] = ";text"
	end
	formspec[#formspec+1] = ";text;text,align=center;image"
	for i=2, #inventory, 2 do
		formspec[#formspec+1] = ","..i.."="..inventory[i].icon
	end
	if show_itemnames then
		formspec[#formspec+1] = ";text"
	end
	formspec[#formspec+1] = ";text;text,align=center]"
	formspec[#formspec+1] = "tooltip[inventory;All the items you've transfered to the market to sell and the items you've\npurchased with buy orders. Double-click on an item to bring it back into your\npersonal inventory.]"
	formspec[#formspec+1] = "table[0,0;9.9,4;inventory;"
	formspec[#formspec+1] = "0"
	if show_itemnames then
		formspec[#formspec+1] = ",Item"
	end	
	formspec[#formspec+1] = ",Description,Quantity,0"
	if show_itemnames then
		formspec[#formspec+1] = ",Item"
	end	
	formspec[#formspec+1] = ",Description,Quantity"

	for i, entry in ipairs(inventory) do
		formspec[#formspec+1] = "," .. i
		if show_itemnames then
			formspec[#formspec+1] = "," .. entry.item
		end	
		formspec[#formspec+1] = "," .. entry.description:gsub("\n", " ") .. "," .. entry.quantity
	end	
	
	formspec[#formspec+1] = "]container[1.1,4.5]list[detached:commoditymarket:" .. market.name .. ";add;0,0;1,1;]"
		.."label[1,0;Drop items here to\nadd to your account]"
		.."listring[current_player;main]listring[detached:commoditymarket:" .. market.name .. ";add]"
		
	if market.def.inventory_limit then
		formspec[#formspec+1] = "label[3,0;Inventory limit:\n" .. inventory_count.."/" .. market.def.inventory_limit .. "]"
			.. "tooltip[3,0;1.5,1;You can still receive purchased items if you've exceeded your inventory limit,\nbut you won't be able to transfer items from your personal inventory into\nthe market until you've emptied it back down below the limit again.]"
	end
	formspec[#formspec+1] = "label[4.9,0;Balance:\n" .. market.def.currency_symbol .. account.balance .. "]"
		.."field[6.1,0.25;1,1;withdrawamount;;]"
		.."field_close_on_enter[withdrawamount;false]"
		.."button[6.7,0;1.2,1;withdraw;Withdraw]"
		.."tooltip[4.9,0;3.5,1;Enter the amount of currency you'd like to withdraw then click the 'Withdraw'\nbutton to convert it into items and transfer it to your personal inventory.]"
		.."container_end[]"
	
	formspec[#formspec+1] = "container[1.1,5.75]list[current_player;main;0,0;8,1;]"..
			"list[current_player;main;0,1.25;8,3;8]container_end[]"

	return table.concat(formspec)
end


-- Market formspec
--------------------------------------------------------------------------------------------------------

local truncate_item_names_to = 30

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
	local show_itemnames = account.show_itemnames == "true"
	local sort_by = tonumber(account.sort_markets_by_column) or -1
	if show_itemnames then sort_by = sort_by - 1 end -- displace columns 1 if itemnames are enabled
	--	"Icon,Item,Description,#00FF00,Buy Vol,Buy Max,#FF0000,Sell Vol,Sell Min,Last Price"
	if sort_by == 1 and show_itemnames then
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
	local market_def = market.def
	local selected = account.selected
	local market_list = make_marketlist(market, account)
	local show_itemnames = account.show_itemnames == "true"

	local formspec = {
		"size[10,10]",
		"tabheader[0,0;tabs;"..market_def.description..",Your Inventory,Market Orders;3;false;true]",
		"tablecolumns["
	}
	
	-- column definitions
	formspec[#formspec+1] = "image" -- icon
	for i, row in ipairs(market_list) do
		formspec[#formspec+1] = "," .. i .. "=" .. get_icon(row.item)
	end
	formspec[#formspec+1] = ";"
	if show_itemnames then
		formspec[#formspec+1] = "text;" -- itemname
	end
	formspec[#formspec+1] = "text;" -- description
		.."color,span=2;"
		.."text,align=right,tooltip=Number of items there's demand for in the market;"
		.."text,align=right,tooltip=Maximum price being offered to buy one of these;"
		.."color,span=2;"
		.."text,align=right,tooltip=Number of items available for sale in the market;"
		.."text,align=right,tooltip=Minimum price being demanded to sell one of these;"
		.."text,align=right,tooltip=Price paid for one of these the last time one was sold]"
		.."table[0,0;9.9,5;summary;"

	-- header row
	formspec[#formspec+1] = "0"-- icon
	if show_itemnames then
		formspec[#formspec+1] = ",Item" -- itemname
	end
	formspec[#formspec+1] = ",Description,#00FF00,Buy Vol,Buy Max,#FF0000,Sell Vol,Sell Min,Last Price"

	local selected_idx
	local selected_row
	
	local truncate_length
	-- If we're not showing item names we can be more generous in allowed description length
	if show_itemnames then truncate_length = truncate_item_names_to else truncate_length = truncate_item_names_to * 2 end
	
	-- Show list of item market summaries
	for i, row in ipairs(market_list) do
		formspec[#formspec+1] = ","..i -- icon

		if show_itemnames then
			local item_display = row.item
			if item_display:len() > truncate_length then
				item_display = item_display:sub(1,truncate_length-2).."..."
			end
			formspec[#formspec+1] = "," .. item_display
		end
		
		local def = minetest.registered_items[row.item] or {}
		local desc_display = def.description:gsub("\n", " ") or "Unknown Item"
		if desc_display:len() > truncate_length then
			desc_display = desc_display:sub(1,truncate_length-2).."..."
		end
		formspec[#formspec+1] = "," .. desc_display
		formspec[#formspec+1] = ",#00FF00"
		formspec[#formspec+1] = "," .. row.buy_volume
		formspec[#formspec+1] = "," .. ((row.buy_orders[#row.buy_orders] or {}).price or "-")
		formspec[#formspec+1] = ",#FF0000"
		formspec[#formspec+1] = "," .. row.sell_volume
		formspec[#formspec+1] = "," .. ((row.sell_orders[#row.sell_orders] or {}).price or "-")
		formspec[#formspec+1] = "," .. (row.last_price or "-")
		
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
		.."tooltip[filter_participating;Select this to show only the markets where you have either a buy or a sell order pending.]"
		.."tooltip[search_filter;Enter substring to search item identifiers for]"
		.."tooltip[apply_search;Apply search to outputs]"
		.."container_end[]"

	-- if a visible item market is selected, show the orders for it in detail
	if selected_row then
		local current_time = minetest.get_gametime()
		
		local desc_display
		if show_itemnames then
			desc_display = selected
		else
			local def = minetest.registered_items[selected_row.item] or {}
			desc_display = def.description:gsub("\n", " ") or "Unknown Item"
		end

		-- player inventory for this item and for currency
		formspec[#formspec+1] = "label[0.1,5.1;"..desc_display.."\nIn inventory: "
			.. tostring(account.inventory[selected] or 0) .."\nBalance: "..market_def.currency_symbol..account.balance .."]"
		
		-- buy/sell controls
		formspec[#formspec+1] = "container[6,5]"
		local sell_limit = market_def.sell_limit
		if sell_limit then
			local total_sell = 0
			for item, orders in pairs(market.orders_for_items) do
				for _, order in ipairs(orders.sell_orders) do
					if order.account == account then
						total_sell = total_sell + order.quantity
					end
				end
			end
			formspec[#formspec+1] = "label[0,0;Sell limit: ".. total_sell .. "/" .. sell_limit .."]"
				.."tooltip[0,0;2,0.25;This market limits the total number of items a given seller can have for sale at a time.\nYou have "
				..sell_limit-total_sell.." items remaining. Cancel old sell orders to free up space.]"
		end
		formspec[#formspec+1] = "button[0,0.5;1,1;buy;Buy]field[1.3,0.85;1,1;quantity;Quantity;]"
			.."field[2.3,0.85;1,1;price;Price;]button[3,0.5;1,1;sell;Sell]"
			.."field_close_on_enter[quantity;false]field_close_on_enter[price;false]"
			.."tooltip[0,0.25;3.75,1;Use these fields to enter buy and sell orders for the selected item]"
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
	
	local show_itemnames = account.show_itemnames or "false"

	formspec[#formspec+1] = "container[0.5, 7.5]label[0,0;Settings:]checkbox[0,0.25;show_itemnames;Show Itemnames;"
		..show_itemnames.."]container_end[]"
	
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
			local col_count
			local show_itemnames = account.show_itemnames == "true"
			if show_itemnames then
				col_count = 4
			else
				col_count = 3
			end
		
			local index = invevent.row*col_count + math.ceil(invevent.column/col_count) - col_count*2
			local account = market:get_account(name)
			local inventory = {}
			for item, quantity in pairs(account.inventory) do
				table.insert(inventory, {item=item, quantity=quantity, description=get_item_description(item)})
			end
			if show_itemnames then
				table.sort(inventory, inventory_item_comp)
			else
				table.sort(inventory, inventory_desc_comp)
			end
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

	local process_checkbox = function(property_name, fields, account)
		if (fields[property_name] == "true" and account[property_name] ~= "true") or
			(fields[property_name] == "false" and account[property_name] ~= "false") then
			account[property_name] = fields[property_name]
			return true
		end
		return false
	end

	if process_checkbox("filter_participating", fields, account) then something_changed = true end
	if process_checkbox("show_itemnames", fields, account) then something_changed = true end
				
	if fields.apply_search or fields.key_enter_field == "search_filter" then
		something_changed = true
	end
	
	if something_changed then
		minetest.show_formspec(name, formname, market:get_formspec(account))
	end
end)
