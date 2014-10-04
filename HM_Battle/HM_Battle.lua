--
-- 海鳗插件：战场/竞技场助手、九宫报时助手
--

HM_Battle = {
	bFormArean = true,		-- 在竞技场自动交出阵眼
	bAlarmJG2 = false,		-- 九宫自动报时
	bMarkMap = true,		-- 战场地图方向标记
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
    local hTotal = frame:Lookup("", "")
    local ui = HM.UI(hTotal, "Handle_MapEx")
	if not dwMapID then
		dwMapID = GetClientPlayer().GetMapID()
	end
    if HM_Battle.bMarkMap and (dwMapID == 48 or dwMapID == 50 or dwMapID == 135 or dwMapID == 186) and not ui then
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
		elseif dwMapID == 186 then
            ui:Append("Text", { txt = _L["East"], font = 199, x = 590 * fS, y = 430 * fS })
            ui:Append("Text", { txt = _L["South"], font = 199, x = 530 * fS, y = 550 * fS })
            ui:Append("Text", { txt = _L["West"], font = 199, x = 435 * fS, y = 545 * fS })
            ui:Append("Text", { txt = _L["North"], font = 199, x = 505 * fS, y = 385 * fS })
            ui:Append("Text", { txt = _L["Center"], font = 199, x = 520 * fS, y = 460 * fS })
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
-- 事件处理
-------------------------------------
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
	-- kill effect
	ui:Append("Text", { txt = _L["PVP kill effect"], x = 0, y = 222, font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Play sound after killing"], x = 10, y = 250, checked = HM_KillEffect.bSound })
	:Click(function(bChecked)
		HM_KillEffect.bSound = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Show red text after killing"], x = 10, y = 278, checked = HM_KillEffect.bText })
	:Click(function(bChecked)
		HM_KillEffect.bText = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Show caster name of float combat text"], x = 10, y = 306, checked = HM_CombatText.bShowName })
	:Click(function(bChecked)
		HM_CombatText.Switch(bChecked)
	end)
end

-- check conflict
_HM_Battle.PS.OnConflictCheck = function()
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("SYS_MSG", _HM_Battle.OnSysMsg)
HM.RegisterEvent("LOADING_END", function()
	_HM_Battle.BeginJG()
	HM_CombatText.Switch(HM_CombatText.bShowName)
end)
HM.RegisterEvent("BATTLE_FIELD_NOTIFY", _HM_Battle.OnBattleNotify)
HM.RegisterEvent("ARENA_NOTIFY", _HM_Battle.OnAreanNotify)

-- add to HM panel
HM.RegisterPanel(_L["Battle/Arean"], 1540, nil, _HM_Battle.PS)

-- hotkey
HM.AddHotKey("AlarmJG", _L["JIUGONG chest timer"],  _HM_Battle.AlarmJG)
