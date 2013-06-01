--
-- 海鳗插件：战场/竞技场助手、九宫报时助手
--

HM_Battle = {
	bFormArean = true,		-- 在竞技场自动交出阵眼
	bAlarmJG2 = false,		-- 九宫自动报时
	bMarkMap = true,		-- 战场地图方向标记
	bArenaAward = true,	-- 下周可得名剑币估算
	bAutoBattle= true,		-- 自动进入战场
	bAutoArena = true,		-- 自动进入竞技场
}
HM.RegisterCustomData("HM_Battle")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Battle = {
	bBeginJG = false,
	nTimeJG = 180,
}

-- middle map replace
_HM_Battle.ShowMap = MiddleMap.ShowMap
MiddleMap.ShowMap = function(frame, dwMapID, nIndex)
    _HM_Battle.ShowMap(frame, dwMapID, nIndex)
    local dwMapID, hTotal = MiddleMap.dwMapID, frame:Lookup("", "")
    local ui = HM.UI(hTotal, "Handle_MapEx")
    if HM_Battle.bMarkMap and (dwMapID == 48 or dwMapID == 50 or dwMapID == 135) and not ui then
        ui = HM.UI.Append(hTotal, "Handle2", "Handle_MapEx", { x = 0, y = 0 })
        hTotal:FormatAllItemPos()
    end
    if ui then
        local fS = 0.9 / (Station.GetUIScale() / Station.GetMaxUIScale())
        ui:Raw():Clear()
        if dwMapID == 48 and HM_Battle.bMarkMap then
            ui:Append("Text", { txt = _L["Northwest"], font = 199, x = 420 * fS, y = 320 * fS })
            ui:Append("Text", { txt = _L["Northeast"], font = 199, x = 730 * fS, y = 320 * fS })
            ui:Append("Text", { txt = _L["Southwest"], font = 199, x = 430 * fS, y = 670 * fS })
            ui:Append("Text", { txt = _L["Southeast"], font = 199, x = 735 * fS, y = 670 * fS })
            ui:Append("Text", { txt = _L["Center"], font = 199, x = 545 * fS, y = 500 * fS })
            ui:Raw():FormatAllItemPos()
        elseif dwMapID == 50 and HM_Battle.bMarkMap then
            ui:Append("Text", { txt = _L["East"], font = 199, x = 710 * fS, y = 500 * fS })
            ui:Append("Text", { txt = _L["South"], font = 199, x = 570 * fS, y = 690 * fS })
            ui:Append("Text", { txt = _L["West"], font = 199, x = 415 * fS, y = 520 * fS })
            ui:Append("Text", { txt = _L["North"], font = 199, x = 605 * fS, y = 315 * fS })
            ui:Append("Text", { txt = _L["Center"], font = 199, x = 560 * fS, y = 480 * fS })
            ui:Raw():FormatAllItemPos()
        elseif dwMapID == 135 and HM_Battle.bMarkMap then
            ui:Append("Text", { txt = _L["East"], font = 199, x = 725 * fS, y = 490 * fS })
            ui:Append("Text", { txt = _L["South"], font = 199, x = 510 * fS, y = 650 * fS })
            ui:Append("Text", { txt = _L["West"], font = 199, x = 385 * fS, y = 465 * fS })
            ui:Append("Text", { txt = _L["North"], font = 199, x = 605 * fS, y = 325 * fS })
            ui:Append("Text", { txt = _L["Center"], font = 199, x = 580 * fS, y = 460 * fS })
            ui:Raw():FormatAllItemPos()
        end
    end
end

---------------------------------------------------------------------
-- 九宫战场报时助手
---------------------------------------------------------------------
-- count alarm frames
_HM_Battle.GetAutoFrame = function(nEnd)
	return { nEnd - 1920, nEnd - 1440, nEnd - 960, nEnd - 480, nEnd - 320, nEnd - 160, nEnd - 80 }
end

-- alarm 9g box
_HM_Battle.AlarmJG = function()
	if not _HM_Battle.bBeginJG then
		return HM.Sysmsg(_L["You are not in JIUGONG battlefield"])
	end
	if not _HM_Battle.nFrameJG1 and not _HM_Battle.nFrameJG2 then
		return HM.Sysmsg(_L["No chest will be appeared"])
	end
	local nFrame = GetLogicFrameCount()
	for i = 1, 2 do
		local nNext = _HM_Battle["nFrameJG" .. i]
		if nNext then
			local _, nMin, nSec = GetTimeToHourMinuteSecond(nNext - nFrame, true)
			local szMsg = _L("No.%d chest will appear after ", i)
			if nMin > 0 then
				szMsg = szMsg .. nMin .. _L["min "]
			end
			if nSec > 0 then
				szMsg = szMsg .. nSec .. _L["sec"]
			end
			szMsg = szMsg .. _L[", attention plz!"]
			HM.Talk(PLAYER_TALK_CHANNEL.RAID, szMsg)
		end
	end
end

-- breathe 9g box
_HM_Battle.BreatheJG = function()
	local nFrame = GetLogicFrameCount()
	for i = 1, 2 do
		local nEnd = _HM_Battle["nFrameJG" .. i]
		if nEnd and nEnd > nFrame then
			local bAlarm, tFrame, nFrame2 = false, _HM_Battle["tFrameJG" .. i], nFrame
			while tFrame[1] and tFrame[1] <= nFrame do
				nFrame2 = table.remove(tFrame, 1)
				bAlarm = true
			end
			if bAlarm and HM_Battle.bAlarmJG2 then
				local _, nMin, nSec = GetTimeToHourMinuteSecond(nEnd - nFrame2, true)
				local szMsg = _L("No.%d chest will appear after ", i)
				if nMin > 0 then szMsg = szMsg .. nMin .. _L["min "] end
				if nSec > 0 then szMsg = szMsg .. nSec .. _L["sec"] end
				szMsg = szMsg .. _L[", attention plz!"]
				HM.Talk(PLAYER_TALK_CHANNEL.RAID, szMsg)
			end
		else
			_HM_Battle["nFrameJG" .. i] = nil
			_HM_Battle["tFrameJG" .. i] = nil
		end
	end
end

-- enter 9g map
_HM_Battle.BeginJG = function()
	local me = GetClientPlayer()
	if me and me.GetScene().dwMapID == 48 then
		_HM_Battle.nFrameJG1 = nil
		_HM_Battle.tFrameJG1 = nil
		_HM_Battle.nFrameJG2 = nil
		_HM_Battle.tFrameJG2 = nil
		_HM_Battle.bBeginJG = true
		HM.BreatheCall("HM_Battle_JG", _HM_Battle.BreatheJG, 1000)
		RegisterMsgMonitor(_HM_Battle.MonitorJG, {"MSG_SYS"})
	else
		_HM_Battle.bBeginJG = false
		HM.BreatheCall("HM_Battle_JG", nil)
		UnRegisterMsgMonitor(_HM_Battle.MonitorJG, {"MSG_SYS"})
	end
end

-- check 9g box
_HM_Battle.MonitorJG = function(szMsg)
	if _HM_Battle.bBeginJG and StringFindW(szMsg, _L["got ZHENLONG chest"]) then
		local _, _, nBeginTime, nEndTime = GetBattleFieldPQInfo()
		local nCurrentTime = GetCurrentTime()
		if nEndTime - nCurrentTime < _HM_Battle.nTimeJG then
			return
		end
		local nFrame = GetLogicFrameCount()
		if not _HM_Battle.nFrameJG1 then
			_HM_Battle.nFrameJG1 = nFrame + _HM_Battle.nTimeJG * GLOBAL.GAME_FPS
			_HM_Battle.tFrameJG1 = _HM_Battle.GetAutoFrame(_HM_Battle.nFrameJG1)
		elseif not _HM_Battle.nFrameJG2 then
			_HM_Battle.nFrameJG2 = nFrame + _HM_Battle.nTimeJG * GLOBAL.GAME_FPS
			_HM_Battle.tFrameJG2 = _HM_Battle.GetAutoFrame(_HM_Battle.nFrameJG2)
		end
	end
end

-------------------------------------
-- 下周可得名剑币估算（暂不可用）
-------------------------------------
-- calc arean point
_HM_Battle.CountArenaAward = function(tData)
	local nAward = -1
	for k, v in pairs(tData) do
		local nTeamCount, nPlayerCount = tData[k]["dwCorpsCount"], tData[k]["dwPersonCount"]
		local nTeamLv, nPlayerLv = tData[k]["nCorpsLevel"], tData[k]["nPersonLevel"]
		local nPoint = 0
		if nTeamCount >= 10 and (nPlayerCount / nTeamCount) >= 0.3 then
			local nRaceLevel, fS = nPlayerLv, 1
			if (nTeamLv - nPlayerLv) <= 200 then
				nRaceLevel = nTeamLv
			end
			if k == 0 then
				fS = 0.8
			elseif k == 1 then
				fS = 0.9
			end
			if nRaceLevel < 800 then
				nPoint = fS * 4 * (650 * nRaceLevel + 2337500) / 10000
			elseif nRaceLevel < 3100 then
				nPoint = fS * 4 * (1238400 * (nRaceLevel - 1900) / ((nRaceLevel - 1900) ^ 2 + 1440000) + 800)
			else
				nPoint = fS * 4 * (195 * nRaceLevel + 12555500) / 10000
			end
			nPoint = math.floor(nPoint)
		end
		if nPoint > nAward then
			nAward = nPoint
		end
	end
	return nAward
end

-- show next week count
_HM_Battle.ShowNextArenaAward = function()
	local frame = Station.Lookup("Normal/ArenaCorpsPanel")
	if frame and frame:IsVisible() then
		local tData = _HM_Battle.tCorpsData or {}
		local nPoint = _HM_Battle.CountArenaAward(tData)
		local hText = frame:Lookup("", "Text_Currency")
		local szText = _L["Next week = "] .. nPoint
		local me = GetClientPlayer()
		if _HM_Battle.dwAreanID == me.dwID then
			szText = FormatString(g_tStrings.STR_AREAN_AWARD, me.nArenaAward) .. " (" .. szText .. ")"
		end
		hText:SetText(szText)
		hText:Show()
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
-- open arena panel
_HM_Battle.OnSyncArenaList = function()
	if HM_Battle.bArenaAward and GetCorpsInfo then
		local dwAreanID, nCorps = arg0, 0
		local tar = GetPlayer(dwAreanID)
		if tar then
			for i = 0, 2, 1 do
				if GetCorpsID(i, dwAreanID) ~= 0 then
					nCorps = nCorps + 1
				end
			end
			_HM_Battle.szAreaName = string.gsub(tar.szName, "@.*$", "")
			_HM_Battle.dwAreanID, _HM_Battle.nCorps, _HM_Battle.tCorpsData = dwAreanID, nCorps, {}
		end
	end
end

-- sync arena data
_HM_Battle.OnSyncArenaData = function()
	local dwCorpsID, nCorpsType, dwPeekPlayerID, bRank = arg0, arg1, arg2, arg3
	if bRank == 1 or dwPeekPlayerID ~= _HM_Battle.dwAreanID or _HM_Battle.tCorpsData[nCorpsType] ~= nil then
		return
	end
	local tMemberInfo = GetCorpsMemberInfo(dwCorpsID, false)
	if not tMemberInfo then
		SyncCorpsMemberData(dwCorpsID, false, _HM_Battle.dwAreanID)
	else
		local tData, tCorpsInfo = {}, GetCorpsInfo(dwCorpsID, false)
		tData.dwCorpsCount = tCorpsInfo.dwWeekTotalCount
		tData.nCorpsLevel = tCorpsInfo.nCorpsLevel
		for i = 1, tCorpsInfo.nMemberCount do
			if string.gsub(tMemberInfo[i].szPlayerName, "@.*$", "") == _HM_Battle.szAreaName  then
				tData.dwPersonCount = tMemberInfo[i].dwWeekTotalCount
				tData.nPersonLevel = tMemberInfo[i].nGrowupLevel
				break
			end
		end
		_HM_Battle.tCorpsData[nCorpsType] = tData
		_HM_Battle.nCorps = _HM_Battle.nCorps - 1
		if _HM_Battle.nCorps <= 0 then
			_HM_Battle.ShowNextArenaAward()
		end
	end
end

-- check formdation
_HM_Battle.OnShiftForm = function()
	local me, team = GetClientPlayer(), GetClientTeam()
	if me.IsInParty() and IsInArena() then
		local nGroup = team.GetMemberGroupIndex(me.dwID)
		local tGroupInfo = team.GetGroupInfo(nGroup)
		if tGroupInfo.dwFormationLeader == me.dwID then
			local tarID = nil
			for _, dwID in pairs(tGroupInfo.MemberList) do
				local info = team.GetMemberInfo(dwID)
				if info.bIsOnLine and dwID ~= me.dwID and not info.bDeathFlag then
					tarID = dwID
					if info.dwMountKungfuID ~= 10080
						and info.dwMountKungfuID ~= 10028
						and info.dwMountKungfuID ~= 10176
					then
						break
					end
				end
			end
			if tarID then
				team.SetTeamFormationLeader(tarID, nGroup)
				HM.Sysmsg(_L("Auto set [%s] as formation leader for my death", team.GetClientTeamMemberName(tarID)))
			end
		end
	end
end

-- my death
_HM_Battle.OnSysMsg = function()
	if arg0 == "UI_OME_DEATH_NOTIFY" then
		if arg1 == GetClientPlayer().dwID and HM_Battle.bFormArean then
			_HM_Battle.OnShiftForm()
		end
	end
end

-- join battle
_HM_Battle.OnBattleNotify = function()
	if HM_Battle.bAutoBattle and arg0 == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
		DoAcceptJoinBattleField(arg5, arg3, arg4, arg6, arg7)
	end
end

-- join arena
_HM_Battle.OnAreanNotify = function()
	if HM_Battle.bAutoArena and arg0 == ARENA_NOTIFY_TYPE.LOG_IN_ARENA_MAP then
		DoAcceptJoinArena(arg1, arg7, arg5, arg6, arg8, arg9, arg2)
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Battle.PS = {}

-- init panel
_HM_Battle.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	-- auto
	ui:Append("Text", { txt = _L["Options"], x = 0, y = 0, font = 27})
	ui:Append("WndCheckBox", { txt = _L["Auto set formation leader after death in arean"], x = 10, y = 28, checked = HM_Battle.bFormArean })
	:Click(function(bChecked)
		HM_Battle.bFormArean = bChecked
	end)
	-- 9g
	ui:Append("Text", { txt = _L["JIUGONG chest timer"], x = 0, y = 64, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 92, checked = HM_Battle.bAlarmJG2 })
	:Text(_L["Auto broadcast in battle channel (1min/30s/10s)"]):Click(function(bChecked)
		HM_Battle.bAlarmJG2 = bChecked
	end)
	local nX = ui:Append("WndButton", { x= 10, y = 122 })
	:Text(_L["Manual show"] .. HM.GetHotKey("AlarmJG", true, true)):AutoSize(8):Click(_HM_Battle.AlarmJG):Pos_()
	ui:Append("Text", { txt = _L["Set hotkeys"], x = nX + 5, y = 120 }):Click(HM.SetHotKey)
	-- mark middle map
	ui:Append("Text", { txt = _L["Others"], x = 0, y = 158, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 186, checked = HM_Battle.bMarkMap })
	:Text(_L["Show the orientation of some battlefield maps (newbie necessary)"]):Click(function(bChecked)
		HM_Battle.bMarkMap = bChecked
	end)
	ui:Append("WndCheckBox", { x = 10, y = 214, checked = HM_Battle.bArenaAward })
	:Text(_L["Show next week currency in the arean panel"]):Click(function(bChecked)
		HM_Battle.bArenaAward = bChecked
	end)
	-- extra options (auto enter)
	ui:Append("Text", { txt = _L["Auto confirm"], x = 0, y = 250, font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Auto enter battlefield (need not click, prevent desertion)"], x = 10, y = 278, checked = HM_Battle.bAutoBattle })
	:Click(function(bChecked)
		HM_Battle.bAutoBattle = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Auto enter arean (same as above)"], x = 10, y = 306, checked = HM_Battle.bAutoArena })
	:Click(function(bChecked)
		HM_Battle.bAutoArena = bChecked
	end)
end

-- check conflict
_HM_Battle.PS.OnConflictCheck = function()
	if JG_Helper then
		JG_Helper.bOn = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("SYS_MSG", _HM_Battle.OnSysMsg)
HM.RegisterEvent("LOADING_END", _HM_Battle.BeginJG)
HM.RegisterEvent("SYNC_CORPS_LIST", _HM_Battle.OnSyncArenaList)
HM.RegisterEvent("SYNC_CORPS_BASE_DATA", _HM_Battle.OnSyncArenaData)
HM.RegisterEvent("SYNC_CORPS_MEMBER_DATA", _HM_Battle.OnSyncArenaData)
HM.RegisterEvent("BATTLE_FIELD_NOTIFY", _HM_Battle.OnBattleNotify)
HM.RegisterEvent("ARENA_NOTIFY", _HM_Battle.OnAreanNotify)

-- add to HM panel
HM.RegisterPanel(_L["Battle/Arean"], 354, _L["Battle"], _HM_Battle.PS)

-- hotkey
HM.AddHotKey("AlarmJG", _L["JIUGONG chest timer"],  _HM_Battle.AlarmJG)
