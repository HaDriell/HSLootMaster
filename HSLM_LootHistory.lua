-- Hawk Shadow Loot Master's Element Mixin

HSLM_ElementMixin = {};

local HSLM_ElementEvents =
{
    "CHAT_MSG_SYSTEM",
};

function HSLM_ElementMixin:OnLoad()
    self.Item.IconBorder:SetSize(self.Item:GetWidth(), self.Item:GetHeight());
    FrameUtil.RegisterFrameForEvents(self, HSLM_ElementEvents);
end

function HSLM_ElementMixin:OnEnter()
    self:SetTooltip();
end

function HSLM_ElementMixin:OnLeave()
    GameTooltip:Hide();
end

function HSLM_ElementMixin:SetTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -6);

    local item = Item:CreateFromItemLink(self.dropInfo.itemHyperlink);
    local itemQuality = item:GetItemQuality();
    local qualityColor = ITEM_QUALITY_COLORS[itemQuality].color;

    GameTooltip_SetTitle(GameTooltip, qualityColor:WrapTextInColorCode(item:GetItemName()));
    GameTooltip:Show();
end

function HSLM_ElementMixin:Init(dropInfo)
    self.dropInfo = dropInfo;

    local item = Item:CreateFromItemLink(self.dropInfo.itemHyperlink);
    local itemQuality = item:GetItemQuality();
    local qualityColor = ITEM_QUALITY_COLORS[itemQuality].color;

    self.ItemName:SetText(item:GetItemName());
    self.ItemName:SetVertexColor(qualityColor:GetRGB());
    SetItemButtonQuality(self.Item, itemQuality, dropInfo.itemHyperlink);
    self.Item.icon:SetTexture(item:GetItemIcon());

    self.Item:SetScript("OnClick", function (button, buttonName, down)
        if IsModifiedClick() then
            HandleModifiedItemClick(dropInfo.itemHyperlink);
        end
    end);

    self.Item:SetScript("OnEnter", function ()
        GameTooltip:SetOwner(self.Item, "ANCHOR_RIGHT");
        GameTooltip:SetHyperlink(dropInfo.itemHyperlink);
    end);

    self.Item:SetScript("OnLeave", function ()
        GameTooltip:Hide();
    end);

    if self:IsMouseMotionFocus() then
        self:SetTooltip();
    end
end

function HSLM_ElementMixin:OnEvent(event, ...)
    if event == "CHAT_MSG_SYSTEM" then
        self:HandleChatMessageSystem(...);
    end
end

function HSLM_ElementMixin:HandleChatMessageSystem(text, ...)
    -- Attempt to parse a /rand message from any player
    local _, _, playerName, rollValue, rollMin, rollMax = string.find(text, "(%a+) .* (%d+) %((%d+)%-(%d+)%)");
    
    if not playerName or not rollValue or not rollMin or not rollMax then
        return -- Not a valid /rand message
    end

    -- TODO : Check if this Element is the active Loot here
end

function HSLM_ElementMixin:SetDrop(encounterID, lootListID)
    self.encounterID = encounterID;
    self.lootListID = lootListID;

    local dropInfo = C_LootHistory.GetSortedInfoForDrop(self.encounterID, self.lootListID);
    self:Init(dropInfo);
end

function HSLM_ElementMixin:OnShow()
    FrameUtil.RegisterFrameForEvents(self, HSLM_ElementEvents);
end

function HSLM_ElementMixin:OnHide()
    FrameUtil.UnregisterFrameForEvents(self, HSLM_ElementEvents);
end

-- Hawk Shadow Loot Master's Loot Frame Mixin

HSLM_LootHistoryFrameMixin = {};

local HSLM_LootHistoryFrameAlwaysListenEvents =
{
    "LOOT_HISTORY_CLEAR_HISTORY",
};

local HSLM_LootHistoryFrameWhenShownEvents =
{
    "LOOT_HISTORY_UPDATE_ENCOUNTER",
};

function HSLM_LootHistoryFrameMixin:OnLoad()
    FrameUtil.RegisterFrameForEvents(self, HSLM_LootHistoryFrameAlwaysListenEvents);
    self:InitRegions();
    self:InitScrollBox();
end

function HSLM_LootHistoryFrameMixin:OnShow()
    FrameUtil.RegisterFrameForEvents(self, HSLM_LootHistoryFrameWhenShownEvents);

    self:SetupEncounterDropDown();

    if not self.selectedEncounterID then
        local encounters = C_LootHistory.GetAllEncounterInfos();
        local firstEncounter = encounters[1];
        if firstEncounter then
            self:OpenToEncounter(firstEncounter.encounterID);
        else
            self:SetInfoShown(false);
        end
    end
end

function HSLM_LootHistoryFrameMixin:OnHide()
    FrameUtil.UnregisterFrameForEvents(self, HSLM_LootHistoryFrameWhenShownEvents);

    self.ScrollBox:RemoveDataProvider();
    self.selectedEncounterID = nil;
end

function HSLM_LootHistoryFrameMixin:OnEvent(event, ...)
    if event == "LOOT_HISTORY_UPDATE_ENCOUNTER" then
        local encounterID = ...;
        if encounterID == self.selectedEncounterID then
            self:DoFullRefresh();
        end
    elseif event == "LOOT_HISTORY_CLEAR_HISTORY" then
        self:SetInfoShown(false);
        self.selectedEncounterID = nil;
        self.encounterInfo = nil;
    end
end

function HSLM_LootHistoryFrameMixin:OnDragStart()
    self:StartMoving();
end

function HSLM_LootHistoryFrameMixin:OnDragStop()
    self:StopMovingOrSizing();
end

local ScrollBoxPad = 7;
local ScrollBoxSpacing = 8;
function HSLM_LootHistoryFrameMixin:InitScrollBox()
    local view = CreateScrollBoxListLinearView(ScrollBoxPad, ScrollBoxPad, ScrollBoxPad, ScrollBoxPad, ScrollBoxSpacing);

    local function Initializer(frame, elementData)
        frame:SetDrop(self.selectedEncounterID, elementData.lootListID);
    end

    view:SetElementFactory(function(factory, elementData)
        if elementData.lootListID then
            factory("HSLM_LootHistoryElementTemplate", Initializer);
        end
    end);

    view:SetElementExtentCalculator(function(dataIndex, elementData)
        if elementData.lootListID then
            return 58;
        end
    end);

    ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view);
end

function HSLM_LootHistoryFrameMixin:InitRegions()
    self.ResizeButton:SetScript("OnMouseDown", function ()
        local alwaysStartFromMouse = true;
        self:StartSizing("BOTTOM", alwaysStartFromMouse);
    end);
    self.ResizeButton:SetScript("OnMouseUp", function ()
        self:StopMovingOrSizing();
    end);

    self.TitleContainer.TitleText:SetText("Hawk Shadow Loot Master");
end

function HSLM_LootHistoryFrameMixin:SetupEncounterDropDown()
    local function Initializer(dropDown, level)
        local function DropDownButtonClick(button)
            self:OpenToEncounter(button.value);
        end

        local encounters = C_LootHistory.GetAllEncounterInfos();

        for _, encounter in ipairs(encounters) do
            local info = UIDropDownMenu_CreateInfo();
            info.fontObject = GameFontHighlightSmall;
            info.text = encounter.encounterName;
            info.minWidth = 236;
            info.value = encounter.encounterID;
            info.func = DropDownButtonClick;
            UIDropDownMenu_AddButton(info);
        end
    end

    local totalWidth = 239;
    local dropDownEdgeWidth = 16;
    UIDropDownMenu_SetWidth(self.EncounterDropDown, totalWidth - dropDownEdgeWidth);
    UIDropDownMenu_JustifyText(self.EncounterDropDown, "RIGHT");
    UIDropDownMenu_Initialize(self.EncounterDropDown, Initializer);
end

function HSLM_LootHistoryFrameMixin:SetInfoShown(shown)
    self.ScrollBox:SetShown(shown);
    self.ScrollBar:SetShown(shown);
    self.EncounterDropDown:SetShown(shown);

    self.NoInfoString:SetShown(not shown);
end


function HSLM_LootHistoryFrameMixin:OpenToEncounter(encounterID)
    self:SetInfoShown(true);
    self.selectedEncounterID = encounterID;
    UIDropDownMenu_SetSelectedValue(self.EncounterDropDown, encounterID);
    self:DoFullRefresh();
end

function HSLM_LootHistoryFrameMixin:DoFullRefresh()
	self.encounterInfo = C_LootHistory.GetInfoForEncounter(self.selectedEncounterID);

	local dataProvider = CreateDataProvider();
	local drops = C_LootHistory.GetSortedDropsForEncounter(self.selectedEncounterID);
	local anyNotPassed = false;
	local passedHeaderAdded = false;

    for _, dropInfo in ipairs(drops) do
		if dropInfo.playerRollState == Enum.EncounterLootDropRollState.Pass and not passedHeaderAdded then
			if anyNotPassed then
				dataProvider:Insert({isPassedSpacer = true});
			end
			dataProvider:Insert({isPassedHeader = true});
			passedHeaderAdded = true;
		elseif dropInfo.playerRollState ~= Enum.EncounterLootDropRollState.Pass then
			anyNotPassed = true;
		end

		dataProvider:Insert({encounterID = self.selectedEncounterID, lootListID = dropInfo.lootListID});
	end

	self.ScrollBox:SetDataProvider(dataProvider);
end