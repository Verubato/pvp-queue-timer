local frame = CreateFrame("Frame")
local dbDefaults = {
	Point = "TOP",
	RelativePoint = "TOP",
	X = 0,
	Y = -80,
}
local fontPath = "Fonts\\FRIZQT__.TTF"
local fontSize = 18
local fontFlags = "OUTLINE"
local paddingX = 12
local paddingY = 8
local updateInterval = 0.25
local elapsedSinceUpdate = 0
local draggable
local text

local function ApplyPosition()
	local db = PvPQueueTimerDB
	local point = db.Point or dbDefaults.Point
	local relativePoint = db.RelativePoint or dbDefaults.RelativePoint
	local x = (type(db.X) == "number") and db.X or dbDefaults.X
	local y = (type(db.Y) == "number") and db.Y or dbDefaults.Y

	draggable:ClearAllPoints()
	draggable:SetPoint(point, UIParent, relativePoint, x, y)
end

local function SavePosition()
	local point, _, relativePoint, x, y = draggable:GetPoint(1)
	PvPQueueTimerDB.Point = point
	PvPQueueTimerDB.RelativePoint = relativePoint
	PvPQueueTimerDB.X = x
	PvPQueueTimerDB.Y = y
end

local function ResizeDraggableToText()
	local w = text:GetStringWidth() or 0
	local h = text:GetStringHeight() or 0

	if w < 1 then
		w = 1
	end
	if h < 1 then
		h = 1
	end

	draggable:SetSize(w + paddingX * 2, h + paddingY * 2)
end

local function FormatTime(seconds)
	seconds = math.floor(seconds or 0)

	local m = math.floor(seconds / 60)
	local s = seconds % 60

	return string.format("%02d:%02d", m, s)
end

local function IsInPvPInstance()
	local inInstance, instanceType = IsInInstance()
	return inInstance and (instanceType == "pvp" or instanceType == "arena")
end

local function GetLongestPvPQueueElapsedSeconds()
	local maxSecs = nil
	local maxQueues = MAX_BATTLEFIELD_QUEUES or 3

	for i = 1, maxQueues do
		local status = GetBattlefieldStatus(i)
		if status == "queued" or status == "confirm" then
			local ms = GetBattlefieldTimeWaited(i)

			if type(ms) == "number" and ms > 0 then
				local secs = ms / 1000

				if (not maxSecs) or secs > maxSecs then
					maxSecs = secs
				end
			end
		end
	end

	return maxSecs
end

local function UpdateDisplay()
	if IsInPvPInstance() then
		text:SetText("")
		text:Hide()
		return
	end

	local secs = GetLongestPvPQueueElapsedSeconds()
	if secs then
		text:SetText("Time in Queue: " .. FormatTime(secs))
		text:Show()

		ResizeDraggableToText()
	else
		text:SetText("")
		text:Hide()
	end
end

PvPQueueTimerDB = PvPQueueTimerDB or {}

draggable = CreateFrame("Frame", nil, UIParent)
draggable:SetClampedToScreen(true)
draggable:EnableMouse(true)
draggable:SetMovable(true)
draggable:RegisterForDrag("LeftButton")

draggable:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

draggable:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	SavePosition()
end)

text = draggable:CreateFontString(nil, "OVERLAY")
text:SetFont(fontPath, fontSize, fontFlags)
text:SetPoint("CENTER", draggable, "CENTER", 0, 0)
text:SetText("")
text:Hide()

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
frame:RegisterEvent("PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		ApplyPosition()
	end

	UpdateDisplay()
end)

frame:SetScript("OnUpdate", function(_, delta)
	if IsInPvPInstance() then
		return
	end

	elapsedSinceUpdate = elapsedSinceUpdate + delta

	if elapsedSinceUpdate >= updateInterval then
		elapsedSinceUpdate = 0
		UpdateDisplay()
	end
end)
