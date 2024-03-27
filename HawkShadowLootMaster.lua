assert(LibStub, "HawkShadowLootMaster requires LibStub");

local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1");
assert(LibDataBroker, "HawkShadowLootMaster requires LibDataBroker-1.1");

local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0");
assert(LibDBIcon, "HawkShadowLootMaster requires LibDBIcon-1.0");

local AceDB = LibStub:GetLibrary("AceDB-3.0");
assert(AceDB, "HawkShadowLootMaster requires AceDB-3.0");

local AceAddon = LibStub:GetLibrary("AceAddon-3.0");
assert(AceAddon, "HawkShadowLootMaster requires AceAddon-3.0");

local HawkShadowLootMaster = AceAddon:NewAddon("HawkShadowLootMaster"
	, "AceConsole-3.0"
	, "AceEvent-3.0"
);

function HawkShadowLootMaster:OnInitialize()
	self:InitializeDatabase();
	self:InitializeMinimapButton();
	self:InitializeFrames();
end

function HawkShadowLootMaster:InitializeDatabase()
	local defaults = {
		profile = {
			-- LibDBIcon wants that
			minimap = {
				hide = false,
			},
		},

		global = {
			-- ConfigurationFrame variables
			configuration = {
				rollDuration = 60,
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

function HawkShadowLootMaster:InitializeFrames()
	self.ConfigurationFrame = CreateFrame("Frame", nil, UIParent, "HSLM_ConfigurationFrame");
	self.ConfigurationFrame:Hide();
	
	self.LootFrame = nil; -- TODO : Create the frame XML for that
end

function HawkShadowLootMaster:ToggleConfigurationFrame()
	if self.ConfigurationFrame:IsShown() then
		self.ConfigurationFrame:Hide();
	else
		self.ConfigurationFrame:Show();
	end
end

function HawkShadowLootMaster:OnMinimapButtonPressed(dataObject, button)
	if button == "LeftButton" then
		self:ToggleConfigurationFrame();
	end

	if button == "RightButton" then
		self:Print("Clicked with Right Button");
	end
end

function HawkShadowLootMaster:GetDB()
	return self.db;
end


-- TODO : use that for automatic trading with a winner
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
