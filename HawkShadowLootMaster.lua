assert(LibStub, "HawkShadowLootMaster requires LibStub");

local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1");
assert(LibDataBroker, "HawkShadowLootMaster requires LibDataBroker-1.1");

local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0");
assert(LibDBIcon, "HawkShadowLootMaster requires LibDBIcon-1.0");

local AceDB = LibStub:GetLibrary("AceDB-3.0");
assert(AceDB, "HawkShadowLootMaster requires AceDB-3.0");

local HawkShadowLootMaster = LibStub("AceAddon-3.0"):NewAddon("HawkShadowLootMaster"
	, "AceConsole-3.0"
	, "AceEvent-3.0"
);

function HawkShadowLootMaster:OnInitialize()
	self:InitializeFrames();
	self:InitializeDatabase();
	self:InitializeMinimapButton();
end

function HawkShadowLootMaster:InitializeFrames()
	self.ConfigurationFrame = CreateFrame("HSLM_ConfigurationFrame", "HSLM_ConfigurationFrame", UIParent);
end

function HawkShadowLootMaster:InitializeDatabase()
	local defaults = {
		profile = {

			-- LibDBIcon wants that
			minimap = {
				hide = false,
			},

			-- Roll distribution options
			rolls = {
				duration = 60,
			},

			loots = {
				-- ItemReference (whatever that can link to the item in inventory)
				-- LootStatus (is the loot already distributed)
				-- Looter (name of the player that looted the item)
			},

			history = {
				-- List of { Player, LootCount }
			},
		},
	};
	self.db = AceDB:New("HawkShadowLootMasterDB", defaults);
end

function HawkShadowLootMaster:InitializeMinimapButton()
	local dataObject = LibDataBroker:NewDataObject("HawkShadowLootMaster", {
		type = "data source",
		text = "HawkShadowLootMaster",
		icon = "Interface/AddOns/HawkShadowLootMaster/logo",
		OnClick = function(...) HawkShadowLootMaster:OnMinimapButtonPressed(...); end
	});

	LibDBIcon:Register("HawkShadowLootMaster", dataObject, self.db.profile.minimap);
end

function HawkShadowLootMaster:OnMinimapButtonPressed(dataObject, button)
	if button == "LeftButton" then
		self:Print("Clicked with Left Button");

		if not TradeFrame:IsShown() then
			InitiateTrade("raid1");
		else
			-- TODO : Abstract in function please
			local found = false;
			for bag = 0, 4 do
				local slots = C_Container.GetContainerNumSlots(bag);
				for slot = 1, slots do
					local item = C_Container.GetContainerItemLink(bag, slot);
					if item and item:find("Rune sifflante") then
						C_Container.UseContainerItem(bag, slot);
						found = true;
					end
					if found then break; end
				end
				if found then break; end
			end
			self:Print("Found : ", found);
		end

	end
	
	if button == "RightButton" then
		self:Print("Clicked with Right Button");
	end
end

function HawkShadowLootMaster:TradeItemWith(unitID, itemName)
	if not TradeFrame:IsShown() then
		InitiateTrade(unitID);
	else
		local found = false;
		for bag = 0, 4 do

			local slots = C_Container.GetContainerNumSlots(bag);
			for slot = 1, slots do

				local item = C_Container.GetContainerItemLink(bag, slot);
				found = item and item:find(itemName);

				if found then
					C_Container.UseContainerItem(bag, slot);
					break;
				end
			end

			if found then
				break;
			end
		end
	end
end
