surface.CreateFont("SODTotalTimeFont", {
	font = "Arial",
	extended = false,
	size = 22,
	weight = 500,
})

local SECONDS_IN_MINUTE = 60
local SECONDS_IN_HOUR = 3600
local SECONDS_IN_DAY = 86400

-- Credits to the person who made this blur panel function
-- https://gmod.facepunch.com/f/gmoddev/mtdf/I-need-help-making-a-blurred-derma-panel/1/
local matBlur = Material("pp/blurscreen")
local function BlurPanel(panel, layers, density, alpha)
	local x, y = panel:LocalToScreen(0, 0)

	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(matBlur)

	for i = 1, 3 do
		matBlur:SetFloat("$blur", (i / layers) * density)
		matBlur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
	end
end

local function menu(tblPlayerSODTimes)
	local frame = vgui.Create("DFrame")
	frame:SetSize(700, ScrH() - 50)
	frame:Center()
	frame:MakePopup()
	frame:SetTitle("SOD Timer")
	frame.Paint = function(self, w, h)
		BlurPanel(self, 10, 20, 255)
		draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 70, 120))
		draw.RoundedBox(4, 0, 0, w, 25, Color(51, 153, 255, 150))
	end

	local ClearTimesButton = vgui.Create("DButton", frame)
	ClearTimesButton:SetSize(frame:GetWide() - 20, 25)
	ClearTimesButton:SetPos(10, frame:GetTall() - 35)
	ClearTimesButton:SetText("Clear All Times")
	ClearTimesButton.DoClick = function()
		net.Start("SODClearTimes")
		net.SendToServer()
		frame:Remove()

		timer.Simple(1, function() RunConsoleCommand("sodtimer") end)
	end
	ClearTimesButton.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, Color(200, 200, 200, 255))
	end

	local SODTimesList = vgui.Create("DListView", frame)
	SODTimesList:SetSize(frame:GetWide() - 20, frame:GetTall() - 70)
	SODTimesList:SetPos(10, 30)
	SODTimesList:SetSortable(false)
	SODTimesList:AddColumn("Name")
	SODTimesList:AddColumn("Steam ID 64")
	SODTimesList:AddColumn("Rank")
	SODTimesList:AddColumn("Time")
	SODTimesList:AddColumn("Timestamp")
	SODTimesList:SetMultiSelect(false)
	SODTimesList.Paint = function(self, w, h) end

	for _, v in pairs(tblPlayerSODTimes) do
		local hourSeconds = v["sodtime"] % SECONDS_IN_DAY
		local minuteSeconds = hourSeconds % SECONDS_IN_HOUR
		local remainingSeconds = minuteSeconds  % SECONDS_IN_MINUTE

		local days = math.floor(v["sodtime"] / SECONDS_IN_DAY)
		local hours = math.floor(hourSeconds / SECONDS_IN_HOUR)
		local minutes = math.floor(minuteSeconds / SECONDS_IN_MINUTE)
		local seconds = math.ceil(remainingSeconds)

		local time = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)

		SODTimesList:AddLine(v["lastnick"], v["sid64"], v["lastrank"], time, v["sodtime"])
	end

	SODTimesList:SortByColumn(5, true)
end

net.Receive("SODOpenMenu", function()
	menu(net.ReadTable())
end)
