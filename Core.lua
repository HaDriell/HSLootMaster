-- WoW Namespace
local addonName, HSLootMaster = ...;

-- Globals
local HSLootMaster = LibStub("AceAddon-3.0"):NewAddon("HSLootMaster");

HSLootMasterLDB = LibStub("LibDataBroker-1.1"):NewDataObject("HSLootMaster", {
    type = "data source",
    text = "HSLootMaster",
    icon = "Interface\\AddOns\\HSLootMaster\\logo",
    OnClick = function ()
        HSLootMaster:ToggleDisplay();
    end
});

LibDBIcon = LibStub("LibDBIcon-1.0");

function HSLootMaster:OnInitialize()
    -- Init data broker
    self.DB = LibStub("AceDB-3.0"):New("HSLootMasterDB", {
        profile = {
            -- Defaults for LibDBIcon
            minimap = {
                hide = false
            },

            -- DB For Player loots history
            playerInfos = {
                -- List of PlayerInfos, empty by default
            },
        },
    });
    LibDBIcon:Register("HSLootMaster", HSLootMasterLDB, self.DB.profile.minimap);
    self:UpdateMinimapButton();
    AddonCompartmentFrame:RegisterAddon({
        text = "HSLootMaster",
        icon = "Interface\\AddOns\\HSLootMaster\\logo",
        notCheckable = true,
        func = function ()
            HSLootMaster:UpdateMinimapButton();
        end
    });
end

function HSLootMaster:UpdateMinimapButton()
    if (self.DB.profile.minimap.hide) then
        LibDBIcon:Hide("HSLootMaster");
    else
        LibDBIcon:Show("HSLootMaster");
    end
end

function HSLootMaster:ToggleDisplay()
    HSLM_LootHistoryFrame:SetShown(not HSLM_LootHistoryFrame:IsShown());
end

function HSLootMaster:GetPlayerInfos(unit)
    local playerInfos = self.DB.profile.playerInfos;
    local playerName, _ = UnitName(unit);

    return playerInfos[playerName];
end

function HSLootMaster:GetOrCreatePlayerInfos(unit)
    local record = self:GetPlayerInfos(unit);
    
    if not record then
        -- Create the Record if it doesn't exist
        local playerInfos = self.DB.profile.playerInfos;
        local playerName, _ = UnitName(unit);
        record = {
            name = playerName,
            loots = 0,
            transmogs = 0,
        };

        table.insert(playerInfos, record);
    end

    return record;
end

function HSLootMaster:GetRaidUnits()
    local list = {};

    for i = 1, MAX_RAID_MEMBERS do -- for each raid member
        local unit = format("%s%i", "raid", i); -- raid1, raid2, ..., raid40
        if UnitExists(unit) then
            table.insert(list, unit);
        end
    end

    return list;
end

------------
-- LootDelivery Functions
------------

function HSLootMaster:StartLootDelivery(lootHandle)
    -- TODO : announce /rw [LootName] début
    self:AddHandler("CHAT_MSG_SYSTEM", HandleChatMessageSystem);
    self:GetMainFrame():RegisterEvent("CHAT_MSG_SYSTEM");
end

function HSLootMaster:StopLootDelivery(lootHandle)
    self:GetMainFrame():UnregisterEvent("CHAT_MSG_SYSTEM");
    self:RemoveHandler("CHAT_MSG_SYSTEM", HandleChatMessageSystem);
    -- TODO : announce /rw [LootName] fin
end

function HSLootMaster:SetCurrentLoot(lootHandle)
    if HSLootMaster.CurrentLoot == lootHandle then
        return;
    end

    if HSLootMaster.CurrentLoot ~= nil then
        self:StopLootDelivery();
    end

    HSLootMaster.CurrentLoot = lootHandle;

    if HSLootMaster.CurrentLoot ~= nil then
        self:StartLootDelivery();
    end
end