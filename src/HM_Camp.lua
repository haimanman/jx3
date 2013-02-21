--
-- 海鳗插件：攻防选目标、攻防自动屏蔽、日常 BOSS报时（小退还原）
--

local function _n(dwID)
	return Table_GetNpcTemplateName(dwID)
end

HM_Camp = {
	bHideEnable = false,
	tHideExclude = { [4] = true, [6] = true, [7] = true },
	tHideSave = {},
	bPartyAlert = true,			-- 不同阵营的成员进队发出提示
	bQuestAccept = true,	-- 自动接日常
	bBossTime = true,			-- boss 刷新提醒(倒计时条)
	bBossTimeAlert = false,		-- boss 刷新团队播报
	bBossTimeGF = true,		-- 攻防 BOSS 计时
	tBossList = {
		[_n(6219)--[[方超]]] = 5,
		[_n(6222)--[[霸图]]] = 5,
		[_n(6220)--[[赵新宇]]] = 5,
		[_n(6221)--[[孙永恒]]] = 5,
		[_n(14042)--[[冷翼毒神]]] = 1.5,
		[_n(1308)--[[郭海宾]]] = 3,
		[_n(1317)--[[左破天]]] = 3,
		--[_n(1217)--[[催命判官]]] = 3,
		--[_n(1215)--[[恶人谷练兵将]]] = 3,
	},
	tAnchor = {},
}

for k, _ in pairs(HM_Camp) do
	RegisterCustomData("HM_Camp." .. k)
end

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Camp = {
	tHideItem = {
		_L["Shield NPC"], _L["Shield player"], _L["Shield gas field"],
		_L["Hide player name"], _L["Hide player title"], _L["Hide guild name"],
		_L["Hide blood bar"], _L["Hide combat msg"],
		_L["Hide HM gas range"], _L["Hide HM organ range"],
		_L["Hide HM skill monitor"], _L["Hide HM target buff"], _L["Hide HM self buff"],
		_L["Hide HM red point of minimap"],
	},
	tDeadBoss = {}, 	-- dead boss (for time)
	tAddParty = {},	-- add party member
	tActiveBoss = {},	-- actived boss in camp fight
	tTimer = {},	--data of timer
}

-- gf boss list
_HM_Camp.tBossGF = {
	[_n(17233)--[[谢烟客]]] = 1, [_n(17234)--[[陶杰]]] = 1, [_n(17235)--[[周峰]]] = 1, [_n(17236)--[[郑鸥]]] = 1, [_n(16894)--[[张桎辕]]] = 1,
	[_n(20577)--[[可人]]] = 1, [_n(18050)--[[月弄痕]]] = 1, [_n(18048)--[[影]]] = 1, [_n(16893)--[[司空仲平]]] = 1, [_n(20275)--[[谢渊]]] = 3, [_n(16895)--[[翟季真]]] = 5,
	[_n(17237)--[[顾延恶]]] = 2, [_n(17240)--[[陶国栋]]] = 2, [_n(17239)--[[张一洋]]] = 2, [_n(17238)--[[吕沛杰]]] = 2, [_n(16900)--[[米丽古丽]]] = 2,
	[_n(16902)--[[肖药儿]]] = 2, [_n(16901)--[[沈眠风]]] = 2, [_n(16899)--[[陶寒亭]]] = 2, [_n(16903)--[[烟]]] = 2,  [_n(20274)--[[王遗风]]] = 4, [_n(20428)--[[莫雨]]] = 6,
}

-- get boss camp
_HM_Camp.GetBossCamp = function(szName)
	local n = _HM_Camp.tBossGF[szName]
	if n and (n % 2) == 0 then
		return CAMP.EVIL
	elseif n then
		return CAMP.GOOD
	end
end

-- sysmsg
_HM_Camp.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Camp"])
end

--debug
_HM_Camp.Debug = function(szMsg)
	HM.Debug(szMsg, _L["HM_Camp"])
end

-- get hide menu
_HM_Camp.GetHideMenu = function()
	local m0 = {}
	for k, v in ipairs(_HM_Camp.tHideItem) do
		local m1 = { szOption = v,
			bCheck = true, bChecked = HM_Camp.tHideExclude[k] ~= true,
			fnAction = function(d, b) HM_Camp.tHideExclude[k] = not b end
		}
		if k >= 4 and k <= 7 then
			m1.fnDisable = function() return Global_UpdateHeadTopPosition == nil end
		end
		table.insert(m0, m1)
	end
	return m0
end

-- save hide setting
_HM_Camp.SaveHide = function()
	-- 4, 5, 6, 7
	if Global_UpdateHeadTopPosition ~= nil then
		HM_Camp.tHideSave[4] = not GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_NAME)
		HM_Camp.tHideSave[5] = not GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_TITLE)
		HM_Camp.tHideSave[6] = not GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_GUILD)
		HM_Camp.tHideSave[7] = not GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_LEFE)
	end
	-- 9, 10, 11, 12, 13
	HM_Camp.tHideSave[9] = HM_Area ~= nil and not HM_Area.bQichang
	HM_Camp.tHideSave[10] = HM_Area ~= nil and not HM_Area.bJiguan
	HM_Camp.tHideSave[11] = HM_TargetMon ~= nil and not HM_TargetMon.bSkillMon
	HM_Camp.tHideSave[12] = HM_TargetMon ~= nil and not HM_TargetMon.bTargetBuffEx
	HM_Camp.tHideSave[13] = HM_TargetMon ~= nil and not HM_TargetMon.bSelfBuffEx
	HM_Camp.tHideSave[14] = HM_RedName ~=nil and not HM_RedName.bEnableMini
end

-- switch hide
_HM_Camp.HideGF = function(bEnable, bNoSave)
	local tHide = {}
	if bEnable == nil then
		bEnable = not HM_Camp.bHideEnable
		if _HM_Camp.HideBox then
			return _HM_Camp.HideBox:Check(bEnable)
		end
	end
	HM_Camp.bHideEnable = bEnable
	if bEnable then
		if not bNoSave then
			_HM_Camp.SaveHide()
		end
		for i = 1, #_HM_Camp.tHideItem do
			tHide[i] = HM_Camp.tHideExclude[i] ~= true
		end
		_HM_Camp.Sysmsg(_L["Enable super shield"])
	else
		for i = 1, #_HM_Camp.tHideItem do
			tHide[i] = HM_Camp.tHideSave[i] == true
		end
		_HM_Camp.Sysmsg(_L["Disable super shield"])
	end
	-- npc
	if tHide[1] then
		rlcmd("hide npc")
	else
		rlcmd("show npc")
	end
	-- player
	if tHide[2] then
		rlcmd("hide player")
	else
		rlcmd("show player")
	end
	-- qc
	if tHide[3] then
		rlcmd("npc filter on 1")
		rlcmd("npc filter on 2")
	else
		rlcmd("npc filter off 1")
		rlcmd("npc filter off 2")
	end
	-- head flag
	if Global_UpdateHeadTopPosition ~= nil then
		SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_NAME, not tHide[4])
		SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_TITLE, not tHide[5])
		SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_GUILD, not tHide[6])
		SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_LEFE, not tHide[7])
		Global_UpdateHeadTopPosition()
	end
	-- combat
	if not HM_Camp.tHideExclude[8] then
		local frame = Station.Lookup("Lowest/CombatTextWnd")
		if tHide[8] and frame then
			Wnd.CloseWindow(frame)
		elseif not tHide[8] and not frame then
			Wnd.OpenWindow("CombatTextWnd")
		end
	end
	-- restore
	if HM_Area then
		if not HM_Camp.tHideExclude[9] then
			HM_Area.bQichang = not tHide[9]
		end
		if not HM_Camp.tHideExclude[10] then
			HM_Area.bJiguan = not tHide[10]
		end
	end
	if HM_TargetMon then
		if not HM_Camp.tHideExclude[11] then
			HM_TargetMon.bSkillMon = not tHide[11]
		end
		if not HM_Camp.tHideExclude[12] then
			HM_TargetMon.bTargetBuffEx = not tHide[12]
		end
		if not HM_Camp.tHideExclude[13] then
			HM_TargetMon.bSelfBuffEx = not tHide[13]
		end
		HM_TargetMon.UpdateFrames()
	end
	if HM_RedName then
		if not HM_Camp.tHideExclude[14] then
			HM_RedName.bEnableMini = not tHide[14]
		end
	end
end

-- quick select target
_HM_Camp.TargetGF = function()
	local npc, nFlag = nil, 0
	for _, v in ipairs(HM.GetAllNpc()) do
		local nFlag2 = _HM_Camp.tBossGF[v.szName]
		if nFlag2 and (nFlag2 > 2 or not npc) then
			npc, nFlag = v, nFlag2
			if nFlag2 > 4 then
				break
			end
		end
	end
	if npc then
		local me, bSel = GetClientPlayer(), false
		if not HM.IsDps(me) then
			bSel = (nFlag == 1 or nFlag == 3 or nFlag == 5)
		else
			bSel = (nFlag == 2 or nFlag == 4 or nFlag == 6)
		end
		if (bSel and me.nCamp == CAMP.EVIL) or (not bSel and me.nCamp == CAMP.GOOD) then
			local tarType, tarID = npc.GetTarget()
			local tar = HM.GetTarget(tarType, tarID)
			if not tar then
				HM.SetTarget(TARGET.NPC, npc.dwID)
				_HM_Camp.Sysmsg(_L("None of target, first to select BOSS [%s]", npc.szName))
			else
				HM.SetTarget(tarType, tarID)
				_HM_Camp.Sysmsg(_L("The target of BOSS [%s] is [%s], selected", npc.szName, tar.szName))
			end
		else
			HM.SetTarget(TARGET.NPC, npc.dwID)
			_HM_Camp.Sysmsg(_L("Select the BOSS [%s]", npc.szName))
		end
	else
		_HM_Camp.Sysmsg(_L["No related BOSS found"])
	end
end

-------------------------------------
-- 日常 BOSS 计时监控、提醒
-------------------------------------
-- edit boss item
_HM_Camp.EditBoss = function(szName, dwMin)
	local frm, tBoss = _HM_Camp.kFrame, HM_Camp.tBossList
	if not frm then
		frm = HM.UI.CreateFrame("HM_CAMP_BOSS", { close = false, w = 381, h = 240 })
		frm:Append("Text", { txt = _L["Name of NPC"], x = 0, y = 0, font = 27 }):Pos_()
		frm:Append("WndEdit", "Edit_Name", { x = 0, y = 28, limit = 100, w = 290, h = 25 } )
		frm:Append("Text", { txt = _L["Refresh Time (Unit: min)"], x = 0, y = 60, font = 27 })
		frm:Append("WndEdit", "Edit_Time", { x = 0, y = 88, w = 290, h = 25, limit = 10 })
		-- buttons
		frm:Append("WndButton", "Btn_Save", { txt = _L["Save"], x = 45, y = 120 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			local dwMin = tonumber(frm:Fetch("Edit_Time"):Text())
			if szName == "" or not dwMin then
				HM.Alert(_L["Name of NPC and time can not be empty"])
			else
				tBoss[szName] = dwMin
				frm:Toggle(false)
			end
		end)
		frm:Append("WndButton", "Btn_Delete", { txt = _L["Remove"], x = 145, y = 120 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			tBoss[szName] = nil
			frm:Toggle(false)
		end)
		_HM_Camp.kFrame = frm
	end
	-- title
	if not szName then
		frm:Title(_L["Add BOSS refresh time"])
		frm:Fetch("Edit_Name"):Text(""):Enable(true)
		frm:Fetch("Edit_Time"):Text(""):Enable(true)
	else
		frm:Title(_L["Edit BOSS refresh time"])
		frm:Fetch("Edit_Name"):Text(szName):Enable(false)
		frm:Fetch("Edit_Time"):Text(tostring(tBoss[szName])):Enable(true)
	end
	frm:Fetch("Btn_Delete"):Enable(szName ~= nil)
	frm:Toggle(true)
end

-- get boss list
_HM_Camp.GetBossMenu = function()
	local m0 = {
		{ szOption = _L["* New *"], fnAction = _HM_Camp.EditBoss },
		{ bDevide = true },
	}
	for k, v in pairs(HM_Camp.tBossList) do
		table.insert(m0, { szOption = k .. _L("(%smin)", v), fnAction = function() _HM_Camp.EditBoss(k, v) end })
	end
	return m0
end

-- get boss alert frames (return list)
_HM_Camp.GetBossTime = function(nFrame)
	local nNow, tFrame = GetLogicFrameCount(), {}
	-- xMin
	local nMin = math.ceil(nFrame / 960) - 1
	while nMin > 0 do
		local nF = nNow + nFrame - nMin * 960
		table.insert(tFrame, { nF, _L("%dm", nMin) })
		nMin = nMin - 1
	end
	-- xSec
	local tSec = { 480, 320, 160, 80, 64, 48, 32, 16 }
	-- 1~5, 10, 20, 30 sec
	for _, v in ipairs(tSec) do
		if nFrame > v then
			local nF = nNow + nFrame - v
			table.insert(tFrame, { nF, _L("%ds", v / 16) })
		end
	end
	return tFrame
end

-------------------------------------
-- 事件函数
-------------------------------------
-- boss death
_HM_Camp.OnSysMsg = function()
	if HM_Camp.bBossTime and arg0 == "UI_OME_DEATH_NOTIFY" then
		local npc = GetNpc(arg1)
		if npc and HM_Camp.tBossList[npc.szName] then
			local me, time = GetClientPlayer(), math.floor(HM_Camp.tBossList[npc.szName] * 960)
			_HM_Camp.tDeadBoss[npc.szName] = {
				tFrame = _HM_Camp.GetBossTime(time),
				dwMapID = me.GetScene().dwMapID,
				nX = npc.nX,
				nY = npc.nY,
				nZ = npc.nZ,
			}
			_HM_Camp.Timer(npc.szName, time)
		end
	end
end

-- boss appear
_HM_Camp.OnNpcEnter = function()
	-- boss alert
	if HM_Camp.bBossTime and not IsEmpty(_HM_Camp.tDeadBoss) then
		local npc = GetNpc(arg0)
		if npc and _HM_Camp.tDeadBoss[npc.szName] then
			-- set target
			_HM_Camp.tDeadBoss[npc.szName] = nil
			HM.SetTarget(TARGET.NPC, npc.dwID)
			-- talk tip
			local nChannel = PLAYER_TALK_CHANNEL.RAID
			if not GetClientPlayer().IsInParty() then
				nChannel = PLAYER_TALK_CHANNEL.NEARBY
			end
			if HM_Camp.bBossTimeAlert then
				HM.Talk(nChannel, _L("* Notice * [%s] appeared, hurried to attack it !!!", npc.szName))
			end
			_HM_Camp.KillTimer(npc.szName)
		end
	end
end

-- breathe call
_HM_Camp.OnBreathe = function()
	local me, nFrame = GetClientPlayer(), GetLogicFrameCount()
	-- BossTime Alert
	if HM_Camp.bBossTime and me then
		for k, v in pairs(_HM_Camp.tDeadBoss) do
			if v.dwMapID ~= me.GetScene().dwMapID then	-- diff map
				_HM_Camp.tDeadBoss[k] = nil
			elseif v.nEnd then	-- expired
				if (nFrame - v.nEnd) > 64 then
					_HM_Camp.tDeadBoss[k] = nil
				end
			else
				local at = v.tFrame[1]
				if at and nFrame >= at[1] then
					if (nFrame - at[1]) < 16 and HM.GetDistance(v.nX, v.nY, v.nZ) < 100 then
						local nChannel = PLAYER_TALK_CHANNEL.RAID
						if not me.IsInParty() then
							nChannel = PLAYER_TALK_CHANNEL.NEARBY
						end
						if HM_Camp.bBossTimeAlert then
							HM.Talk(nChannel, _L("* Notice * [%s] will appears after %s !!!", k, at[2]))
						end
					end
					table.remove(v.tFrame, 1)
					if table.getn(v.tFrame) == 0 then
						v.nEnd = nFrame
					end
				end
			end
		end
	end
end

--only for timer
_HM_Camp.Timer = function(szName, nTime)
	local nFrame=GetLogicFrameCount()
	table.insert(_HM_Camp.tTimer,{
		dwID = szName,
		szName = szName,
		nEnd = nTime + GetLogicFrameCount(),
		nTotal = nTime
	})
	_HM_Camp.Debug("start timer ["..npc.szName.."]")
end

_HM_Camp.KillTimer = function(szName)
	for i,v in ipairs(_HM_Camp.tTimer) do
		if v.dwID == szName then
			table.remove(_HM_Camp.tTimer,i)
			_HM_Camp.Debug("kill timer [" .. npc.szName .. "]")
			return
		end
	end
end

_HM_Camp.ClearTimer = function()
	_HM_Camp.tTimer = {}
end

--for test
HM_Camp.KillTimer = _HM_Camp.KillTimer
HM_Camp.Timer = _HM_Camp.Timer
HM_Camp.ClearTimer = _HM_Camp.ClearTimer

_HM_Camp.GetBoxText = function(hImage, hBG, hTextName, hTextTime)
	local nCount = hImage:GetItemCount()
	if hImage.nIndex < nCount then
		nCount = hImage.nIndex
	else
		hImage:AppendItemFromString("<image> w=200 h=32 postype=10 path=" .. EncodeComponentsString("ui\\Image\\UICommon\\CommonPanel2.UITex") .. " frame=15 imagetype=1 </image>")
		hBG:AppendItemFromString("<image> w=200 h=32 postype=10 path=" .. EncodeComponentsString("ui\\Image\\UICommon\\CommonPanel2.UITex") .. " frame=75 alpha=100 imagetype=1 </image>")
		hTextName:AppendItemFromString("<text> w=200 h=32 postype=10 halign=1 valign=1 </text>")
		hTextTime:AppendItemFromString("<text> w=200 h=32 postype=10 halign=2 valign=1 </text>")
	end
	hImage.nIndex = nCount + 1
	return hImage:Lookup(nCount), hBG:Lookup(nCount), hTextName:Lookup(nCount), hTextTime:Lookup(nCount)
end

_HM_Camp.GetLeftTime = function(nEndFrame, bFrame)
	local nFrame = nEndFrame - GetLogicFrameCount()
	local nSec = nFrame / 16
	if nSec < 10 then
		if bFrame and nSec < 5 then
			return string.format("(%d)%ds", nFrame, nSec), 204
		end
		return string.format("%.1fs", nSec), 204
	elseif nSec < 100 then
		return string.format("%ds", nSec), 204
	elseif nSec < 3600 then
		return string.format("%dm %ds", nSec / 60, nSec % 60), 203
	elseif nSec < 86400 then
		return string.format("%dh %dm %ds", nSec / 3600, nSec / 60 % 60, nSec % 60), 203
	elseif nSec < 604800 then
		return string.format("%dd %dh %dm %ds", nSec / 86400, nSec / 3600 % 24, nSec / 60 % 60, nSec % 60),203
	else
		return "", 203
	end
end

_HM_Camp.UpdateTimer = function(data, image, bg, name, time)
	if not box.dwID then
		name:SetFontScheme(15)
		time:SetFontScheme(15)
	end
	if image.dwID ~= data.dwID then
		image.dwID = data.dwID
		if string.len(data.szName) > 10 then
			name:SetText(string.sub(data.szName, 1, 8) .. "..")
		else
			name:SetText(data.szName)
		end
	end
	local szTime, nFont = _HM_Camp.GetLeftTime(data.nEnd, true)
	local nFrame = data.nEnd - GetLogicFrameCount()
	time:SetText(szTime)
	time:SetFontScheme(nFont)
	if nFrame < 160 then
		image:SetFrame(13)
		image:SetPercentage(nFrame / 160)
	else
		image:SetFrame(15)
		image:SetPercentage(nFrame / data.nTotal)
	end
	image:Show()
	bg:Show()
	name:Show()
	time:Show()
end

_HM_Camp.UpdateAnchor = function(frame)
	local an = HM_Camp.tAnchor[frame.nIndex]
	if an then
		-- custom pos
		frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	else
		-- default pos
		frame:SetAbsPos(460, 150)
	end
	frame:CorrectPos()
end

_HM_Camp.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_Camp.tAnchor[this.nIndex] = GetFrameAnchor(this)
end

-- event
_HM_Camp.OnEvent = function(event)
	if event == "ON_ENTER_CUSTOM_UI_MODE" or event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this)
	elseif event == "UI_SCALED" then
		_HM_Camp.UpdateAnchor(this)
	end
end

_HM_Camp.OnFrameCreate = function()
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("UI_SCALED")
	_HM_Camp.UpdateAnchor(this)
	if this.nIndex == 1 then
		UpdateCustomModeWindow(this, _L["HM Boss timer"])
	end
end

_HM_Camp.OnFrameBreathe = function()
	local nFrame, me = GetLogicFrameCount(), GetClientPlayer()
	if not me then return end
	local hImage, hBG, hTextName, hTextTime, bHide = this:Lookup("", "Handle_ImageTimer"), this:Lookup("", "Handle_ImageBG"), this:Lookup("", "Handle_TextName"), this:Lookup("", "Handle_TextTime"), true
	hImage.nIndex=0
	for _,v in ipairs(_HM_Camp.tTimer) do
		if v.nEnd > nFrame then
			_HM_Camp.UpdateTimer(v, _HM_Camp.GetBoxText(hImage, hBG, hTextName, hTextTime))
			bHide = false
		end
	end
	if bHide then
		hImage:Hide()
		hBG:Hide()
		hTextName:Hide()
		hTextTime:Hide()
	else
		for i = hImage:GetItemCount() - 1, hImage.nIndex, -1 do
			hImage:Lookup(i):Hide()
			hBG:Lookup(i):Hide()
			hTextName:Lookup(i):Hide()
			hTextTime:Lookup(i):Hide()
		end
		hImage:FormatAllItemPos()
		hBG:FormatAllItemPos()
		hTextName:FormatAllItemPos()
		hTextTime:FormatAllItemPos()
		hImage:Show()
		hBG:Show()
		hTextName:Show()
		hTextTime:Show()
		local handle = this:Lookup("", "")
		hImage:SetRelPos(0, 0)--FIXME: the following 4(or 5) statement is unnecessary?
		hBG:SetRelPos(0, 0)
		hTextName:SetRelPos(0, 0)
		hTextTime:SetRelPos(0, 0)
		handle:FormatAllItemPos()
	end
end

_HM_Camp.UpdateFrame = function(bEnable, nIndex)
	local frame = Station.Lookup("Normal/HM_Camp_" .. nIndex)
	if bEnable then
		if not frame then
			frame = Wnd.OpenWindow("interface\\HM\\ui\\HM_Camp.ini", "HM_Camp_" .. nIndex)
			frame.nIndex = nIndex
			frame.OnFrameBreathe = _HM_Camp.OnFrameBreathe
			frame.OnFrameDragEnd = _HM_Camp.OnFrameDragEnd
			frame.OnEvent = _HM_Camp.OnEvent
			local _this = this
			this = frame
			_HM_Camp.OnFrameCreate()
			this = _this
		end
	elseif frame then
		Wnd.CloseWindow(frame)
	end
end

_HM_Camp.UpdateFrames = function()
	_HM_Camp.UpdateFrame(HM_Camp.bBossTime, 1)
end

-- party add member
_HM_Camp.OnPartyAdd = function(dwID)
	local team = GetClientTeam()
	if team.nGroupNum > 1 then
		local info = team.GetMemberInfo(dwID)
		if info and info.nCamp ~= GetClientPlayer().nCamp then
			local nGroup = team.GetMemberGroupIndex(dwID) + 1
			HM.Talk(PLAYER_TALK_CHANNEL.RAID,
				_L("* Warn * ~%s~ camp player [%s] join the team in No.%d group", g_tStrings.STR_CAMP_TITLE[info.nCamp], info.szName, nGroup))
		end
	end
end

-------------------------------------
-- 攻防 BOSS 计时
-------------------------------------
-- 包括支持复活点BOSS：鼠标左键点击士气条图标弹出提示，右键点击发布到当前聊天频道
-- 大声喊：米丽古丽已经不支，可人，有劳了
-- check is in camp fight map (BUFF：偃旗息鼓/2105)
_HM_Camp.IsInGFMap = function()
	--do return true end
	local me = GetClientPlayer()
	if me then
		local aBuff = me.GetBuffList() or {}
		for _, v in ipairs(aBuff) do
			if not v.bCanCancel and v.dwID == 2105 then
				return true
			end
		end
	end
end

-- get boss info
_HM_Camp.ShowBossInfo = function()
	local szTip = ""
	if not HM_Camp.bBossTimeGF then
		return
	elseif not _HM_Camp.IsInGFMap() then
		_HM_Camp.tActiveBoss = {}
		szTip = GetFormatText(_L["Not in camp fight map or not battle"], 27)
	else
		local nCamp, nFrame = GetClientPlayer().nCamp, GetLogicFrameCount()
		for k, v in pairs(_HM_Camp.tActiveBoss) do
			local nFont, nSec = 165, math.ceil(nFrame - v)/16
			if nSec < 7200 then
				local nBossCamp = _HM_Camp.GetBossCamp(k)
				if not nBossCamp then
					nFont = 163
				elseif nCamp ~= nBossCamp then
					nFont = 166
				end
				local szName = "\n" .. k .. "  "
				local szTime = string.format("%d'%02d\"", nSec / 60, nSec % 60)
				if nSec < 300 then
					szTime = szTime .. " (-90%)"
				elseif nSec < 600 then
					szTime = szTime .. "(-60%)"
				elseif nSec < 900 then
					szTime = szTime .. "(-30%)"
				end
				szTip = szTip .. GetFormatText(szName, nFont) .. GetFormatText(szTime)
			end
		end
		if szTip == "" then
			szTip = GetFormatText(_L["No camp BOSS information"], 27)
		else
			szTip = GetFormatText(_L["Camp BOSS infomation"], 27) .. szTip
		end
	end
	local nX, nY = Cursor.GetPos()
	OutputTip(szTip, 330, { nX, nY, 10, 10 })
end

-- talk boss info
_HM_Camp.TalkBossInfo = function()
	local bHave, nFrame = false, GetLogicFrameCount()
	if not HM_Camp.bBossTimeGF then
		return
	elseif not _HM_Camp.IsInGFMap() then
		_HM_Camp.tActiveBoss = {}
		return HM.Sysmsg(_L["Not in camp fight map or not battle"])
	end
	local nChannel, szName = EditBox_GetChannel()
	local bTalk2, szTalk2 = HM.CanTalk(nChannel), ""
	if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		nChannel = szName
	end
	for k, v in pairs(_HM_Camp.tActiveBoss) do
		local nSec = math.ceil(nFrame - v)/16
		if nSec < 7200 then
			if not bHave then
				bHave = true
				if bTalk2 then
					HM.Talk2(nChannel, _L["Camp BOSS infomation"])
				else
					szTalk2 = szTalk2 .. _L["Camp BOSS infomation"]
				end
			end
			local szInfo = _L("[%s: %d'%02d\"", k, nSec / 60, nSec % 60)
			if nSec < 300 then
				szInfo = szInfo .. " (-90%)"
			elseif nSec < 600 then
				szInfo = szInfo .. " (-60%)"
			elseif nSec < 900 then
				szInfo = szInfo .. " (-30%)"
			end
			szInfo = szInfo .. _L["]"]
			if bTalk2 then
				HM.Talk2(nChannel, szInfo)
			else
				szTalk2 = szTalk2 .. szInfo
			end
		end
	end
	if not bHave then
		HM.Sysmsg(_L["No camp BOSS information"])
	elseif not bTalk2 then
		HM.Talk2(nChannel, szTalk2)
	end
end

-- 绑定攻防面板事件
_HM_Camp.HookCampPanel = function()
	local frame = Station.Lookup("Normal/CampPanel")
	if frame and not frame.bEventAdded then
		local img1, img2 = frame:Lookup("", "Image_Logo1"), frame:Lookup("", "Image_Logo2")
		img1:RegisterEvent(0x30)
		img1.OnItemLButtonClick = _HM_Camp.ShowBossInfo
		img1.OnItemRButtonClick = _HM_Camp.TalkBossInfo
		img2:RegisterEvent(0x30)
		img2.OnItemLButtonClick = _HM_Camp.ShowBossInfo
		img2.OnItemRButtonClick = _HM_Camp.TalkBossInfo
		frame.bEventAdded = true
	end
end

-- 监视 NPC 地图喊话
_HM_Camp.OnNpcYell = function(szMsg)
	local _, _, szBoss1, szBoss2 = string.find(szMsg, _L["Shout: (-) have been seriously injured (. -), Labor"])
	if szBoss1 and szBoss2 then
		_HM_Camp.tActiveBoss[szBoss1] = nil
		_HM_Camp.tActiveBoss[szBoss2] = GetLogicFrameCount()
	end
end

-- 地图加载完毕，判断是否在浩气、恶人
_HM_Camp.OnLoadingEnd = function()
	local dwMapID = GetClientPlayer().GetScene().dwMapID
	if dwMapID == 27 or dwMapID == 25 then
		_HM_Camp.HookCampPanel()
		RegisterMsgMonitor(_HM_Camp.OnNpcYell, { "MSG_NPC_YELL" })
	else
		UnRegisterMsgMonitor(_HM_Camp.OnNpcYell, { "MSG_NPC_YELL" })
	end
	_HM_Camp.ClearTimer()
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Camp.PS = {}

-- deinit panel
_HM_Camp.PS.OnPanelDeactive = function(frame)
	_HM_Camp.HideBox = nil
end

-- init panel
_HM_Camp.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- quick shield
	ui:Append("Text", { txt = _L["Camp fight target"], x = 0, y = 0, font = 27 })
	_HM_Camp.HideBox = ui:Append("WndCheckBox", { x = 10, y = 28, checked = HM_Camp.bHideEnable })
	:Text(_L["Enable shield (macro cmd: /"] .. _L["CampShield"] .. _L[", "]):Click(_HM_Camp.HideGF)
	nX = _HM_Camp.HideBox:Pos_()
	nX = ui:Append("Text", { txt = _L["Hotkey"], x = nX, y = 27 }):Click(HM.SetHotKey):Pos_()
	ui:Append("Text", { txt = HM.GetHotKey("HideGF", false) .. _L[") "], x = nX, y = 27 })
	ui:Append("WndComboBox", { txt = _L["Set shield item"], x = 14, y = 56 }):Menu(_HM_Camp.GetHideMenu)
	-- select target
	ui:Append("Text", { txt = _L["Camp fight target"], x = 0, y = 92, font = 27 })
	nX = ui:Append("WndButton", { txt = _L["Select camp target"], x = 10, y = 122 }):AutoSize(8):Click(_HM_Camp.TargetGF):Pos_()
	nX = ui:Append("Text", { txt = _L["(macro cmd: /"] .. _L["CampTarget"] .. _L[", "], x = nX, y = 121 }):Pos_()
	nX = ui:Append("Text", { txt = _L["Hotkey"], x = nX, y = 121 }):Click(HM.SetHotKey):Pos_()
	ui:Append("Text", { txt = HM.GetHotKey("TargetGF", false) .. _L[") "], x = nX, y = 121 })
	ui:Append("Text", { txt = _L["In offensive, DPS select BOSS and healer select MT, otherwise is the opposite"], x = 14, y = 148, font = 161 })
	-- boss time/quest
	ui:Append("Text", { txt = _L["Camp daily quest"], x = 0, y = 184, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = 212, checked = HM_Camp.bBossTime })
	:Text(_L["Enable the refresh time of BOSS"]):Click(function(bChecked)
		HM_Camp.bBossTime = bChecked
		_HM_Camp.UpdateFrame(bChecked, 1)
	end):Pos_()
	nX = ui:Append("WndCheckBox", { x = nX + 10, y = 212, checked = HM_Camp.bBossTimeAlert })
	:Text(_L["Broadcast in team"]):Click(function(bChecked) HM_Camp.bBossTimeAlert = bChecked end):Pos_()
	ui:Append("WndComboBox", { txt = _L["Set BOSS time"], x = nX + 10, y = 212 }):Menu(_HM_Camp.GetBossMenu)
	ui:Append("WndCheckBox", { x = 10, y = 240, checked = HM_Camp.bPartyAlert })
	:Text(_L["Alert when different camp of players join the team"]):Click(function(bChecked) HM_Camp.bPartyAlert = bChecked end)
	ui:Append("WndCheckBox", { x = 10, y = 268, checked = HM_Camp.bBossTimeGF})
	:Text(_L["Record BOSS time in camp fight (click icons of camp bar)"]):Click(function(bChecked)
		HM_Camp.bBossTimeGF = bChecked
	end)
end

-- player menu
_HM_Camp.PS.OnPlayerMenu = function()
	return {
		szOption = _L["Enable super shield"] .. HM.GetHotKey("HideGF", true),
		bCheck = true, bChecked = HM_Camp.bHideEnable, fnAction = _HM_Camp.HideGF
	}
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_ENTER_GAME", _HM_Camp.UpdateFrames)
HM.RegisterEvent("SYS_MSG", _HM_Camp.OnSysMsg)
HM.RegisterEvent("LOADING_END", _HM_Camp.OnLoadingEnd)
HM.RegisterEvent("NPC_ENTER_SCENE", _HM_Camp.OnNpcEnter)
HM.RegisterEvent("PARTY_ADD_MEMBER", function()
	if HM_Camp.bPartyAlert then
		local dwMapID = GetClientPlayer().GetScene().dwMapID
		-- camp map list 22，25，27，30，104
		if dwMapID == 22 or dwMapID == 25 or dwMapID == 27 or dwMapID == 30 or dwMapID == 104 then
			_HM_Camp.tAddParty[arg1] = true
		end
	end
end)
HM.RegisterEvent("PARTY_UPDATE_MEMBER_INFO", function()
	if _HM_Camp.tAddParty[arg1] then
		_HM_Camp.tAddParty[arg1] = nil
		_HM_Camp.OnPartyAdd(arg1)
	end
end)
HM.RegisterEvent("SYNC_ROLE_DATA_END", function()
	if HM_Camp.bHideEnable then
		_HM_Camp.HideGF(true, true)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["Camp helper"], 444, _L["Battle"], _HM_Camp.PS)

-- hotkey
HM.AddHotKey("TargetGF", _L["Auto camp target"],  _HM_Camp.TargetGF)
HM.AddHotKey("HideGF", _L["Super shield"],  _HM_Camp.HideGF)
AppendCommand(_L["CampTarget"], _HM_Camp.TargetGF)
AppendCommand(_L["CampShield"], function() _HM_Camp.HideGF() end)

-- breathe
HM.BreatheCall("HM_Camp", _HM_Camp.OnBreathe)
