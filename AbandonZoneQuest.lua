local QuestGroupsByName = {}
local buttonPool = CreateFramePool("Button", QuestMapFrame.QuestsFrame, "ZQA_AbandonButton")

local function Slug(value)
	return value:lower():gsub('[^a-z]', '')
end

local function PlaceButton(parent, offset, title, tooltip, slug)
	title = title or parent:GetText()
	tooltip = tooltip or title
	slug = slug or Slug(title)
	if QuestGroupsByName[slug] then
		local button = buttonPool:Acquire()
		button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offset, 0)
		button.title = title
		button.tooltip = tooltip
		button.slug = slug
		button:Show()
	end
end

local function ButtonsShow()
	buttonPool:ReleaseAll()
	for header in QuestScrollFrame.headerFramePool:EnumerateActive() do
		PlaceButton(header, 240)
	end
	for header in QuestScrollFrame.campaignHeaderFramePool:EnumerateActive() do
		PlaceButton(header.Text, 15)
	end
	
	-- TODO: Find a good place for this button
	-- PlaceButton(QuestMapFrame, -40, "your quest log", "All quests", "all")
end

local function AbandonQuests(slug)
	local group = QuestGroupsByName[slug] or {}
	for questId, title in pairs(group.quests or {}) do
		print("|cFFFFFF00Abandoned quest: '" .. title .. "'|r")
		C_QuestLog.SetSelectedQuest(questId)
		C_QuestLog.SetAbandonQuest();
		C_QuestLog.AbandonQuest();
	end
	QuestGroupsByName[slug] = nil
end

function ZQA_ButtonEnter(self)
	GameTooltip:SetOwner(self)
	GameTooltip:SetText(self.tooltip)
	GameTooltip:Show()
end

function ZQA_ButtonLeave(self)
	GameTooltip:Hide()
end

function ZQA_ButtonClick(self)
	local dialog = StaticPopup_Show ("ZQA_ABANDON_CONFIRMATION", self.title)
	if dialog then
		dialog.data = self.slug
	end
end

local function FillQuestGroups()
	local all = {quests={}}
	QuestGroupsByName = {all=all}
	local currentGroup
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)
		if info.isHeader then
			currentGroup = {
				title=info.title,
				hidden=true,
				quests={}
			}
			QuestGroupsByName[Slug(info.title)] = currentGroup
		else
			currentGroup.hidden = currentGroup.hidden and info.isHidden
			currentGroup.quests[info.questID] = info.title
			all.quests[info.questID] = info.title
		end
	end
end

StaticPopupDialogs["ZQA_ABANDON_CONFIRMATION"] = {
	text = "Are you sure you want to abandon all quests in %s?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function(self, data)
		AbandonQuests(data)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

SLASH_ABANDONZONE1 = "/abandonzone"
SlashCmdList["ABANDONZONE"] = function(zone)
	local slug = Slug(zone)
	if slug == "help" or zone == "" then
		print("|cFFFFFF00Type '/abandonzone' followed by the name of the zone you wish to abandon quests in, or type '/abandonzone all' to abandon all quests.|r")
	elseif not QuestGroupsByName[slug] then
		print("|cFFFFFF00Zone '".. zone.. "' not found|r")
	else
		AbandonQuests(slug)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(event, arg1)
	if event == "ADDON_LOADED" and arg1 ~= "AbandonZoneQuest" then
		return
	end
	FillQuestGroups()
end)

local function ButtonsHide()
	buttonPool:ReleaseAll()
end

QuestMapFrame:HookScript("OnShow", ButtonsShow)
QuestMapFrame:HookScript("OnEvent", ButtonsShow)
QuestMapFrame:HookScript("OnHide", ButtonsHide)