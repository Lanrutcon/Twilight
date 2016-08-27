local Addon = CreateFrame("FRAME");


local Twilight = _G["Twilight"];

--inventory
local inventory, merchantWares = {}, {};
local typeSelected;

local typeIndex, itemIndex;

local colorQualityTable = {
	[0] = {0.41, 0.41, 0.41},	--trash
	[1] = {1, 1, 1},			--common
	[2] = {0.32, 1, 0.2},		--uncommon
	[3] = {0.2, 0.64, 1},		--rare
	[4] = {0.84, 0.41, 1},		--epic
	[5] = {1, 0.7, 0.2},		--legendary
	[7] = {0.90, 0.8, 0.5},		--heirloom
	
	--TODO: Get all colors for all qualities
};

local currencyTable = {
	["Honor Points"] = 392,
	["Conquest Points"] = 390,
	["Justice Points"] = 395,
	["Valor Points"] = 396,
}


---
--TODO
---
--Questions to think about:
--x * How to use an item
-- * How to use an item that has a target AoE effect
-- * How to set an item in the action bar
-- * How to link items to chat
-- * How to write in chat while bags are open
--x * How to distiguish between an enchanted item and a not-enchanted one.
--x 				--Solution: GetContainerItemLink returns a itemLink string which contains the enchants/gems attached
--x							Besides the count, save the enchants/gems as well
--x							Do this only for equipment.
--
--
-- * To do or not to do? That's the question. Merchant Sell & Buy panel
--
--x * IDEA:
-- 			--x Make a KeyBind for TwilightItemButton. Then the player can assign it to any key.
-- 			--x KeyBind is a Right-Click.
-- 			--x This allows the player to use an item without using the mouse.
-- 
-- 
--x * Create 2nd side table
--x * Display Gold and Bag Space
--x * Create item buttons when they are needed (i.e. do not create 200 buttons onInit)
--x * Hide ItemPanel when the player closes all bags
--x * Show a Tooltip with the item stats
--x * Fade In/Out everything!
--x * Set Skyrim Fonts
--x * Inventory must also contain equipped items
-- * Store a index variable for each itemType (just like Skyrim) - No need to save it in a SavedVariable. 
--x * Sort by alphabetic order. (check out: main.lua) -> table.insert(table,pos,value)
--x * Make the skyrim tooltip simple, just show the basic info.
--x * Create ItemType buttons when they are needed (currently it's being created 10). It should help on Merchant Panel
--x * ItemTypeButtons should have points to the 1st button. The 1st button moves and all other buttons move as well. (this can be applied to itemList buttons)
--x * /run print(GetBindingKey("CLICK TwilightItemInfoButton:RightButton")) - add the keybind that player is using to bottom panel
--x * Update BottomPanel with all the important info (x*buy, x*sell, xºdrop, x+equip, ~unequip, x+use keys)
-- 			--TIP: 	Create 3 pairs fontStrings, and use them when you need them.
--					This prevents updating positions.
--x * Usable items must have a key label (currently only show "DROP")
-- * When the player has no keybind for "USE", warn the player when he tries to open the bags
-- 
-- * It needs an urgent clean up...
-- 
--
--	BUGS:
--x * When you equip something, the item disappears from the bags and appears in the character panel (aka inventory). Update their values in the table.
--x * When you hide the addOn while itemList is open, if you show the addon the item list will bug out
--x * Small bug on bottomPanel info. An util function needs to be created for fading in/out with the option to hide in the end.
--x * Long item names go beyond the frames
--x * When interacting with a Merchant, you can't go full down.
--x * When buying/selling, the "Merchant Types" have player items.
--x * Tooltip should include the value when selling/buying
--x * Add a texture to the button that divide the merchant items from player items. And make it "unselectable".
--x * When interacting with a new NPC, the list bugs out. (Merchant table is being updated...)
--x * When selling, if the player sells every thing in a type, it bugs out.
--x * When selling, if the player has multiple items of a type, and sells a kind of an item completely, the last button doesn't hide.
--x * When buying a new item, if the player has not that item type, then it doesn't update (it needs to close interaction)
--x moveEntries and moveItemList is moving according the FPS and not by time elapsed
--x When selling/droping the 1st item in a list, it bugs out.
-- (MAYBE FIXED) (LEGION) Shift+Space is can be used when it shouldn't. It uses the last item that was usable (dangerous).
--x If the itemList is shown when you open the bags, the alpha is not 1. After going back to typeList the alpha goes to 1.

---------------------------------
--UTILS

local function getTableSize(table)
	local size = 0;
	for k,v in pairs(table) do
		size = size + 1;
	end
	return size;
end


local function getEmptySlotPosition()
	for i = 0, 4 do
		for j = 1, GetContainerNumSlots(i) do
			if(not GetContainerItemID(i,j)) then
				return i, j;
			end
		end
	end
end


-------TABLE FUNCTIONS

--New table insert.
--Inserts in alphabethic order
local function tableInsertValue(tab, newIndex, value)
	for num, itemTable in pairs(tab) do
		if(newIndex < itemTable.name) then
			table.insert(tab, num, value);
			return;
		elseif(newIndex == itemTable.name) then
			tab[num] = value;
			return;
		end
	end
	table.insert(tab, value);
end


local function getTableIndexOf(table, itemName)
	for num, itemTable in pairs(table) do
		if(itemTable.name == itemName) then
			return num;
		end
	end
end







--move entries
local frameMover = CreateFrame("FRAME");
--movement is an integer [-1 or +1]
local function moveEntries(list, buttonName, index, movement)
	local btn = list.buttons[1];
	local point, anchor, relativePoint, xOfs, yOfs = btn:GetPoint();
	
	
	--smooth move
	local ofs = 0;
	local total = 0;	--0.04
	frameMover:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		ofs = 64*total/0.04;
		btn:SetPoint("CENTER", 0, yOfs + ofs * movement);
		if(total > 0.04) then
			btn:SetPoint("CENTER", 0, yOfs + 64 * movement);
			self:SetScript("OnUpdate", nil);
		end
	end);
	
	
	for num, btn in pairs(list.buttons) do
		local point, anchor, relativePoint, xOfs, yOfs = btn:GetPoint();
		btn.fontString:SetFontObject(SkyrimFont);
		if(btn.equippedTexture) then
			btn.equippedTexture:SetVertexColor(0.5,0.5,0.5,1);
		end
	end

	_G[buttonName..index].fontString:SetFontObject(SkyrimFontHighlighted);
	local i = 1;
	while(_G[buttonName..index].fontString:GetStringWidth() > 290) do
		_G[buttonName..index].fontString:SetFontObject("SkyrimFontHighlightedSmall"..i);
		i = i + 1;
	end
end


local function showInventory()
	if(IsModifierKeyDown()) then
		return;
	end
	UIParent:SetAlpha(0);
	--WorldFrame:SetFrameStrata("FULLSCREEN");
	MinimapCluster:Hide(); --Minimap icons aren't affected with "SetAlpha"
	
	frameFade(Twilight, 0.2, 0, 1);
	Twilight.selectedButton = nil;
	Twilight:EnableKeyboard(true);
end


local function hideInventory()
	if(not Twilight:IsShown()) then
		return;
	end

	MinimapCluster:Show();
	--WorldFrame:SetFrameStrata("WORLD");

	frameFade(UIParent, 0.2, 0, 1);
	frameFade(Twilight, 0.2, 1, 0, true);
	
	Twilight:EnableKeyboard(false);
	
	Twilight.itemInfo.button:Disable();
end




--Scan bags
local function scanBags()
	for i = 0, 4 do
		for j = 1, GetContainerNumSlots(i) do
			local itemID = GetContainerItemID(i,j);
			local itemLink = GetContainerItemLink(i,j)
			
			if(itemLink) then
				local itemString = string.match(itemLink, "item[%-?%d:]+");
				
				local itemName, itemLink, quality, _, _, itemType, _, _, _, texture, vendorPrice = GetItemInfo(itemID);
				local itemCount = GetItemCount(itemID);
				
				--local index = itemName .. ":" .. itemString;
				
				if(not inventory[itemType]) then
					inventory[itemType] = {};
				end
				if(itemType == "Armor" or itemType == "Weapon") then
					local position = getTableIndexOf(inventory[itemType], itemName);
					if inventory[itemType][position] then
						itemCount = inventory[itemType][position].count;
					else
						itemCount = 0;
					end
					tableInsertValue(inventory[itemType], itemName, {itemString=itemString, itemLink=itemLink, name=itemName, texture=texture, quality=quality, count=(itemCount or 0) + 1, bagID=i, slotID=GetContainerNumSlots(i)-j+1, actualSlotID=j, vendorPrice=vendorPrice});
				else
					tableInsertValue(inventory[itemType], itemName, {itemString=itemString, itemLink=itemLink, name=itemName, texture=texture, quality=quality, count=itemCount, bagID=i, slotID=GetContainerNumSlots(i)-j+1, actualSlotID=j, vendorPrice=vendorPrice});
				end
			end
		end
	end
end

--scan currently equipped items
local function scanEquipment()
	for i=EQUIPPED_FIRST, EQUIPPED_LAST do
		local itemLink = GetInventoryItemLink("player", i);
		local itemID = GetInventoryItemID("player", i);
		if(itemLink) then
			local itemString = string.match(itemLink, "item[%-?%d:]+");
		
			local itemName, itemLink, quality, _, _, itemType, _, _, _, texture, vendorPrice = GetItemInfo(itemID);
			local itemCount = GetItemCount(itemID);
			
			--local index = itemName .. ":" .. itemString;
			
			if(not inventory[itemType]) then
				inventory[itemType] = {};
			end
			
			if(itemType == "Armor" or itemType == "Weapon") then
				local position = getTableIndexOf(inventory[itemType], itemName);
				if inventory[itemType][position] then
					inventory[itemType][position].count = (inventory[itemType][position].count or 0) + 1;
					inventory[itemType][position].isEquipped = true;
					inventory[itemType][position].slotID = i;
				else
					tableInsertValue(inventory[itemType], itemName, {itemString=itemString, itemLink=itemLink, name=itemName, texture=texture, quality=quality, count=1, isEquipped=true, slotID=i, vendorPrice=vendorPrice});
				end
			end
			
		end
	end
end



local waitFrame = CreateFrame("FRAME");

--waiting function
--waits for the given event to trigger, and then executes the given function.
--After one occur, unregisters the event
local function waitForEvent(event, func)
	waitFrame:SetScript("OnEvent", function(self, event)
		self:UnregisterEvent(event);
		func();	
	end);
	waitFrame:RegisterEvent(event);
end



local isScanningMerchant, readingMerchant;
--Scan merchant wares and saves all info in "MerchantWare" table
local function scanMerchant()
	if(not MerchantFrame:IsShown()) then
		return;
	end
	
	isScanningMerchant = true;
	
	table.wipe(merchantWares);
	for i=1, GetMerchantNumItems() do
		local itemLink = GetMerchantItemLink(i);
		--this may happen when interacting with a merchant with new items (i.e. items not in cache)
		if(not itemLink) then
			--query all merchant pages
			for j=1,math.ceil(GetMerchantNumItems()/MERCHANT_ITEMS_PER_PAGE) do
				MerchantFrame.page = j;
				MerchantFrame_Update();
			end
			waitForEvent("MERCHANT_UPDATE", scanMerchant);
			return;
		end

		
		local name, texture, costGold, stack, stock, canUse, anotherCurrency = GetMerchantItemInfo(i);
		local currencyTexture, currencyAmount, _, currencyName = GetMerchantItemCostItem(i, 1);

		local itemName, itemLink, quality, _, _, itemType = GetItemInfo(itemLink);
		
		if(not merchantWares[itemType]) then
			merchantWares[itemType] = {};
		end
		
		local itemString = string.match(itemLink, "item[%-?%d:]+");
		tableInsertValue(merchantWares[itemType], itemName, {itemString=itemString, itemLink=itemLink, name=itemName, texture=texture, quality=quality, count=stock, slotID=i, cost=costGold, stack=stack, currencyName=currencyName, currencyAmount=currencyAmount, currencyTexture=currencyTexture});
	end
	
	isScanningMerchant = false;
end


local function scanAll()
	table.wipe(inventory);
	scanBags();
	scanEquipment();	
end


--if "true" gets the right fontstring (type) on the tooltip
local INVTYPE = {
	[INVTYPE_2HWEAPON] = true,
	[INVTYPE_BODY] = false,
	[INVTYPE_CHEST] = true,
	[INVTYPE_CLOAK] = false,
	[INVTYPE_FEET] = true,
	[INVTYPE_FINGER] = false,
	[INVTYPE_HAND] = true,
	[INVTYPE_HEAD] = true,
	[INVTYPE_HOLDABLE] = false,
	[INVTYPE_LEGS] = true,
	[INVTYPE_NECK] = false,
	[INVTYPE_RANGED] = true,
	[INVTYPE_RELIC] = true,
	[INVTYPE_SHIELD] = true,
	[INVTYPE_SHOULDER] = true,
	[INVTYPE_TABARD] = false,
	[INVTYPE_THROWN] = true,
	[INVTYPE_TRINKET] = false,
	[INVTYPE_WAIST] = true,
	[INVTYPE_WEAPON] = true,
	[INVTYPE_WEAPONMAINHAND] = true,
	[INVTYPE_WEAPONOFFHAND] = true,
	[INVTYPE_WRIST] = true,
	
	--Check GlobalStrings.lua for more entries.

};

local function getItemStats(itemLink)
	GameTooltip:SetOwner(TwilightItemInfoButton, "ANCHOR_RIGHT");
	GameTooltip:SetHyperlink(itemLink);
	
	
	local slot, type, stat;
	
	for i=1, GameTooltip:NumLines()-1 do
		local text = _G["GameTooltipTextLeft"..i]:GetText() or "";
		if(INVTYPE[text] == true) then
			slot, type = text, _G["GameTooltipTextRight"..i]:GetText()
		elseif(INVTYPE[text] == false) then
			slot = text;
		end
		
		if (string.find(_G["GameTooltipTextLeft"..i+1]:GetText() or "", DAMAGE) or
			string.find(_G["GameTooltipTextLeft"..i+1]:GetText() or "", ARMOR)) then
				stat = _G["GameTooltipTextLeft"..i+1]:GetText();
				break;
		end
	end
	
	GameTooltip:Hide();
	
	--polish STAT value (i.e. removing "Armor", "Damage", etc...)
	if(stat) then
		local index = string.find(stat, "%d+");
		local parsed = "";
		while(index) do
			parsed = parsed .. string.sub(stat, 0, index);
			stat = string.sub(stat, index+1, -1);
			index = string.find(stat, "%d+");
		end
		stat = parsed;
	end
	
	
	return slot, type, stat;
end


local function updateBottomPanel()
	local panel = Twilight.bottomPanel;
	
	local itemTable;
	
	if(not typeSelected) then
		frameFade(panel.label1, 0.2, 1, 0, true);
		frameFade(panel.string1, 0.2, 1, 0, true);
		
		if(panel.label2:IsShown()) then
			frameFade(panel.label2, 0.2, 1, 0, true);
			frameFade(panel.string2, 0.2, 1, 0, true);
		end
		
		return;
	end
	
	if(readingMerchant) then
		itemTable = merchantWares[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
		
		--show "buy" keybind
		panel.label1:SetText("Buy");
		panel.string1:SetText("[E]");
		
		panel.label1:Show();
		panel.string1:Show();
		
		
		--hide the rest
		panel.label2:Hide();
		panel.string2:Hide();
	else
		itemTable = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
		
		local isUsable = IsConsumableItem(itemTable.itemLink);
		local keybind = GetBindingKey("CLICK TwilightItemInfoButton:RightButton");
		
		--if interacting with a merchant
		if(MerchantFrame:IsShown()) then
			--hide all everything besides :>> show "sell" keybind
			panel.label1:SetText("Sell");
			panel.string1:SetText("[".. keybind .."]");
			
			if(itemTable.vendorPrice > 0) then
				panel.label1:Show();
				panel.string1:Show();
			else
				panel.label2:Hide();
				panel.string2:Hide();
			end
		
		else
			--if is ARMOR or WEAPON, show [shift+space] key
			if(typeSelected == "Armor" or typeSelected == "Weapon") then
				if(not itemTable.isEquipped) then
					panel.label1:SetText("Equip");
					panel.string1:SetText("[".. keybind .."]");
				else --if equipped
					panel.label1:SetText("Unequip");
					panel.string1:SetText("[R]");
				end
				
				panel.label2:SetText("Drop");
				panel.string2:SetText("[Q]");
				
				panel.label2:Show();
				panel.string2:Show();
			else
				if(isUsable) then
					panel.label1:SetText("Use");
					panel.string1:SetText("[".. keybind .."]");
					
					panel.label2:SetText("Drop");
					panel.string2:SetText("[Q]");
					
					panel.label2:Show();
					panel.string2:Show();
				else
					panel.label1:SetText("Drop");
					panel.string1:SetText("[Q]");
					
					panel.label2:Hide();
					panel.string2:Hide();
				end
			end
			
			panel.label1:Show();
			panel.string1:Show();
		end

	end
end


local function hideItemList()
	if(not Twilight.itemList:IsShown() or Twilight.itemList.moving) then
		return;
	end
	
	Twilight.itemList.moving = true;
	
	frameFade(Twilight.typeList.disabledFrame, 0.2, 1, 0, true);
	
	local alpha = Twilight.itemList:GetAlpha();
	local offSet = 260;
	local total = 0;
	Twilight.itemList:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		
		alpha = 1-total/0.2;
		offSet = 260-260*total/0.2;
		

		self:SetAlpha(alpha);
		self:SetPoint("LEFT", WorldFrame, offSet, 0);
		
		if(total > 0.2) then
			self:SetScript("OnUpdate", nil);
			self:Hide();
			self.moving = false;
		end
		
	end);
	
	updateBottomPanel();

end


local function updateItemTooltip()

	local addOnTooltip = _G["TwilightItemInfo"];
	
	--item name
	--checks if the name is too big
	addOnTooltip.itemInfoName:SetFontObject(SkyrimFontItemTitle);
	if(addOnTooltip.itemInfoName:GetStringWidth() > 450) then
		addOnTooltip.itemInfoName:SetFontObject(SkyrimFontItemTitleSmall);
	end
	
	
	local itemTable;
	
	if(readingMerchant) then
		itemTable = merchantWares[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
	else
		itemTable = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
	end
	

	--if the player is selling/buying, show price
	if(MerchantFrame:IsShown()) then
		--show value if interacting with a merchant
		if(readingMerchant) then
			if(itemTable.currencyTexture) then
				if(currencyTable[itemTable.currencyName]) then
					local currencyName, playerCurrencyAmount = GetCurrencyInfo(currencyTable[itemTable.currencyName]);
					if(playerCurrencyAmount < itemTable.currencyAmount) then
						addOnTooltip.valueString:SetText("|cffee3333"..itemTable.currencyAmount .. "|r\124T" ..itemTable.currencyTexture.. ":16\124t");
					end
				else
					addOnTooltip.valueString:SetText(itemTable.currencyAmount .. "\124T" ..itemTable.currencyTexture.. ":16\124t");
				end
			else
				addOnTooltip.valueString:SetText(GetCoinTextureString(itemTable.cost));
			end
			addOnTooltip.valueLabel:Show();
			addOnTooltip.valueString:Show();
		elseif(itemTable.vendorPrice > 0) then
			addOnTooltip.valueString:SetText(GetCoinTextureString(itemTable.vendorPrice));
			addOnTooltip.valueLabel:Show();
			addOnTooltip.valueString:Show();
		else
			addOnTooltip.valueLabel:Hide();
			addOnTooltip.valueString:Hide();
		end
	else
		addOnTooltip.valueLabel:Hide();
		addOnTooltip.valueString:Hide();
	end

		
	--Item stats
	if(typeSelected ~= "Armor" and typeSelected ~= "Weapon") then
		addOnTooltip.statLabel:Hide();
		addOnTooltip.statString:Hide();
		addOnTooltip.typeLabel:Hide();
		addOnTooltip.typeString:Hide();
		addOnTooltip.slotLabel:Hide();
		addOnTooltip.slotString:Hide();
		return;
	end
	
	
	

	
	local itemLink = itemTable.itemLink;
	local slot, type, stat = getItemStats(itemLink);
	
	

	addOnTooltip.statLabel:Show();
	addOnTooltip.statString:Show();
	addOnTooltip.typeLabel:Show();
	addOnTooltip.typeString:Show();
	addOnTooltip.slotLabel:Show();
	addOnTooltip.slotString:Show();
	--special cases	
	--Held in off-hand, Fingers, Necks, Trinkets
	if (slot == INVTYPE_HOLDABLE or slot == INVTYPE_FINGER or slot == INVTYPE_NECK or slot == INVTYPE_TRINKET or
		slot == INVTYPE_TABARD or slot == INVTYPE_BODY) then
		addOnTooltip.statLabel:Hide();
		addOnTooltip.statString:Hide();
		addOnTooltip.typeLabel:Hide();
		addOnTooltip.typeString:Hide();
	--Relics
	elseif(slot == INVTYPE_RELIC) then
		addOnTooltip.statLabel:Hide();
		addOnTooltip.statString:Hide();
	--Cloacks
	elseif(slot == INVTYPE_CLOAK) then
		addOnTooltip.typeLabel:Hide();
		addOnTooltip.typeString:Hide();	
	elseif(typeSelected == "Armor") then
		addOnTooltip.statLabel:SetText(ARMOR:upper());
		addOnTooltip.statString:SetText(stat);
	elseif(typeSelected == "Weapon") then
		addOnTooltip.statLabel:SetText(DAMAGE:upper());
		addOnTooltip.statString:SetText(stat);
	else
		addOnTooltip.statLabel:Hide();
		addOnTooltip.statString:Hide();
		addOnTooltip.typeLabel:Hide();
		addOnTooltip.typeString:Hide();
	end
	addOnTooltip.typeString:SetText(type);
	addOnTooltip.slotString:SetText(slot);
	addOnTooltip.statString:SetText(stat);
	
	
	--rearrange labels and strings (i.e. centering them)
	--get num labels available:
	local i, shownLabels = 0, {};
	for num,label in pairs({addOnTooltip.typeLabel, addOnTooltip.statLabel, addOnTooltip.slotLabel}) do
		if(label:IsShown()) then
			i = i + 1;
			table.insert(shownLabels, label);
		end
	end
	for num,label in pairs(shownLabels) do
		if(i == 1) then
			label:SetPoint("CENTER", -30, -22);
		elseif(i == 2) then
			label:SetPoint("CENTER", (num*100)-170, -22);
		elseif(i == 3) then
			label:SetPoint("CENTER", (num*160)-350, -22);
		end
	end
	
end



local function updateItemButton()

	local twi = Twilight;

	local itemTable;
	
	if(readingMerchant) then
		itemTable = merchantWares[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
	else
		itemTable = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
	end
	
	
	twi.itemInfo.itemTexture.itemTable = itemTable;
	
	
	if(readingMerchant) then
		twi.itemInfo.button:Disable();	--make sure we disable the button, when scrolling merchant wares.
										--the button shouldn't do anything in these cases.
		SetItemButtonTexture(twi.itemInfo.itemTexture, itemTable.texture);
		if(itemTable.stack > 1) then
			twi.itemInfo.itemTexture.stack:SetText(itemTable.stack);
			twi.itemInfo.itemTexture.stack:Show();
		else
			twi.itemInfo.itemTexture.stack:Hide();
		end
	else
		
		--if the item is not equipped
		if(not itemTable.isEquipped) then
			twi.itemInfo.button:Enable();
			twi.itemInfo.button:SetParent(_G["ContainerFrame"..itemTable.bagID+1]);
			twi.itemInfo.button:SetID(itemTable.actualSlotID);
			
			--local texture = GetContainerItemInfo(itemTable.bagID, itemTable.actualSlotID);
			SetItemButtonTexture(twi.itemInfo.itemTexture, itemTable.texture);
		
		--if the item is equipped
		else
			twi.itemInfo.button:Disable();
			--local texture = GetInventoryItemTexture("player", itemTable.slotID);
			SetItemButtonTexture(twi.itemInfo.itemTexture, itemTable.texture);
		end
	end
	 
	_G["TwilightItemInfoItemInfoName"]:SetText(string.upper(itemTable.name));
		 
	twi.itemInfo.itemTexture.iconTexture:SetTexCoord(0.075,0.925,0.075,0.925);
end

local function updateItemTypeButtons()
	--if player is interacting with a merchant
	if(MerchantFrame:IsShown()) then
		--set type buttons according with merchantWare table
		local i = 1;
		local btn;
		for type, _ in pairs(merchantWares) do
			local btn = _G["TwilightTypeListbutton"..i];
			if(not btn) then
				btn = CreateFrame("FRAME", "TwilightTypeListbutton"..i, Twilight.typeList, "TwilightTypeListButtonTemplate");
				btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -64);
				table.insert(Twilight.typeList.buttons, btn);
			end
			
			btn.fontString:SetText(string.upper(type));
			btn.fontString:SetFontObject(SkyrimFont);
			
			btn.text = type;
			if(_G["TwilightTypeListbutton"..i-1]) then
				btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -64);
			else
				btn:SetPoint("CENTER", Twilight.typeList, 0, 64*(typeIndex-1));
			end
			btn.texture:Hide();
			btn:Show();
			i = i + 1;
		end
		
		--setting the line texture that divides the merchant from the player
		btn = _G["TwilightTypeListbutton"..i]
		btn.texture:Show();

		btn.fontString:SetText("");
		btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -64);
		btn:Show();
			
		i = i + 1;
		for type, _ in pairs(inventory) do
			btn = _G["TwilightTypeListbutton"..i];
			if(not btn) then
				btn = CreateFrame("FRAME", "TwilightTypeListbutton"..i, Twilight.typeList, "TwilightTypeListButtonTemplate");
				btn:SetPoint("CENTER", 0, -(i-1)*64);
				table.insert(Twilight.typeList.buttons, btn);
			end
			btn.fontString:SetText(string.upper(type));
			btn.fontString:SetFontObject(SkyrimFont);
			
			btn.text = type;
			if(_G["TwilightTypeListbutton"..i-1]) then
				btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -64);
			else
				btn:SetPoint("CENTER", Twilight.typeList, 0, 64*(typeIndex-1));
			end
			btn.texture:Hide();
			btn:Show();
			i = i + 1;
		end
		for j=i, getTableSize(Twilight.typeList.buttons) do
			_G["TwilightTypeListbutton"..j]:Hide();
		end
		_G["TwilightTypeListbutton"..typeIndex].fontString:SetFontObject(SkyrimFontHighlighted);
		
		--set type buttons for players items
		
	else
		--set type buttons for players items
		local i = 1;
		for type, table in pairs(inventory) do
			local btn = _G["TwilightTypeListbutton"..i];
			btn.fontString:SetText(string.upper(type));
			btn.fontString:SetFontObject(SkyrimFont);
			
			btn.text = type;
			--btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1] or Twilight.typeList, 0, -64);
			
			if(_G["TwilightTypeListbutton"..i-1]) then
				btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -64);
			else
				btn:SetPoint("CENTER", Twilight.typeList, 0, 64*(typeIndex-1));
			end
			btn.texture:Hide();
			btn:Show();
			i = i + 1;
		end
		for j=i, getTableSize(Twilight.typeList.buttons) do
			_G["TwilightTypeListbutton"..j]:Hide();
		end
		_G["TwilightTypeListbutton"..typeIndex].fontString:SetFontObject(SkyrimFontHighlighted);
	end
end



local function updateItemListButtons()
	for num, button in pairs(Twilight.itemList.buttons) do
		if(not button:IsShown()) then
			return;
		end
		
		if(readingMerchant) then
			--if the nutwier of the button is higher than the nutwier of items in the merchant items, then something was bought (happens with stock items)
			--TODO: Check if this is the best place to handle this
			if(num > getTableSize(merchantWares[typeSelected])) then
				button:Hide();
				return;
			end
			button.equippedTexture:Hide();
			button.fontString:SetTextColor(unpack(colorQualityTable[merchantWares[typeSelected][button.index].quality]));
			if(merchantWares[typeSelected][button.index].count > 1) then
				button.fontString:SetText(merchantWares[typeSelected][button.index].name .. " (" .. merchantWares[typeSelected][button.index].count .. ")");
			else
				button.fontString:SetText(merchantWares[typeSelected][button.index].name);
			end	
		else
			--when the player sells everything in a type, checks if it's the 1st button to get out
			--and if yes, brings the player to the typeMenu
			--TODO: Think about if this is the best place to handle this problem
			if(num == 1 and not inventory[typeSelected]) then
				--if the typeSelected was also the last one, move up aswell
				if(typeIndex > getTableSize(inventory)) then
					typeIndex = typeIndex - 1;
					moveEntries(Twilight.typeList, "TwilightTypeListbutton", itemIndex, -1);
				end
				hideItemList();
				updateItemTypeButtons();
				return;
			end
			
			--if the nutwier of the button is higher than the nutwier of items in the inventory, then something was sold/deleted
			--TODO: Check if this is the best place to handle this
			--print(num, getTableSize(inventory[typeSelected]))
			if(num > getTableSize(inventory[typeSelected])) then
				button:Hide();
				if(itemIndex > getTableSize(inventory[typeSelected])) then
					itemIndex = itemIndex - 1;
					moveEntries(Twilight.itemList, "TwilightItemListbutton", itemIndex, -1);
					updateItemButton();
					updateItemTooltip();
				end

				return;
			end
			
			--show equipped texture if the item is equipped
			if(inventory[typeSelected][button.index] and inventory[typeSelected][button.index].isEquipped) then
				button.equippedTexture:Show();
			else
				button.equippedTexture:Hide();
			end
			
			button.fontString:SetTextColor(unpack(colorQualityTable[inventory[typeSelected][button.index].quality]));
			
			if(inventory[typeSelected][button.index].count > 1) then
				button.fontString:SetText(inventory[typeSelected][button.index].name .. " (" .. inventory[typeSelected][button.index].count .. ")");
			else
				button.fontString:SetText(inventory[typeSelected][button.index].name);
			end
		end
		
		if(inventory[typeSelected] and not inventory[typeSelected][button.index] and merchantWares[typeSelected] and not merchantWares[typeSelected][button.index]) then
			button:Hide();
		end

	end
end






--create all frames, fontStrings, textures, etc...
local function setUpInventory()	
	
	--Twilight = CreateFrame("FRAME", "Twilight", WorldFrame);
	--Twilight:SetPoint("TOPLEFT");
	--Twilight:Hide();
	
	--shorter name
	local twi = Twilight;
	--twi:SetAllPoints();
	
	
	twi.background = twi:CreateTexture();
	twi.background:SetAllPoints();
	twi.background:SetColorTexture(0.0,0.0,0.0, 0.3);
	
	--------------------------------------	
	--TYPE PANEL (Consumables, Weapons, etc...)
	twi.typeList = CreateFrame("FRAME", "TwilightTypeList", twi);
	twi.typeList:SetSize(225, GetScreenHeight());
	twi.typeList:SetPoint("LEFT", WorldFrame, 15, 0);
	twi.typeList:SetFrameStrata("FULLSCREEN");
	
	
	twi.typeList.background = twi.typeList:CreateTexture(nil, "BACKGROUND");
	twi.typeList.background:SetColorTexture(0.02,0.02,0.02,0.6);
	twi.typeList.background:SetAllPoints();
	
	twi.typeList.leftLine = twi.typeList:CreateTexture(nil, "ARTWORK");
	twi.typeList.leftLine:SetColorTexture(0.4,0.4,0.4,0.9);
	twi.typeList.leftLine:SetSize(3, GetScreenHeight());
	twi.typeList.leftLine:SetPoint("LEFT", 3, 0);
	
	twi.typeList.rightLine = twi.typeList:CreateTexture(nil, "ARTWORK");
	twi.typeList.rightLine:SetColorTexture(0.4,0.4,0.4,0.9);
	twi.typeList.rightLine:SetSize(3, GetScreenHeight());
	twi.typeList.rightLine:SetPoint("RIGHT", -4, 0);
	
	twi.typeList.disabledFrame = CreateFrame("FRAME", "TwilightTypeListDisabledTexture", twi.typeList);
	twi.typeList.disabledFrame:SetFrameLevel(10);
	twi.typeList.disabledFrame:SetAllPoints();
	
	twi.typeList.disabledFrame.texture = twi.typeList.disabledFrame:CreateTexture(nil, "OVERLAY");
	twi.typeList.disabledFrame.texture:SetColorTexture(0.8,0.8,0.8,0.2);
	twi.typeList.disabledFrame.texture:SetAllPoints();
	
	twi.typeList.disabledFrame:Hide();
	
	
	twi.typeList.buttons = {};
	--createButtons
	for i=1, 10 do
		local btn = CreateFrame("FRAME", "TwilightTypeListbutton"..i, twi.typeList, "TwilightTypeListButtonTemplate");
		if(_G["TwilightTypeListbutton"..i-1]) then
			btn:SetPoint("CENTER", _G["TwilightTypeListbutton"..i-1], 0, -(i-1)*64);
		else
			btn:SetPoint("CENTER", twi.typeList, 0, 0);
		end
		
		table.insert(twi.typeList.buttons, btn);
	end
	
	--------------------------------------
	--ITEMS PANEL
	twi.itemList = CreateFrame("FRAME", "TwilightItemList", twi.typeList);
	twi.itemList:SetSize(325, GetScreenHeight());
	twi.itemList:SetPoint("LEFT", WorldFrame, 15+225+20, 0);
	twi.itemList:SetFrameStrata("FULLSCREEN");
	
	twi.itemList:Hide();
	
	twi.itemList.background = twi.itemList:CreateTexture(nil, "BACKGROUND");
	twi.itemList.background:SetColorTexture(0.02,0.02,0.02,0.6);
	twi.itemList.background:SetAllPoints();
	
	twi.itemList.leftLine = twi.itemList:CreateTexture(nil, "ARTWORK");
	twi.itemList.leftLine:SetColorTexture(0.4,0.4,0.4,0.9);
	twi.itemList.leftLine:SetSize(3, GetScreenHeight());
	twi.itemList.leftLine:SetPoint("LEFT", 3, 0);
	
	twi.itemList.rightLine = twi.itemList:CreateTexture(nil, "ARTWORK");
	twi.itemList.rightLine:SetColorTexture(0.4,0.4,0.4,0.9);
	twi.itemList.rightLine:SetSize(3, GetScreenHeight());
	twi.itemList.rightLine:SetPoint("RIGHT", -5, 0);
	
	twi.itemList.buttons = {};
	
	twi.itemList:SetScript("OnShow", function(self)
		--smooth movement to the right
		itemIndex = 1;
		local offSet = 0;
		local total = 0;
		twi.itemList:SetScript("OnUpdate", function(self, elapsed)
			total = total + elapsed;
			
			offSet = 260*total/0.2;
			
			self:SetPoint("LEFT", WorldFrame, offSet, 0);
			
			if(total > 0.2) then
				self:SetScript("OnUpdate", nil);
			end
			
		end);
		
		frameFade(self, 0.2, 0, 1);
	
	
		--check if is interacting with a merchant
		local i = 1;
		if(readingMerchant) then
			for index, itemInfo in pairs(merchantWares[typeSelected]) do
			
				--create button if it doesnt exists
				local btn = _G["TwilightItemListbutton"..i];
				if(not btn) then
					btn = CreateFrame("FRAME", "TwilightItemListbutton"..i, Twilight.itemList, "TwilightItemListButtonTemplate");
					--btn:SetPoint("CENTER", _G["TwilightItemListbutton"..i-1], 0, -64);
					table.insert(Twilight.itemList.buttons, btn);
				end
				
				--sets amount
				if(itemInfo.count > 1) then
					_G["TwilightItemListbutton"..i].fontString:SetText(itemInfo.name .. " (" .. itemInfo.count .. ")");
				else
					_G["TwilightItemListbutton"..i].fontString:SetText(itemInfo.name);
				end
				
				_G["TwilightItemListbutton"..i].index = index;
			
				_G["TwilightItemListbutton"..i].itemInfo = itemInfo;
				
				--_G["TwilightItemListbutton"..i]:SetPoint("CENTER", 0, -(i-1)*64);
				if(_G["TwilightItemListbutton"..i-1]) then
					btn:SetPoint("CENTER", _G["TwilightItemListbutton"..i-1], 0, -64);
				else
					btn:SetPoint("CENTER", Twilight.itemList, 0, 64*(itemIndex-1));
				end
				
				_G["TwilightItemListbutton"..i].fontString:SetFontObject(SkyrimFont);
				_G["TwilightItemListbutton"..i]:Show();
				
				i = i + 1;
			end		
	
		else
			for index, itemInfo in pairs(inventory[typeSelected]) do
				
				--create button if it doesnt exists				
				local btn = _G["TwilightItemListbutton"..i];
				if(not btn) then
					btn = CreateFrame("FRAME", "TwilightItemListbutton"..i, Twilight.itemList, "TwilightItemListButtonTemplate");
					--btn:SetPoint("CENTER", _G["TwilightItemListbutton"..i-1], 0, -64);
					table.insert(Twilight.itemList.buttons, btn);
				end
				
				--sets amount 
				if(itemInfo.count > 1) then
					_G["TwilightItemListbutton"..i].fontString:SetText(itemInfo.name .. " (" .. itemInfo.count .. ")");
				else
					_G["TwilightItemListbutton"..i].fontString:SetText(itemInfo.name);
				end
	
				
				_G["TwilightItemListbutton"..i].index = index;
				
				_G["TwilightItemListbutton"..i].itemInfo = itemInfo;
				
				--_G["TwilightItemListbutton"..i]:SetPoint("CENTER", 0, -(i-1)*64);
				if(_G["TwilightItemListbutton"..i-1]) then
					btn:SetPoint("CENTER", _G["TwilightItemListbutton"..i-1], 0, -64);
				else
					btn:SetPoint("CENTER", Twilight.itemList, 0, 64*(itemIndex-1));
				end
				_G["TwilightItemListbutton"..i].fontString:SetFontObject(SkyrimFont);
				_G["TwilightItemListbutton"..i]:Show();
				i = i + 1;
			end
		end
		--hide rest of the buttons
		for j=i, getTableSize(twi.itemList.buttons) do
			_G["TwilightItemListbutton"..j]:Hide();
		end
		
		_G["TwilightItemListbutton"..1].fontString:SetFontObject(SkyrimFontHighlighted);
		--decreases font size if the text is too long
		local i = 1;
		while(_G["TwilightItemListbutton"..1].fontString:GetStringWidth() > 290) do
			_G["TwilightItemListbutton"..1].fontString:SetFontObject("SkyrimFontHighlightedSmall"..i);
			i = i + 1;
		end
		
		frameFade(twi.typeList.disabledFrame, 0.2, 0, 1);
		
		--updates item image
		updateItemButton();
		updateItemTooltip();
		
		--updates info on bottomPanel
		updateBottomPanel();
	
	end);
	
	twi.itemList:SetScript("OnHide", function(self)
		readingMerchant = false;
	end);
	
	
	
	

	local function twi_OnKeyW()
		if(twi.itemList:IsShown() and typeSelected) then
			if(itemIndex == 1) then
				return;
			end
			itemIndex = itemIndex - 1;
			moveEntries(twi.itemList, "TwilightItemListbutton", itemIndex, -1);
			
			updateItemButton();
			updateItemTooltip();
			updateBottomPanel();
		else
			if(typeIndex == 1) then
				return;
			end
			
			if(_G["TwilightTypeListbutton"..typeIndex-1].texture:IsShown()) then
				typeIndex = typeIndex - 2;
				moveEntries(twi.typeList, "TwilightTypeListbutton", typeIndex, -2);	
			else
				typeIndex = typeIndex - 1;
				moveEntries(twi.typeList, "TwilightTypeListbutton", typeIndex, -1);
			end
		end
	end
	
	local function twi_OnKeyS()
		if(twi.itemList:IsShown() and typeSelected) then
			if(readingMerchant and itemIndex == getTableSize(merchantWares[typeSelected])) then
				return;
			elseif(not readingMerchant and itemIndex == getTableSize(inventory[typeSelected])) then
				return;
			end
			itemIndex = itemIndex + 1;
			moveEntries(twi.itemList, "TwilightItemListbutton", itemIndex, 1);
			
			updateItemButton();
			updateItemTooltip();
			updateBottomPanel();
		else
			if((typeIndex == getTableSize(inventory) and not MerchantFrame:IsShown()) or
				typeIndex == getTableSize(inventory)+getTableSize(merchantWares)+1 and MerchantFrame:IsShown()) then
				return;
			end
			
			if(_G["TwilightTypeListbutton"..typeIndex+1].texture:IsShown()) then
				typeIndex = typeIndex + 2;
				moveEntries(twi.typeList, "TwilightTypeListbutton", typeIndex, 2);	
			else
				typeIndex = typeIndex + 1;
				moveEntries(twi.typeList, "TwilightTypeListbutton", typeIndex, 1);
			end
		end
	end

	--------------------------------------
	--setting controls -> W, S, A, D
	--
	
	typeIndex, itemIndex = 1, 1;
	twi:SetScript("OnKeyUp", function(self, key)
		self.pressed = false;
		cancelTimer();
		
		if(frameMover:GetScript("OnUpdate")) then
			return;
		end
		
		if(TwilightStaticPopup:IsShown()) then
			if(key == "ESCAPE" or key == "Q") then
				TwilightStaticPopup:Hide();
			elseif(key == "ENTER") then
				twi.itemInfo.button:Click();
				DeleteCursorItem();
				TwilightStaticPopup:Hide();
			end
			return;
		end
		
		--close bags
		if(key == "ESCAPE" or key == "B" or key == "I") then
			if(key == "ESCAPE" and TwilightStaticPopup:IsShown()) then
				TwilightStaticPopup:Hide();
				return;
			end
			TwilightStaticPopup:Hide();
			ToggleAllBags();
			HideUIPanel(MerchantFrame);
		
			readingMerchant = false;
		
		--go next
		elseif(key == "D") then
			if(MerchantFrame:IsShown() and typeIndex <= getTableSize(merchantWares)) then
				readingMerchant = true;
			else
				readingMerchant = false;
			end
			typeSelected = _G["TwilightTypeListbutton"..typeIndex].text;
			twi.itemList:Show();
			updateItemListButtons();
			updateItemButton();
			updateItemTooltip();
			updateBottomPanel();
		
		--go back
		elseif(key == "A") then
			typeSelected = nil;
			itemIndex = 1;
			readingMerchant = false;
			
			hideItemList();
			
			--twi.itemList:Hide();
		
		--unequip an piece
		elseif(key == "R") then
			if(not twi.itemList:IsShown() or (typeSelected ~= "Weapon" and typeSelected ~= "Armor")) then
				return;
			end
			
			local itemTable = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
			
			PickupInventoryItem(itemTable.slotID);
			PickupContainerItem(getEmptySlotPosition());
			
		--buy item
		elseif(readingMerchant and key == "E") then
			local itemTable = merchantWares[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
			BuyMerchantItem(itemTable.slotID);
		
		
		
		elseif(not MerchantFrame:IsShown() and key == "Q") then
			--warns first (show popup)
			TwilightStaticPopup:Hide();
			TwilightStaticPopup.itemLink = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index].itemLink;
			TwilightStaticPopup:Show();
		
		
		--testing purposes
		elseif(key == "SPACE") then
			local itemTable = inventory[_G["TwilightTypeListbutton"..typeIndex].text][_G["TwilightItemListbutton"..itemIndex].index];
			print(itemTable.name, itemTable.bagID, itemTable.slotID, itemTable.actualSlotID);
		
		elseif(key == "ENTER") then
			print("-----------")
			print(twi:GetAlpha())
			print(twi.typeList:GetAlpha())
			print(twi.itemList:GetAlpha())
		
		
		elseif(key == "LSHIFT") then
			self:EnableKeyboard(true);
		end
		
	end);
	
	twi:SetScript("OnKeyDown", function(self, key)
		if(key == "LSHIFT") then
			self:EnableKeyboard(false);
		elseif(key == "S") then
			self.pressed = true;
			local function func()
				twi_OnKeyS();
				if(self.pressed) then
					createTimer(0.1, func)
				end
			end
			twi_OnKeyS();
			createTimer(0.35, func)
		elseif(key == "W") then
			self.pressed = true;
			local function func()
				twi_OnKeyW();
				if(self.pressed) then
					createTimer(0.1, func)
				end
			end
			twi_OnKeyW();
			createTimer(0.35, func)
		end
	end);
	
	
	--------------------------------------
	--ITEM INFO PANEL
	
	twi.itemInfo = CreateFrame("FRAME", "TwilightItemInfo", twi.itemList, "TwilightTooltip");
	twi.itemInfo:SetPoint("CENTER", WorldFrame, 290, -150);
	twi.itemInfo:SetFrameStrata("FULLSCREEN");
	
	
	twi.itemInfo.itemTexture = CreateFrame("BUTTON", "ItemButton", twi.itemInfo);
	twi.itemInfo.itemTexture:SetSize(128, 128);
	twi.itemInfo.itemTexture:SetPoint("TOP", 0, 200);
	twi.itemInfo.itemTexture:Show();
	
	twi.itemInfo.itemTexture:SetScript("OnClick", function(self, button)
		if(button == "LeftButton") then
			twi.itemInfo.button:Click();
		end
	end);
	
	twi.itemInfo.itemTexture:SetScript("OnEnter", function(self)
		if(IsAltKeyDown()) then
			GameTooltip:SetParent(WorldFrame);
			GameTooltip:SetFrameStrata("TOOLTIP");
			for i=1,3 do
				_G["ShoppingTooltip"..i]:SetParent(WorldFrame);
				_G["ShoppingTooltip"..i]:SetFrameStrata("TOOLTIP");
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			
			local btn = _G["TwilightItemInfoButton"];
			if(readingMerchant) then
				GameTooltip:SetMerchantItem(self.itemTable.slotID);
			elseif(self.itemTable.isEquipped) then
				GameTooltip:SetInventoryItem("player", self.itemTable.slotID);
			else
				GameTooltip:SetBagItem(btn:GetParent():GetID(), btn:GetID());
			end
		else
			ResetCursor();
		end
	end);
	
	twi.itemInfo.itemTexture:SetScript("OnLeave", function(self)
		GameTooltip:SetParent(UIParent);
		GameTooltip:SetFrameStrata("TOOLTIP");
		GameTooltip:Hide();
		for i=1,3 do
			_G["ShoppingTooltip"..i]:SetParent(UIParent);
			_G["ShoppingTooltip"..i]:SetFrameStrata("TOOLTIP");
		end
		ResetCursor();				
	end);
	
	--icon texture
	twi.itemInfo.itemTexture.iconTexture = twi.itemInfo.itemTexture:CreateTexture("ItemButtonIconTexture");
	twi.itemInfo.itemTexture.iconTexture:SetTexCoord(0.075,0.925,0.075,0.925);
	twi.itemInfo.itemTexture.iconTexture:SetSize(120,120);
	twi.itemInfo.itemTexture.iconTexture:SetPoint("CENTER");
	
	twi.itemInfo.itemTexture:SetBackdrop({--bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 14, edgeSize = 14,
		--insets = { left = 4, right = 4, top = 4, bottom = 4,
	});
	
	--stack size (important for merchant when they sell in packs)
	twi.itemInfo.itemTexture.stack = twi.itemInfo.itemTexture:CreateFontString();
	twi.itemInfo.itemTexture.stack:SetFontObject(SkyrimFontHighlighted);
	twi.itemInfo.itemTexture.stack:SetPoint("BOTTOMRIGHT", -2, 2);
	twi.itemInfo.itemTexture.stack:Hide();
	
	
	twi.itemInfo.button = CreateFrame("Button", "TwilightItemInfoButton", twi.itemInfo, "ContainerFrameItemButtonTemplate");
	twi.itemInfo.button:ClearAllPoints();
	
	--setting the buttons' names correctly when the player open the bags
	twi:SetScript("OnShow", function(self)
		updateItemTypeButtons();
	end);
	
	
	twi:SetScript("OnEvent", function(self, event, ...)
		if(event == "PLAYER_EQUIPMENT_CHANGED") then
			scanAll();
			
			updateItemListButtons();
		
		--when clicking on items that pop up a quest
		elseif(event == "QUEST_DETAIL") then
			hideInventory();
		elseif(event == "ACTIONBAR_SHOWGRID") then
			if(self:IsShown()) then
				self:SetFrameStrata("LOW");
				frameFade(UIParent, 0.2, 0, 0.6);
			end
		elseif(event == "ACTIONBAR_HIDEGRID") then
			if(self:IsShown()) then
				self:SetFrameStrata("FULLSCREEN");
				frameFade(UIParent, 0.2, UIParent:GetAlpha(), 0);
			end
		end
	end);
	
	twi:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	twi:RegisterEvent("QUEST_DETAIL");
	twi:RegisterEvent("ACTIONBAR_SHOWGRID");
	twi:RegisterEvent("ACTIONBAR_HIDEGRID");
	
end


--storing Blizz functions
local blizz_ToggleBackpack, blizz_ToggleAllBags = ToggleBackpack, ToggleAllBags;
function ToggleAllBags()
	if(Twilight:IsShown()) then
		hideInventory();
	else
		showInventory();
	end
end





Addon:SetScript("OnEvent", function(self, event, ...)
	if(event == "BAG_UPDATE") then
		scanAll();
		if(Twilight:IsShown() and Twilight.itemList:IsShown()) then
			updateItemTypeButtons();
			updateItemListButtons();
			updateItemButton();
			updateBottomPanel();
		end
	elseif(event == "MERCHANT_SHOW") then
		scanMerchant();
		
		--reset the position of item index and hide the itemList panel
		typeIndex = 1;	
		itemIndex = 1;
		Twilight.itemList:Hide(); --don't use the "hideItemList" is not needed
		Twilight.typeList.disabledFrame:Hide();
		
		--a timer is needed because we can't access the merchant wares before the scanning is complete
		self:SetScript("OnUpdate", function(self, elapsed)
			if(not isScanningMerchant) then
				updateItemTypeButtons();
				ToggleAllBags();
				self:SetScript("OnUpdate", nil);
			end
		end);

		
	elseif(event == "PLAYER_ENTERING_WORLD") then
		--for Bindings.xml
		BINDING_HEADER_TWILIGHT = "Twilight";
		_G["BINDING_NAME_CLICK TwilightItemInfoButton:RightButton"] = "Use item";
	
		setUpInventory();
		
		Addon:UnregisterEvent("PLAYER_ENTERING_WORLD");
		
		--this allows to init the blizzard bags. Then it's not necessary to remove alpha when accessing them.
		blizz_ToggleAllBags();
		blizz_ToggleAllBags();
		
		local total = 0;
		self:SetScript("OnUpdate", function(self, elapsed)
			total = total + elapsed;
			if(total > 0.01) then
				scanAll();
				self:RegisterEvent("BAG_UPDATE");
				self:SetScript("OnUpdate", nil);
			end
		end);
	elseif(event == "MERCHANT_CLOSED") then
		readingMerchant = false;
		hideInventory();
		
		--reset the position of item index and hide the itemList panel
		typeIndex = 1;	
		itemIndex = 1;
		Twilight.itemList:Hide(); --don't use the "hideItemList" is not needed
		Twilight.typeList.disabledFrame:Hide();
	end
end);

Addon:RegisterEvent("PLAYER_ENTERING_WORLD");
Addon:RegisterEvent("MERCHANT_SHOW");
Addon:RegisterEvent("MERCHANT_CLOSED");