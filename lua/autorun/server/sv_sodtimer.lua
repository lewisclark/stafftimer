local SODTimer = {}

function SODTimer.Init()
	SODTimer.Team = TEAM_SOD	-- Set your staff on duty job here
	SODTimer.PlayersOnDuty = {}
	SODTimer.LoopDelay = 5

	sql.Query("CREATE TABLE IF NOT EXISTS sodtimer (sid64 varchar(30), lastnick varchar(50), lastrank varchar(20), sodtime int)")

	util.AddNetworkString("SODOpenMenu")
	util.AddNetworkString("SODClearTimes")

	timer.Create("SODTimer_HandleNewPlayersOnDuty", SODTimer.LoopDelay, 0, SODTimer.Loop)

	net.Receive("SODClearTimes", SODTimer.ClearTimes)

	hook.Add("PlayerInitialSpawn", "SODCreateNewUserFile", SODTimer.CreatePlayerRecord)
	hook.Add("PlayerDisconnected", "CheckIfWasSOD", SODTimer.PlayerDisconnected)
end
hook.Add("InitPostEntity", "SODTimer_Init", SODTimer.Init)

concommand.Add("sodtimer", function(ply)
	if (not IsValid(ply) or not ply:IsSuperAdmin()) then
		return
	end

	local result = sql.Query("SELECT * FROM sodtimer;")

	net.Start("SODOpenMenu")
		net.WriteTable(result)
	net.Send(ply)
end)

function SODTimer.Loop()
	for _, ply in ipairs(player.GetHumans()) do
		if (not ply:IsAdmin()) then
			continue
		end

		if (ply:Team() == SODTimer.Team and not SODTimer.PlayersOnDuty[ply]) then
			SODTimer.PlayersOnDuty[ply] = CurTime()
		elseif (ply:Team() ~= SODTimer.Team and SODTimer.PlayersOnDuty[ply]) then
			SODTimer.PlayersOnDuty[ply] = nil
		elseif (ply:Team() == SODTimer.Team and SODTimer.PlayersOnDuty[ply]) then
			sql.Query("UPDATE sodtimer SET sodtime = sodtime + '" .. math.floor(CurTime() - SODTimer.PlayersOnDuty[ply]) .. "' WHERE sid64 = '" .. ply:SteamID64() .. "';")

			SODTimer.PlayersOnDuty[ply] = CurTime()
		end
	end
end

function SODTimer.PlayerDisconnected(ply)
	if (SODTimer.PlayersOnDuty[ply]) then
		SODTimer.PlayersOnDuty[ply] = nil
	end
end

function SODTimer.CreatePlayerRecord(ply)
	if (ply:IsAdmin() and not SODTimer.PlayerRecordExists(ply:SteamID64())) then
		sql.Query("INSERT INTO sodtimer VALUES ('" .. ply:SteamID64() .. "', '" .. ply:Nick() .. "', '" .. ply:GetUserGroup() .. "', '0');")
	end
end

function SODTimer.ClearTimes(len, plyClearer)
	if (IsValid(plyClearer) and not plyClearer:IsSuperAdmin()) then
		return
	end

	sql.Query("DELETE FROM sodtimer;")
	table.Empty(SODTimer.PlayersOnDuty)

	for _, ply in ipairs(player.GetHumans()) do
		SODTimer.CreatePlayerRecord(ply)
	end

	RunConsoleCommand("ulx", "asay", plyClearer:Nick() .. " has reset the SOD timer!")
end

function SODTimer.PlayerRecordExists(sid64)
	local val = sql.QueryValue("SELECT sid64 FROM sodtimer WHERE sid64 = '" .. sid64 .. "';")

	return tobool(val)
end
