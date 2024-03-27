assert(LibStub, "HawkShadowLootMaster requires LibStub");

local AceAddon = LibStub:GetLibrary("AceAddon-3.0");
assert(AceAddon, "HawkShadowLootMaster requires AceAddon-3.0");

HSLM_ConfigurationFrameMixin = {};

function HSLM_ConfigurationFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
end

function HSLM_ConfigurationFrameMixin:OnShow()
    local HawkShadowLootMaster = AceAddon:GetAddon("HawkShadowLootMaster");
    HawkShadowLootMaster:Print("Showing HSLM_ConfigurationFrame");
    local rollDuration = HawkShadowLootMaster.db.global.configuration.rollDuration;
end

function HSLM_ConfigurationFrameMixin:OnDragStart()
    self:StartMoving();
end

function HSLM_ConfigurationFrameMixin:OnDragStop()
    self:StopMovingOrSizing();
end