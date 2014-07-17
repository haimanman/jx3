--
-- 海鳗插件：多焦点目标、目标列表
--

HM_TargetList = {
	bShow = true,				-- 开启功能
	bJihuo = true,				-- 开启双击集火（要求 HM_Marker）
	bAutoArena = true,		-- 开启竞技场模式（自动全部焦点对方）
	bAutoBigBoss = true,	-- 自动焦点攻防/计时 BOSS
	----
	--bShowFocus = true,	-- 显示焦点目标
	bFocusState = true,		-- 显示焦点状态/BUFF
	bFocusTarget2 = false,	-- 显示焦点的目标
	bFocusOld = false,		-- 使用旧版焦点界面
	bAltFocus = true,		-- 启用 Shift-点击设焦点
	bMonPrepare = false,	-- 通过切目标监控读条
	----
	--bShowList = true,		-- 显示目标列表
	nListMode = 6,			-- 列表模式
	bListWhite = true,		-- 白色模式
	tShowMode = {			-- 查看模式
		bLevel = false,			-- 显示等级
		bHP = false,			-- 显示血量
		bDistance = false,	-- 显示距离
		bForce = true,			-- 显示玩家职业
		bOnly25 = false,		-- 最多只显示 25个
	},
	nSortType = 0,				-- 排序模式，0：不排序，1：按血量，2：按距离
	bUpTreat = false,		-- 治疗置顶
	bDownDeath = true,	-- 重伤置底
	bDownFar = true,		-- 远距离押后 （抢人头）
	bDownFace = true,		-- 不面向的押后（抢人头）
	nFarThreshold = 20,		-- 20 尺以外算远？
	nAlphaBg = 80,			-- 背景透明度
	nMaxFocus = 5,			-- 最大数量
	bListFocus = true,		-- 在列表中仍显示焦点目标
	tAnchor = {},				-- 窗体位置
	----
	tCustomName = {},		-- 自定义名称
	tCustomTong = {},		-- 自定义帮会
	tCustomForce = {},		-- 自定义门派
	tCustomSave = {
		[_L["DH1"]] = {
				tCustomTong = {},
				tCustomForce = {},
				tCustomTong = {
					[_L["DH2"]] = true,
					[_L["DH3"]] = true,
					[_L["DH4"]] = true,
					[_L["DH5"]] = true,
					[_L["DH6"]] = true,
				},
		},
	},		-- 自定义保存
	----
	bShowAcct = true,	-- 人数统计（敌、友、中）
	tPersistFocus = {},	-- 永久焦点
}
HM.RegisterCustomData("HM_TargetList")

-- 暂不记录的选项
HM_TargetList.bShowFocus = true
HM_TargetList.bShowList = true

-- update custom
--[==[
local tDH8G = HM_TargetList.tCustomSave[_L["DH1"]].tCustomTong
HM.RegisterCustomUpdater(function()
	HM_TargetList.tCustomName = {}
	HM_TargetList.tCustomForce = {}
	HM_TargetList.tCustomTong = tDH8G
	HM_TargetList.tCustomSave[_L["DH1"]] = {
		tCustomTong = {},
		tCustomForce = {},
		tCustomTong = tDH8G,
	}
end, 20121123)
]==]

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_TargetList = {
	szIniFile = "interface\\HM\\HM_TargetList\\HM_TargetList.ini",
	szIniFile2 = "interface\\HM\\HM_TargetList\\HM_TargetList2.ini",
	tFocus = {},
	nFrameFocus = 0,
	nFrameList = 0,
	nFrameAcct = 0,
	tFilterNpc = {},			-- 临时屏蔽的NPC名称
	bInArena = false,
	bCustom = false,		-- 启用自定义
}

-- 是否在齐物阁同一区域：距离 100 尺内并且垂直距离 20尺内 (nZ/64*8)
local function IsInSameQWG(dwPlayer)
	local me = GetClientPlayer()
	if me and me.GetScene().dwMapID == 173 then
		if not dwPlayer then
			return true
		end
		local tar = GetPlayer(dwPlayer)
		if tar and HM.GetDistance(tar) < 100 and math.abs(me.nZ - tar.nZ) < 5120 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- 焦点目标
---------------------------------------------------------------------
-- get focus menu
_HM_TargetList.GetFocusMenu = function()
	local n = HM_TargetList.nMaxFocus
	return {
		{ szOption = _L["Display the latest focus alone"],
			bCheck = true, bChecked = HM_SingleFocus.bEnable2,
			fnAction = function(d, b) HM_SingleFocus.Switch(b) end
		}, { szOption = _L["Show move state/buff"],
			bCheck = true, bChecked = HM_TargetList.bFocusState,
			fnDisable = function() return not HM_TargetList.bShowFocus end,
			fnAction = function() HM_TargetList.bFocusState = not HM_TargetList.bFocusState end
		}, { szOption = _L["Show focused target name"],
			bCheck = true, bChecked = HM_TargetList.bFocusTarget2,
			fnDisable = function() return not HM_TargetList.bShowFocus end,
			fnAction = function() HM_TargetList.bFocusTarget2 = not HM_TargetList.bFocusTarget2 end
		}, { szOption = _L["Auto focus enemy in arena/qiwuge"], bCheck = true, bChecked = HM_TargetList.bAutoArena,
			fnDisable = function() return not HM_TargetList.bShowFocus end,
			fnAction = function() HM_TargetList.bAutoArena = not HM_TargetList.bAutoArena end
		}, { szOption = _L["Auto focus big/camp boss"], bCheck = true, bChecked = HM_TargetList.bAutoBigBoss,
			fnDisable = function() return not HM_TargetList.bShowFocus and HM_Camp end,
			fnAction = function() HM_TargetList.bAutoBigBoss = not HM_TargetList.bAutoBigBoss end
		}, { szOption = _L["Use old focused interface"], bCheck = true, bChecked = HM_TargetList.bFocusOld,
			fnDisable = function() return not HM_TargetList.bShowFocus end,
			fnAction = function()
				HM_TargetList.bFocusOld = not HM_TargetList.bFocusOld
				if _HM_TargetList.frame then
					_HM_TargetList.frame:Lookup("Wnd_Focus"):Lookup("", "Handle_Focus"):Clear()
					_HM_TargetList.nFrameFocus = 0
				end
			end
		}, { szOption = _L("Maximum focus num [%d]", HM_TargetList.nMaxFocus),
			fnDisable = function() return not HM_TargetList.bShowFocus end,
			{ szOption = "1", bCheck = true, bMCheck = true, UserData = 1, bChecked = n == 1 , fnAction = _HM_TargetList.AdjustMaxFocus },
			{ szOption = "2", bCheck = true, bMCheck = true, UserData = 2, bChecked = n == 2 , fnAction = _HM_TargetList.AdjustMaxFocus },
			{ szOption = "3", bCheck = true, bMCheck = true, UserData = 3, bChecked = n == 3 , fnAction = _HM_TargetList.AdjustMaxFocus },
			{ szOption = "4", bCheck = true, bMCheck = true, UserData = 4, bChecked = n == 4 , fnAction = _HM_TargetList.AdjustMaxFocus },
			{ szOption = "5", bCheck = true, bMCheck = true, UserData = 5, bChecked = n == 5 , fnAction = _HM_TargetList.AdjustMaxFocus },
		}, { szOption = _L["<Shift-Click to add focus>"],
			bCheck = true, bChecked = HM_TargetList.bAltFocus,
			fnAction = function(d, b) HM_TargetList.bAltFocus = b end,
		}, { szOption = _L["Monitor focus prepare via set target"],
			bCheck = true, bChecked = HM_TargetList.bMonPrepare,
			fnAction = function(d, b) HM_TargetList.bMonPrepare = b end,
		}
	}
end

-- adjust foucs max
_HM_TargetList.AdjustMaxFocus = function(n)
	if HM_TargetList.nMaxFocus ~= n then
		HM_TargetList.nMaxFocus = n
		while #_HM_TargetList.tFocus > n do
			table.remove(_HM_TargetList.tFocus, 1)
		end
	end
end

-- is focus
_HM_TargetList.IsFocus = function(dwID)
	for k, v in ipairs(_HM_TargetList.tFocus) do
		if v == dwID then
			return true
		end
	end
	return false
end

-- add focus
_HM_TargetList.AddFocus = function(dwID)
	if _HM_TargetList.IsFocus(dwID) then
		return
	end
	if #_HM_TargetList.tFocus >= HM_TargetList.nMaxFocus then
		local nRemove = 1
		for k, v in ipairs(_HM_TargetList.tFocus) do
			local h = HM.GetTarget(v)
			if not h then
				nRemove = k
				break
			end
		end
		-- protected focus people
		if nRemove == 1 then
			local dwFirst = _HM_TargetList.tFocus[1]
			if HM_TargetList.tPersistFocus[dwFirst] then
				nRemove = nRemove + 1
			end
		end
		table.remove(_HM_TargetList.tFocus, nRemove)
	end
	table.insert(_HM_TargetList.tFocus, dwID)
	_HM_TargetList.nFrameFocus = 0
	if not HM_TargetList.bShowFocus then
		HM_TargetList.bShowFocus = true
		_HM_TargetList.UpdateSize(true)
	end
	FireUIEvent("HM_ADD_FOCUS_TARGET", dwID, false)
end

-- del focus
_HM_TargetList.DelFocus = function(dwID)
	for k, v in ipairs(_HM_TargetList.tFocus) do
		if v == dwID then
			if not IsPlayer(dwID) then
				local npc = GetNpc(dwID)
				if npc then
					HM_TargetList.tPersistFocus[npc.szName] = nil
				end
			else
				HM_TargetList.tPersistFocus[dwID] = nil
			end
			table.remove(_HM_TargetList.tFocus, k)
			FireUIEvent("HM_DEL_FOCUS_TARGET", dwID)
			break
		end
	end
	_HM_TargetList.nFrameFocus = 0
end

-- set persist focus
_HM_TargetList.SetPersistFocus = function(dwID)
	_HM_TargetList.AddFocus(dwID)
	_HM_TargetList.nFrameFocus = 0
	if not IsPlayer(dwID) then
		local npc = GetNpc(dwID)
		if npc then
			HM_TargetList.tPersistFocus[npc.szName] = true
		end
	else
		HM_TargetList.tPersistFocus[dwID] = true
	end
end

-- switch focus
_HM_TargetList.SwitchFocus = function(dwID)
	if _HM_TargetList.IsFocus(dwID) then
		_HM_TargetList.DelFocus(dwID)
		if _HM_TargetList.frame then
			_HM_TargetList.frame:Lookup("Wnd_Focus"):Lookup("", "Image_FOver"):Hide()
		end
	else
		_HM_TargetList.AddFocus(dwID)
	end
end

-- set focus
_HM_TargetList.SetFocus = function()
	local dwID, tSelectObject = nil, Scene_SelectObject("nearest")
	if tSelectObject and (tSelectObject[1]["Type"] == TARGET.NPC or tSelectObject[1]["Type"] == TARGET.PLAYER) then
		dwID = tSelectObject[1]["ID"]
	end
	if not dwID then
		_, dwID = GetClientPlayer().GetTarget()
	end
	if dwID ~= 0 then
		_HM_TargetList.SwitchFocus(dwID)
	end
end

-- select focus
_HM_TargetList.SelFocus = function()
	local _, tarID = GetClientPlayer().GetTarget()
	local dwID = nil
	for _, v in ipairs(_HM_TargetList.tFocus) do
		if HM.GetTarget(v) ~= nil then
			if tarID == 0 then
				dwID = v
				break
			elseif tarID == v then
				tarID = 0
			elseif not dwID then
				dwID = v
			end
		end
	end
	if dwID then
		HM.SetTarget(dwID)
	end
end

-- get add/del menu
_HM_TargetList.GetFocusItemMenu = function(dwID)
	if _HM_TargetList.IsFocus(dwID) then
		return { szOption = _L["Remove from HM focus"], fnAction = function() _HM_TargetList.DelFocus(dwID) end }
	else
		return { szOption = _L["Add to HM foucs"], fnAction = function() _HM_TargetList.AddFocus(dwID) end }
	end
end

-- simple number
_HM_TargetList.GetSimpleNum = function(n)
	if n < 10000 then
		return tostring(n)
	elseif n < 1000000 then
		return _L("%.1fw", n / 10000)
	elseif n < 100000000 then
		return _L("%dw", n / 10000)
	else
		return _L("%db", n / 100000000)
	end
end

-- get color
_HM_TargetList.GetForceFontColor = function(tar, myID, bFocus)
	if tar.dwID == myID then
		return 0, 200, 72
	elseif tar.nMoveState == MOVE_STATE.ON_DEATH then
		return 160, 160, 160
	end
	-- special PLAYER for 城战
	if tar.nNpc and tar.nNpc > 0 then
		if IsEnemy(myID, tar.dwID) then
			return 255, 0, 255
		end
		return 0, 255, 255
	end
	if not bFocus and HM_TargetList.bListWhite
		and HM_TargetList.nListMode ~= 1 and HM_TargetList.nListMode ~= 4
	then
		return 255, 255, 255
	end
	if IsEnemy(myID, tar.dwID) then
		return 255, 126, 126
	end
	return GetForceFontColor(tar.dwID, myID)
end

-- update gps info
_HM_TargetList.UpdateFocusGPS = function(h, tar)
	local me = GetClientPlayer()
	if tar.nX == me.nX then
		h:SetRotate(0)
	else
		local dwRad1 = math.atan((tar.nY - me.nY) / (tar.nX - me.nX))
		if dwRad1 < 0 then
			dwRad1 = dwRad1 + math.pi
		end
		if tar.nY < me.nY then
			dwRad1 = math.pi + dwRad1
		end
		local dwRad2 = me.nFaceDirection / 128 * math.pi
		h:SetRotate(1.5 * math.pi + dwRad2 - dwRad1)
	end
end

-- get skill prepare
_HM_TargetList.GetSkillPrepareState = function(tar)
	local _, dwSkillID, dwLevel, fP = tar.GetSkillPrepareState()
	if not dwSkillID and HM_TargetList.bMonPrepare and (not IsPlayer(tar.dwID) or tar.GetOTActionState() == 1) then
		local dwType, dwID = GetClientPlayer().GetTarget()
		HM.SetInsTarget(tar.dwID)
		_, dwSkillID, dwLevel, fP = tar.GetSkillPrepareState()
		HM.SetTarget(dwType, dwID)
	end
	if dwSkillID and dwSkillID ~= 0 then
		local szSkill = HM.GetSkillName(dwSkillID, dwLevel)
		return szSkill, fP
	end
end

-- update mana/skill info
_HM_TargetList.UpdateFocusMana = function(h, tar)
	local hImg, hText = h:Lookup("Image_Mana"), h:Lookup("Text_Mana")
	-- check prepare/channel skill
	local szSkill, fP = _HM_TargetList.GetSkillPrepareState(tar)
	if not szSkill and IsPlayer(tar.dwID) and tar.GetOTActionState() == 2 and HM_Target then
		szSkill, fP = HM_Target.GetSkillChannelState(tar.dwID)
	end
	-- skill result
	if not hText.font then
		hText.font = hText:GetFontScheme()
	end
	if szSkill then
		hImg:SetPercentage(fP)
		hImg:SetFrame(86)
		hImg:Show()
		hText:SetText(szSkill)
		hText:SetFontScheme(18)
		hText:Show()
		return
	end
	-- check mana
	local nCur, nMax, nFrame, mnt = tar.nCurrentMana, tar.nMaxMana, 42, nil
	if IsPlayer(tar.dwID) then
		mnt = tar.GetKungfuMount()
	end
	if mnt and mnt.dwMountType == 10 then
		nCur, nMax, nFrame = tar.nCurrentEnergy, tar.nMaxEnergy, 87
	elseif mnt and mnt.dwMountType == 6 and tar.nMaxRage > 0 then
		nCur, nMax, nFrame = tar.nCurrentRage, tar.nMaxRage, 87
	elseif mnt and mnt.dwMountType == 8 then
		-- 日月能量哪个较多优先哪个，日：86，月：84
		if tar.nSunPowerValue == 1 then
			nCur, nMax, nFrame = tar.nMaxSunEnergy, tar.nMaxSunEnergy, 86
		elseif tar.nMoonPowerValue == 1 then
			nCur, nMax, nFrame = tar.nMaxMoonEnergy, tar.nMaxMoonEnergy, 84
		else
			local fS = tar.nCurrentSunEnergy / tar.nMaxSunEnergy
			local fM = tar.nCurrentMoonEnergy / tar.nMaxMoonEnergy
			if fM < fS then
				nCur, nMax, nFrame = tar.nCurrentSunEnergy, tar.nMaxSunEnergy, 86
			else
				nCur, nMax, nFrame = tar.nCurrentMoonEnergy, tar.nMaxMoonEnergy, 84
			end
		end
	end
	if nMax > 0 then
		local fP = math.min(1, nCur / nMax)
		hImg:SetPercentage(fP)
		hImg:SetFrame(nFrame)
		hImg:Show()
		hText:SetFontScheme(hText.font)
		hText:SetText(_HM_TargetList.GetSimpleNum(nMax) .. "(" .. math.ceil(100 * fP) .. "%)")
	else
		hImg:Hide()
		hText:SetText("")
	end
	if not hText.bIn then
		hText:Hide()
	end
end

-- update focus item
_HM_TargetList.UpdateFocusItem = function(h, tar)
	local me = GetClientPlayer()
	-- update mark image
	local hImg, nIconFrame = h:Lookup("Image_Mark"), _HM_TargetList.tPartyMark[tar.dwID]
	if nIconFrame then
		nIconFrame = PARTY_MARK_ICON_FRAME_LIST[nIconFrame]
		hImg:SetFrame(nIconFrame)
		hImg:Show()
	else
		hImg:Hide()
	end
	-- update camp image
	hImg, nIconFrame = h:Lookup("Image_Camp"), nil
	if tar.nCamp == CAMP.EVIL then
		nIconFrame = 5
	elseif tar.nCamp == CAMP.GOOD then
		nIconFrame = 7
	else
		hImg:Hide()
	end
	if nIconFrame then
		hImg:SetFrame(nIconFrame)
		hImg:Show()
	end
	-- update compass
	_HM_TargetList.UpdateFocusGPS(h:Lookup("Image_Compass"), tar)
	-- update distance
	local hDis, nDis = h:Lookup("Text_Distance"), HM.GetDistance(tar)
	if nDis < 100 then
		hDis:SetText(string.format("%.1f", nDis))
	else
		hDis:SetText(string.format("%d", nDis))
	end
	-- update level
	local hLvl = h:Lookup("Text_Level")
	if hLvl then
		if tar.nLevel and tar.nLevel > 0 then
			hLvl:SetFontScheme(GetTargetLevelFont(tar.nLevel - me.nLevel))
			hLvl:SetText(tostring(tar.nLevel))
		else
			hLvl:SetText("")
		end
	end
	-- update force/mount
	hImg = h:Lookup("Image_Force")
	if HM_TargetDir then
		HM_TargetDir.SetHeadImage(hImg, tar)
	else
		hImg:Hide()
	end
	-- update name, color
	local hText = h:Lookup("Text_Name")
	if hDis:IsVisible() then
		hText:SetText(HM.GetTargetName(tar))
	else
		hText:SetText(hDis:GetText() .. _L["-"] .. HM.GetTargetName(tar))
	end
	hText:SetFontColor(_HM_TargetList.GetForceFontColor(tar, me.dwID, true))
	-- update life
	hImg, hText = h:Lookup("Image_Life"), h:Lookup("Text_Life")
	if tar.nMaxLife > 0 then
		local fP = math.min(1, tar.nCurrentLife / tar.nMaxLife)
		local szHp = "100"
		if fP < 1 then
			szHp = string.format("%.1f", fP * 100)
		end
		hImg:SetPercentage(fP)
		hText:SetText(_HM_TargetList.GetSimpleNum(tar.nMaxLife) .. "(" .. szHp .. "%)")
	else
		hImg:Hide()
		hText:SetText("")
	end
	-- update mana/prepare
	_HM_TargetList.UpdateFocusMana(h, tar)
	-- focus target
	local hText, szText = h:Lookup("Text_Target"), ""
	if HM_TargetList.bFocusTarget2 then
		local ttar = GetTargetHandle(tar.GetTarget())
		if ttar then
			szText = HM.GetTargetName(ttar)
			hText.dwID = ttar.dwID
		else
			szText = ""
			hText.dwID = nil
		end
	end
	hText:SetText(szText)
	-- update state(box)
	if HM_TargetDir then
		local dwIcon, szText
		local hBox, hText = h:Lookup("Box_State"), h:Lookup("Text_State")
		local dwIcon, szText, buff = HM_TargetDir.GetState(tar, true)
		if not dwIcon then
			hBox:Hide()
			hText:SetText("")
		else
			if not buff then
				hBox.dwID = nil
				hBox:SetOverText(0, "")
				hBox:SetOverText(1, "")
			else
				hBox.dwID, hBox.nLevel = buff.dwID, buff.nLevel
				if buff.nStackNum > 1 then
					hBox:SetOverText(0, buff.nStackNum)
				else
					hBox:SetOverText(0, "")
				end
				local nSec = (buff.nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
				if nSec < 3600 then
					hBox:SetOverText(1, string.format("%d\"", nSec))
				else
					hBox:SetOverText(1, "")
				end
				hBox.dwOwner = tar.dwID
			end
			hText:SetText(szText)
			if buff and not buff.bCanCancel then
				hText:SetFontScheme(159)
			else
				hText:SetFontScheme(16)
			end
			hBox:SetObjectIcon(dwIcon)
			hBox:Show()
		end
	end
	-- update slect image
	local _, tarID = me.GetTarget()
	if tarID == tar.dwID and not h.alone then
		local hTotal = _HM_TargetList.frame:Lookup("Wnd_Focus"):Lookup("", "")
		local hOver = hTotal:Lookup("Image_FSelect")
		hOver:SetRelPos(0, h:GetIndex() * 63 - 3)
		hOver:Show()
		hTotal:FormatAllItemPos()
	end
end

-- create focus item
_HM_TargetList.NewFocusItem = function(handle, dwID)
	local h
	if HM_TargetList.bFocusOld then
		h = handle:AppendItemFromIni(_HM_TargetList.szIniFile2, "Handle_Focuser", "Focus_" .. dwID)
	else
		h = handle:AppendItemFromIni(_HM_TargetList.szIniFile, "Handle_Focuser", "Focus_" .. dwID)
	end
	local box = h:Lookup("Box_State")
	box:SetOverTextFontScheme(0, 15)
	box:SetOverTextFontScheme(1, 16)
	box:SetOverTextPosition(1, 3)
	box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
	box.OnItemMouseEnter = function()
		this:SetObjectMouseOver(1)
		if this.dwID then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputBuffTip(this.dwOwner, this.dwID, this.nLevel, 1, false, 0, { x, y, w, h })
		end
	end
	box.OnItemMouseLeave = function()
		this:SetObjectMouseOver(0)
		HideTip()
	end
	return h
end

-- update focus items
_HM_TargetList.UpdateFocusItems = function(handle)
	-- load focus target
	local tFocus = {}
	for k, v in ipairs(_HM_TargetList.tFocus) do
		local tar = HM.GetTarget(v)
		if tar then
			tFocus[v] = tar
		end
	end
	-- clear select
	handle:GetParent():Lookup("Image_FSelect"):Hide()
	-- exists list
	_HM_TargetList.tPartyMark = {}
	if GetClientPlayer().IsInParty() then
		_HM_TargetList.tPartyMark = GetClientTeam().GetTeamMark() or {}
	end
	for i = handle:GetItemCount() - 1, 0, -1 do
		local h = handle:Lookup(i)
		if not tFocus[h.dwID] then
			handle:RemoveItem(i)
		else
			_HM_TargetList.UpdateFocusItem(h, tFocus[h.dwID])
			tFocus[h.dwID] = nil
		end
	end
	-- new list
	for _, v in pairs(tFocus) do
		local h = _HM_TargetList.NewFocusItem(handle, v.dwID)
		h.dwID, h.szName = v.dwID, v.szName
		h:Show()
		_HM_TargetList.UpdateFocusItem(h, v)
	end
end

-- hook target menu
_HM_TargetList.HookTargetMenu = function()
	Target_AppendAddonMenu({ function(dwID)
		return {
			_HM_TargetList.GetFocusItemMenu(dwID),
			{ szOption = _L["Set as persist focus"], fnAction = function() _HM_TargetList.SetPersistFocus(dwID) end },
			{ szOption = _L["Lock as single focus"], fnAction = function() HM_SingleFocus.Lock(dwID) end }
		}
	end })
end

---------------------------------------------------------------------
-- 目标列表
---------------------------------------------------------------------
_HM_TargetList.tListMode = {
	_L["All NPC"], _L["Ally NPC"], _L["Enemy NPC"],	-- 1 ~ 3
	_L["All players"], _L["Ally players"], _L["Enemy players"],	-- 4 ~ 6
}

-- set far threshold
_HM_TargetList.SetFarThreshold = function()
	GetUserInput(_L["Please set the long distance threshold"], function(szText)
		local nDis = tonumber(szText)
		if nDis then
			HM_TargetList.nFarThreshold = nDis
		end
	end, nil, nil, nil, tostring(HM_TargetList.nFarThreshold), 5, true)
end

-- get list menu
_HM_TargetList.GetListMenu = function()
	local m0 = {}
	local m1 = { szOption = _L["View mode of list"] }
	for k, v in ipairs (_HM_TargetList.tListMode) do
		table.insert(m1, { szOption = v, bCheck = true, bMCheck = true, bChecked = k == HM_TargetList.nListMode, fnAction = function()
			HM_TargetList.nListMode = k
			_HM_TargetList.bCustom = false
			_HM_TargetList.UpdateList()
		end })
	end
	table.insert(m0, m1)
	table.insert(m0, { szOption = _L["View options of list"],
		{ szOption = _L["Show level"], bCheck = true, bChecked = HM_TargetList.tShowMode.bLevel,
			fnAction = function(d, b) HM_TargetList.tShowMode.bLevel = b end
		}, { szOption = _L["Show HP"], bCheck = true, bChecked = HM_TargetList.tShowMode.bHP,
			fnAction = function(d, b) HM_TargetList.tShowMode.bHP = b end
		}, { szOption = _L["Show distance"], bCheck = true, bChecked = HM_TargetList.tShowMode.bDistance,
			fnAction = function(d, b) HM_TargetList.tShowMode.bDistance = b end
		}, { szOption = _L["Show player school"], bCheck = true, bChecked = HM_TargetList.tShowMode.bForce,
			fnAction = function(d, b) HM_TargetList.tShowMode.bForce = b end
		}, { szOption = _L["Show only up to 25"], bCheck = true, bChecked = HM_TargetList.tShowMode.bOnly25,
			fnAction = function(d, b) HM_TargetList.tShowMode.bOnly25 = b end
		}
	})
	table.insert(m0, { szOption = _L["Set list order"],
		{ szOption = _L["Not sort"], bCheck = true, bMCheck = true, bChecked = HM_TargetList.nSortType == 0,
			fnAction = function() HM_TargetList.nSortType = 0 end
		}, { szOption = _L["Priority less HP"], bCheck = true, bMCheck = true, bChecked = HM_TargetList.nSortType == 1,
			fnAction = function() HM_TargetList.nSortType = 1 end,
			{ szOption = _L["Rear not oriented"], bCheck = true, bChecked = HM_TargetList.bDownFace,
				fnAction = function(d, b) HM_TargetList.bDownFace = b end
			}, { szOption = _L["Rear"] .. HM_TargetList.nFarThreshold .. _L["feet far"], bCheck = true, bChecked = HM_TargetList.bDownFar,
				fnAction = function(d, b) HM_TargetList.bDownFar = b end,
				{ szOption = _L["Edit distance"], fnAction = _HM_TargetList.SetFarThreshold },
			}
		}, { szOption = _L["Priority closer"], bCheck = true, bMCheck = true, bChecked = HM_TargetList.nSortType == 2,
			fnAction = function() HM_TargetList.nSortType = 2 end
		}, { bDevide = true,
		}, { szOption = _L["Sticky treat player"], bCheck = true, bChecked = HM_TargetList.bUpTreat,
			fnAction = function(d, b) HM_TargetList.bUpTreat = b end
		}, { szOption = _L["Rear dead player"], bCheck = true, bChecked = HM_TargetList.bDownDeath,
			fnAction = function(d, b) HM_TargetList.bDownDeath = b end
		}
	})
	-- filter npc
	local m1 = { szOption = _L["Temporarily filter NPC"], {
		szOption = _L["* New *"], fnAction = function()
			GetUserInput(_L["Enter NPC name to filter"], function(szText)
				_HM_TargetList.tFilterNpc[szText] = true
			end)
		end,
	}, {
		bDevide = true
	} }
	for k, v in pairs(_HM_TargetList.tFilterNpc) do
		table.insert(m1, { szOption = k, bCheck = true, bChecked = v,
			fnAction = function(d, b) _HM_TargetList.tFilterNpc[k] = b end, {
				szOption = _L["Remove"], fnAction = function() _HM_TargetList.tFilterNpc[k] = nil end
			}
		})
	end
	table.insert(m0, m1)
	-- custom
	local m1 = { szOption = _L["Enable custom option"],
		bCheck = true, bChecked = _HM_TargetList.bCustom,
		fnAction = function(d, b)
			_HM_TargetList.bCustom = b
			_HM_TargetList.UpdateListTitle()
		end
	}
	-- custom name
	local m2 = { szOption = _L["Target name"],  {
		szOption = _L["* New *"], fnAction = function()
			GetUserInput(_L["Enter target name to display"], function(szText)
				HM_TargetList.tCustomName[szText] = true
			end)
		end,
	}, { bDevide = true,
	} }
	for k, v in pairs(HM_TargetList.tCustomName) do
		table.insert(m2, { szOption = k, bCheck = true, bChecked = v,
			fnAction = function(d, b) HM_TargetList.tCustomName[k] = b end, {
				szOption = _L["Remove"], fnAction = function() HM_TargetList.tCustomName[k] = nil end
			}
		})
	end
	table.insert(m1, m2)
	-- custom tong
	local m2 = { szOption = _L["Guild name"],  {
		szOption = _L["* New *"], fnAction = function()
			GetUserInput(_L["Enter guild name to display"], function(szText)
				HM_TargetList.tCustomTong[szText] = true
			end)
		end,
	}, { bDevide = true,
	} }
	for k, v in pairs(HM_TargetList.tCustomTong) do
		table.insert(m2, { szOption = k, bCheck = true, bChecked = v,
			fnAction = function(d, b) HM_TargetList.tCustomTong[k] = b end, {
				szOption = _L["Remove"], fnAction = function() HM_TargetList.tCustomTong[k] = nil end
			}
		})
	end
	table.insert(m1, m2)
	-- custom force
	local m2 = { szOption = _L["School force"] }
	for i = 0, 10 do
		table.insert(m2, { szOption = g_tStrings.tForceTitle[i], bCheck = true, bChecked = HM_TargetList.tCustomForce[i] == true,
			fnAction = function(d, b) HM_TargetList.tCustomForce[i] = b end
		})
	end
	table.insert(m1, m2)
	-- custom save
	table.insert(m1, { bDevide = true })
	local m2 = { szOption = _L["Save/Load setting"], {
		szOption = _L["* Save *"], fnAction = function()
			GetUserInput(_L["Enter setting name"], function(szText)
				local t = {}
				for _, v in ipairs({ "tCustomName", "tCustomTong", "tCustomForce" }) do
					t[v] = clone(HM_TargetList[v])
				end
				HM_TargetList.tCustomSave[szText] = t
				HM.Sysmsg(_L("Custom list saved [%s]", szText))
			end)
		end
	}, { bDevide = true,
	} }
	for k, v in pairs(HM_TargetList.tCustomSave) do
		table.insert(m2, { szOption = k, {
			szOption = _L["Load..."],
			fnAction = function()
				for kk, vv in pairs(v) do HM_TargetList[kk] = clone(vv) end
				_HM_TargetList.bCustom = true
				HM.Sysmsg(_L("Applied custom list [%s]", k))
			end
		}, {
			szOption = _L["Remove"],
			fnAction = function() HM_TargetList.tCustomSave[k] = nil end
		} })
	end
	table.insert(m1, m2)
	table.insert(m0, m1)
	table.insert(m0, { szOption = _L["Keep foucs in list"], bCheck = true, bChecked = HM_TargetList.bListFocus,
		fnDisable = function() return not HM_TargetList.bShowList end,
		fnAction = function() HM_TargetList.bListFocus = not HM_TargetList.bListFocus end,
	})
	table.insert(m0, { szOption = _L["Use white text in list"], bCheck = true, bChecked = HM_TargetList.bListWhite,
		fnDisable = function() return not HM_TargetList.bShowList end,
		fnAction = function() HM_TargetList.bListWhite = not HM_TargetList.bListWhite end,
	})
	return m0
end

-- update list title
_HM_TargetList.UpdateListTitle = function()
	if  _HM_TargetList.frame then
		local ttl = _HM_TargetList.frame:Lookup("Wnd_List"):Lookup("", "Text_LTitle")
		local txt = _HM_TargetList.tListMode[HM_TargetList.nListMode]
		if _HM_TargetList.bCustom then
			txt = _L["[Custom]"] .. txt
		end
		ttl:SetText(txt)
	end
end

-- update list
_HM_TargetList.UpdateList = function()
	if HM_TargetList.bShowList and not _HM_TargetList.bCollapse then
		local win = _HM_TargetList.frame:Lookup("Wnd_List")
		_HM_TargetList.UpdateListTitle()
		if HM_TargetList.nListMode > 1 then
			win:Lookup("Btn_Left"):Enable(1)
		else
			win:Lookup("Btn_Left"):Enable(0)
		end
		if HM_TargetList.nListMode < #_HM_TargetList.tListMode then
			win:Lookup("Btn_Right"):Enable(1)
		else
			win:Lookup("Btn_Right"):Enable(0)
		end
		_HM_TargetList.nFrameList = 0
	end
end

-- update list scroll
_HM_TargetList.UpdateListScroll = function()
	local win = _HM_TargetList.frame:Lookup("Wnd_List")
	local handle, scroll = win:Lookup("", "Handle_List"), win:Lookup("Scroll_List")
	local w, h = handle:GetSize()
	local wA, hA = handle:GetAllItemSize()
	local nStep = math.ceil((hA - h) / 10)
	scroll:SetStepCount(nStep)
	if nStep > 0 then
		scroll:Show()
	else
		scroll:Hide()
	end
	if scroll:GetScrollPos() > nStep then
		scroll:SetScrollPos(nStep)
	end
end

-- get rel angle
_HM_TargetList.GetRelAngle = function(me, tar)
	local nX, nY = tar.nX - me.nX, tar.nY - me.nY
	local nDeg, nFace =  0, me.nFaceDirection / 256 * 360
	if nY == 0 then
		if nX < 0 then
			nDeg = 180
		end
	elseif nX == 0 then
		if nY > 0 then
			nDeg = 90
		else
			nDeg = 270
		end
	else
		nDeg = math.deg(math.atan(nY / nX))
		if nX < 0 then
			nDeg = 180 + nDeg
		elseif nY < 0 then
			nDeg = 360 + nDeg
		end
	end
	local nAngle = nFace - nDeg
	if nAngle < -180 then
		nAngle = nAngle + 360
	elseif nAngle > 180 then
		nAngle = nAngle - 360
	end
	return math.abs(nAngle)
end

-- check is treat force
_HM_TargetList.IsTreatForce = function(dwForceID)
	return dwForceID == 2 or dwForceID == 5 or dwForceID == 6
end

-- compare list item
_HM_TargetList.ListItemCompare = function(a, b)
	if not a or not b then
		return true
	end
	-- up special PLAYER for 城战
	if a.nNpc > 0 or b.nNpc > 0 then
		return b.nNpc < a.nNpc
	end
	-- down death
	if HM_TargetList.bDownDeath then
		if a.nMoveState == MOVE_STATE.ON_DEATH and b.nMoveState ~= MOVE_STATE.ON_DEATH then
			return false
		elseif a.nMoveState ~= MOVE_STATE.ON_DEATH and b.nMoveState == MOVE_STATE.ON_DEATH then
			return true
		end
	end
	-- up treat
	if HM_TargetList.bUpTreat then
		local b1, b2 = _HM_TargetList.IsTreatForce(a.dwForceID), _HM_TargetList.IsTreatForce(b.dwForceID)
		if b1 and not b2 then
			return true
		elseif not b1 and b2 then
			return false
		end
	end
	-- down far, down face, HP
	if HM_TargetList.nSortType == 1 then
		if HM_TargetList.bDownFar then
			if a.nDis <= HM_TargetList.nFarThreshold and b.nDis > HM_TargetList.nFarThreshold then
				return true
			elseif a.nDis > HM_TargetList.nFarThreshold and b.nDis <= HM_TargetList.nFarThreshold then
				return false
			end
		end
		if HM_TargetList.bDownFace then
			if a.nAngle <= 80 and b.nAngle > 80 then
				return true
			elseif a.nAngle > 80 and b.nAngle <= 80 then
				return false
			end
		end
		if a.nHP == b.nHP then
			return a.nMaxLife < b.nMaxLife
		end
		return a.nHP < b.nHP
	elseif HM_TargetList.nSortType == 2 then
		return a.nDis < b.nDis
	end
	return a.nIndex < b.nIndex
end

-- check list item
_HM_TargetList.CheckListItem = function(tar, nMode)
	local szName = HM.GetTargetName(tar)
	if szName == "" or (nMode <= 3 and _HM_TargetList.tFilterNpc[szName]) then
		return false
	end
	if nMode <= 3 and tar.dwTemplateID >= 28001 and tar.dwTemplateID <= 36001 then
		return true
	end
	if nMode <= 3 and not tar.IsSelectable() and not _HM_TargetList.bCustom then
		return false
	end
	if not HM_TargetList.bListFocus and _HM_TargetList.IsFocus(tar.dwID) then
		return false
	end
	local myID = GetClientPlayer().dwID
	if (nMode == 2 or nMode == 5) and myID ~= tar.dwID and not IsAlly(myID, tar.dwID) then
		return false
	end
	if (nMode == 3 or nMode == 6) and not IsEnemy(myID, tar.dwID) then
		return false
	end
	local bOK = true
	if _HM_TargetList.bCustom then
		for k, v in pairs(HM_TargetList.tCustomName) do
			if v then
				if k == szName then
					return true
				end
				bOK = false
			end
		end
		if nMode >= 4 then
			local tong = GetTongClient()
			for k, v in pairs(HM_TargetList.tCustomTong) do
				if v then
					if (k == "NONE" or k == "none") and tar.dwTongID == 0 then
						return true
					end
					if tar.dwTongID ~= 0 and k == tong.ApplyGetTongName(tar.dwTongID) then
						return true
					end
					bOK = false
				end
			end
			for k, v in pairs(HM_TargetList.tCustomForce) do
				if v then
					if k == tar.dwForceID then
						return true
					end
					bOK = false
				end
			end
		end
	end
	return bOK
end

-- update list items
_HM_TargetList.UpdateListItems = function(handle)
	-- load data, sort
	local aList = {}
	local bHP = HM_TargetList.tShowMode.bHP or HM_TargetList.nSortType == 1
	local bDis = HM_TargetList.tShowMode.bDistance or HM_TargetList.nSortType == 2 or (HM_TargetList.nSortType == 1 and HM_TargetList.bDownFar)
	local bFace = HM_TargetList.nSortType == 1 and HM_TargetList.bDownFace
	local aItem, me, nMode = {}, GetClientPlayer(), HM_TargetList.nListMode
	local bXGF = false
	if nMode <= 3 then
		aList = HM.GetAllNpc()
	else
		local t = TimeToDate(GetCurrentTime())
		if (t.weekday == 2 or t.weekday == 4) and t.hour >= 20 and t.hour < 22 then
			bXGF = true
		end
		aList = HM.GetAllPlayer()
	end
	for _, v in ipairs(aList) do
		if _HM_TargetList.CheckListItem(v, nMode) then
			local item = {
				dwID = v.dwID, nMoveState = v.nMoveState,
				szName = HM.GetTargetName(v), nLevel = v.nLevel,
				dwForceID = v.dwForceID,
				nNpc = 0,
			}
			if nMode <= 3 then
				item.dwEmployer = v.dwEmployer
			elseif bXGF == true then
				-- check 城战 BUFF：神机台-耐久=7816/ 无法移动=7360，神机车：摧城=7716，旗手：守卫据点=7561
				for i = 0, v.GetBuffCount() - 1, 1 do
					local dwBuffID = v.GetBuff(i)
					if dwBuffID == 7561 then
						item.nNpc = 4
					elseif dwBuffID == 7816 then
						item.nNpc = 3
						break
					elseif dwBuffID == 7716 then
						item.nNpc = 2
						break
					elseif dwBuffID == 7360 then
						item.nNpc = 1
					end
				end
			end
			item.nIndex = #aItem + 1
			if bHP then
				item.nMaxLife = math.max(1, v.nMaxLife)
				item.nHP = math.min(100, math.ceil(v.nCurrentLife * 100 / v.nMaxLife))
			end
			if bDis then
				item.nDis = HM.GetDistance(v)
			end
			if bFace then
				item.nAngle = _HM_TargetList.GetRelAngle(me, v)
			end
			table.insert(aItem, item)
			if HM_TargetList.bOnly25 and #aItem == 25 then
				break
			end
		end
	end
	if #aItem > 1 then
		table.sort(aItem, _HM_TargetList.ListItemCompare)
	end
	-- sync list
	local nCount, nSelect, tarID, nLive = handle:GetItemCount(), 0, 0, 0
	if #aItem > 0 then
		_, tarID = me.GetTarget()
	end
	for k, v in ipairs(aItem) do
		local h, szText = nil, HM.GetTargetName(v)
		if HM_TargetList.tShowMode.bForce and nMode >= 4 then
			szText = "[" .. g_tStrings.tForceTitle[v.dwForceID] .. "]" .. szText
		end
		if HM_TargetList.tShowMode.bLevel and v.nLevel then
			szText = "(" .. v.nLevel .. ")" .. szText
		end
		if HM_TargetList.tShowMode.bDistance then
			szText = szText .. "<" .. string.format("%.1f", v.nDis) .. ">"
		end
		if HM_TargetList.tShowMode.bHP then
			szText = szText .. " " .. v.nHP .. "%"
		end
		if k <= nCount then
			h = handle:Lookup(k - 1)
		else
			h = handle:AppendItemFromIni(_HM_TargetList.szIniFile, "Handle_Lister", "List_" .. k)
			h:Show()
		end
		h.dwID, h.szName, h.bList = v.dwID, v.szName, true
		h:Lookup("Text_Player"):SetText(szText)
		h:Lookup("Text_Player"):SetFontColor(_HM_TargetList.GetForceFontColor(v, me.dwID))
		if v.dwID == tarID then
			nSelect = k
		end
		if v.nMoveState ~= MOVE_STATE.ON_DEATH then
			nLive = nLive + 1
		end
	end
	for i = nCount - 1, #aItem, -1 do
		handle:RemoveItem(i)
	end
	-- update count
	handle:GetParent():Lookup("Text_LCount"):SetText(nLive .. "/" .. #aItem)
	-- update active
	local hSel = handle:GetParent():Lookup("Image_LSelect")
	hSel:Hide()
	if nSelect > 0 then
		local nOff = _HM_TargetList.frame:Lookup("Wnd_List/Scroll_List"):GetScrollPos() * 10
		local nY = (nSelect - 1) * 20 - nOff
		if nY >= 0 and nY <= 180 then
			local nX, _ = hSel:GetRelPos()
			hSel:SetRelPos(nX, nY)
			hSel:Show()
			hSel:GetParent():FormatAllItemPos()
		end
	end
end

-- switch target list
_HM_TargetList.Switch = function(bShow)
	if bShow == nil then
		if _HM_TargetList.ui then
			return _HM_TargetList.ui:Fetch("Check_Show"):Check(not HM_TargetList.bShow)
		end
		HM_TargetList.bShow = not HM_TargetList.bShow
	end
	local frame = Station.Lookup("Normal/HM_TargetList")
	if HM_TargetList.bShow then
		if not frame then
			frame = Wnd.OpenWindow(_HM_TargetList.szIniFile, "HM_TargetList")
		end
	elseif frame then
		Wnd.CloseWindow(frame)
		_HM_TargetList.frame = nil
	end
end

-- arean monitor
_HM_TargetList.MonitorArena = function(szMsg)
	if StringFindW(szMsg, _L["Arean begin!!!"]) or StringFindW(szMsg, _L["Battle begin."]) then
		_HM_TargetList.nBeginArena = GetLogicFrameCount()
		--UnRegisterMsgMonitor(_HM_TargetList.MonitorArena, {"MSG_SYS"})
	end
end

-- account info
_HM_TargetList.GetAcctInfo = function()
	local aList, me = HM.GetAllPlayer(), GetClientPlayer()
	local tAcct  = {
		Enemy  = { live = 0, dead = 0, total = 0 },
		Ally  = { live = 0, dead = 0, total = 0 },
		Neutral = { live = 0, dead = 0, total = 0 },
	}
	for _, v in ipairs(aList) do
		local t = tAcct.Neutral
		if IsEnemy(me.dwID, v.dwID) then
			t = tAcct.Enemy
		elseif IsAlly(me.dwID, v.dwID) or me.dwID == v.dwID then
			t = tAcct.Ally
		end
		t.total = t.total + 1
		if v.nMoveState == MOVE_STATE.ON_DEATH then
			t.dead = t.dead + 1
		else
			t.live = t.live + 1
		end
	end
	return tAcct
end

_HM_TargetList.ShowAcctInfo = function()
	local nChannel, szName = EditBox_GetChannel()
	local t, nCamp = _HM_TargetList.GetAcctInfo(), GetClientPlayer().nCamp
	local tLine = {}
	if t.Enemy.total > 0 then
		local nCamp2 = (nCamp + nCamp) % 3
		local szText = g_tStrings.STR_CAMP_TITLE[nCamp2] .. _L["Enemy"]
		szText = szText .. _L(": Live(%d) Dead(%d) Total(%d)", t.Enemy.live, t.Enemy.dead, t.Enemy.total)
		table.insert(tLine, szText)
	end
	if t.Ally.total > 0 then
		local szText = g_tStrings.STR_CAMP_TITLE[nCamp] .. _L["Ally"]
		szText = szText .. _L(": Live(%d) Dead(%d) Total(%d)", t.Ally.live, t.Ally.dead, t.Ally.total)
		table.insert(tLine, szText)
	end
	if t.Neutral.total > 0 then
		local szText = _L["Neutral"] .. _L(": Live(%d) Dead(%d) Total(%d)", t.Neutral.live, t.Neutral.dead, t.Neutral.total)
		table.insert(tLine, szText)
	end
	if not HM.CanTalk(nChannel) or nChannel == PLAYER_TALK_CHANNEL.WHISPER or nChannel == PLAYER_TALK_CHANNEL.NEARBY then
		local szText = table.concat(tLine, "  ")
		tLine = { szText }
	end
	if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		nChannel = szName
	end
	for _, v in ipairs(tLine) do
		HM.Talk2(nChannel, v)
	end
end

_HM_TargetList.UpdateAcctInfo = function()
	local h = _HM_TargetList.frame:Lookup("Wnd_Account", "")
	local t = _HM_TargetList.GetAcctInfo()
	if t.Enemy.total > 0 then
		h:Lookup("Text_Enemy"):SetText(_L["Enemy"] .. _L(": Live(%d) Dead(%d) Total(%d)", t.Enemy.live, t.Enemy.dead, t.Enemy.total))
	else
		h:Lookup("Text_Enemy"):SetText("")
	end
	if t.Ally.total > 0 then
		h:Lookup("Text_Ally"):SetText(_L["Ally"] .. _L(": Live(%d) Dead(%d) Total(%d)", t.Ally.live, t.Ally.dead, t.Ally.total))
	else
		h:Lookup("Text_Ally"):SetText("")
	end
	if t.Neutral.total > 0 then
		h:Lookup("Text_Other"):SetText(_L["Neutral"] .. _L(": Live(%d) Dead(%d) Total(%d)", t.Neutral.live, t.Neutral.dead, t.Neutral.total))
	else
		h:Lookup("Text_Other"):SetText("")
	end
end

---------------------------------------------------------------------
-- 窗口界面
---------------------------------------------------------------------
_HM_TargetList.UpdateAnchor = function()
	local frame, a = _HM_TargetList.frame, HM_TargetList.tAnchor
	if frame and not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	end
	frame:CorrectPos()
end

_HM_TargetList.UpdateSize = function(bFocusOnly)
	if not HM_TargetList.bShow then return end
	local frame, nY, nH = _HM_TargetList.frame, 30, 30
	local nW, _ = frame:Lookup("", "Image_Bg"):GetSize()
	local wFocus, wList, wAcct = frame:Lookup("Wnd_Focus"), frame:Lookup("Wnd_List"), frame:Lookup("Wnd_Account")
	if _HM_TargetList.bCollapse or not HM_TargetList.bShowFocus then
		wFocus:Hide()
	else
		nY = nY +  wFocus:Lookup("", "Handle_Focus"):GetItemCount() * 63
		if nY > 30 then
			nY = nY + 10
		end
		nH = nY
		wFocus:Show()
	end
	if _HM_TargetList.bCollapse or not HM_TargetList.bShowList then
		wList:Hide()
	else
		local _, xH = wList:GetSize()
		nY = nH + 5
		nH = nY + xH
		wList:SetRelPos(5, nY)
		wList:Show()
	end
	if _HM_TargetList.bCollapse or not HM_TargetList.bShowAcct then
		wAcct:Hide()
	else
		local _, xH = wAcct:GetSize()
		nY = nH + 5
		nH = nY + xH
		wAcct:SetRelPos(5, nY)
		wAcct:Show()
	end
	frame:Lookup("", "Image_Bg"):SetSize(nW, nH)
	if not bFocusOnly then
		_HM_TargetList.UpdateList()
	end
end

HM_TargetList.OnFrameCreate = function()
	_HM_TargetList.frame = this
	this:Lookup("", "Text_Title"):SetText(_L["HM Focus, TargetList"])
	-- events
	this:RegisterEvent("PLAYER_ENTER_SCENE")
	this:RegisterEvent("PLAYER_LEAVE_SCENE")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")
	this:RegisterEvent("UPDATE_SELECT_TARGET")
	this:RegisterEvent("UI_SCALED")
	-- adjust color of acct
	this:Lookup("Wnd_Account", "Text_Enemy"):SetFontColor(255, 0, 0)
	this:Lookup("Wnd_Account", "Text_Ally"):SetFontColor(0, 200, 72)
	this:Lookup("Wnd_Account", "Text_Other"):SetFontColor(255, 255, 0)
	-- update pos/size
	_HM_TargetList.UpdateAnchor()
	if _HM_TargetList.bCollapse then
		this:Lookup("Check_Minimize"):Check(true)
	else
		_HM_TargetList.UpdateSize()
	end
	-- update alpha bg
	this:Lookup("", "Image_Bg"):SetAlpha(math.ceil(HM_TargetList.nAlphaBg * 255 / 100))
end

HM_TargetList.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_TargetList.tAnchor = GetFrameAnchor(this)
end

HM_TargetList.OnFrameBreathe = function()
	if not GetClientPlayer() then return end
	local nFrame = GetLogicFrameCount()
	-- focus
	if not _HM_TargetList.bCollapse and HM_TargetList.bShowFocus
		and (nFrame - _HM_TargetList.nFrameFocus) > 1
	then
		local handle = this:Lookup("Wnd_Focus"):Lookup("", "Handle_Focus")
		local nCount = handle:GetItemCount()
		_HM_TargetList.UpdateFocusItems(handle)
		handle:FormatAllItemPos()
		if nCount ~= handle:GetItemCount() then
			_HM_TargetList.UpdateSize(true)
		end
		_HM_TargetList.nFrameFocus = nFrame
	end
	-- list
	if not _HM_TargetList.bCollapse and HM_TargetList.bShowList
		and (nFrame - _HM_TargetList.nFrameList) > 5
	then
		local handle = this:Lookup("Wnd_List"):Lookup("", "Handle_List")
		local nCount = handle:GetItemCount()
		_HM_TargetList.UpdateListItems(handle)
		handle:FormatAllItemPos()
		if nCount ~= handle:GetItemCount() then
			_HM_TargetList.UpdateListScroll()
		end
		_HM_TargetList.nFrameList = nFrame
	end
	-- acct
	if not _HM_TargetList.bCollapse and HM_TargetList.bShowAcct
		and (nFrame - _HM_TargetList.nFrameAcct) >= GLOBAL.GAME_FPS
	then
		_HM_TargetList.UpdateAcctInfo()
		_HM_TargetList.nFrameAcct = nFrame
	end
	-- check title
	if nFrame % 2 == 0 then
		if _HM_TargetList.nBeginArena then
			if not this.szTitle then
				this.szTitle = this:Lookup("", "Text_Title"):GetText()
			end
			local nSec = math.ceil((nFrame - _HM_TargetList.nBeginArena) / GLOBAL.GAME_FPS)
			this:Lookup("", "Text_Title"):SetText(_L["Arean ongoing: "] .. string.format("%d:%02d", nSec/60, nSec%60))
		elseif this.szTitle then
			this:Lookup("", "Text_Title"):SetText(this.szTitle)
			this.szTitle = nil
		end
	end
end

HM_TargetList.OnEvent = function(event)
	if event == "UI_SCALED" then
		_HM_TargetList.UpdateAnchor()
	elseif event == "UPDATE_SELECT_TARGET" then
		for _, v in ipairs({ "Target", "TargetTarget" }) do
			local frm = Station.Lookup("Normal/" .. v)
			if frm then
				local hnd = frm:Lookup("", "")
				if not hnd.OnItemLButtonUp then
					hnd:RegisterEvent(0x07)
					hnd.OnItemLButtonUp = function()
						if IsShiftKeyDown() and HM_TargetList.bAltFocus then
							_HM_TargetList.SwitchFocus(frm.dwID)
						end
					end
					if v == "TargetTarget" then
						hnd.OnItemRButtonDown = function()
							local menu = {}
							table.insert(menu, _HM_TargetList.GetFocusItemMenu(frm.dwID))
							table.insert(menu, { szOption = _L["Set as persist focus"], fnAction = function() _HM_TargetList.SetPersistFocus(frm.dwID) end })
							table.insert(menu, { szOption = _L["Lock as single focus"], fnAction = function() HM_SingleFocus.Lock(frm.dwID) end })
							PopupMenu(menu)
						end
					end
				end
			end
		end
	elseif event == "PLAYER_ENTER_SCENE" or event == "PLAYER_LEAVE_SCENE"
		or event == "NPC_ENTER_SCENE" or event == "NPC_LEAVE_SCENE"
	then
		-- auto focus in arean
		if HM_TargetList.bAutoArena and event == "PLAYER_ENTER_SCENE"
			and not _HM_TargetList.IsFocus(arg0) and IsEnemy(GetClientPlayer().dwID, arg0)
			and (IsInArena() or IsInSameQWG(arg0))
		then
			_HM_TargetList.AddFocus(arg0)
		end
		-- persist focus
		if not IsEmpty(HM_TargetList.tPersistFocus) then
			if event == "PLAYER_ENTER_SCENE" and HM_TargetList.tPersistFocus[arg0] then
				_HM_TargetList.AddFocus(arg0)
			elseif event == "NPC_ENTER_SCENE" then
				local npc = GetNpc(arg0)
				if npc and HM_TargetList.tPersistFocus[npc.szName] then
					_HM_TargetList.AddFocus(npc.dwID)
				end
			end
		end
		-- auto focus big boss
		if HM_TargetList.bAutoBigBoss and HM_Camp and event == "NPC_ENTER_SCENE"
			and not _HM_TargetList.IsFocus(arg0) and HM_Camp.IsCareNpc(GetNpc(arg0))
		then
			_HM_TargetList.AddFocus(arg0)
		end
		-- force flush
		if HM_TargetList.bShowFocus and _HM_TargetList.IsFocus(arg0) then
			_HM_TargetList.nFrameFocus = 0
		end
		if HM_TargetList.nListMode < 5 and (event == "NPC_ENTER_SCENE" or event == "NPC_LEAVE_SCENE") then
			_HM_TargetList.nFrameList = 0
		elseif HM_TargetList.nListMode > 4 and (event == "PLAYER_ENTER_SCENE" or event == "PLAYER_LEAVE_SCENE") then
			_HM_TargetList.nFrameList = 0
		end
	end
end

HM_TargetList.OnLButtonClick = function()
	local szName = this:GetName()
	if szName == "Btn_Left" then
		if HM_TargetList.nListMode > 1 then
			HM_TargetList.nListMode = HM_TargetList.nListMode - 1
			_HM_TargetList.bCustom = false
			_HM_TargetList.UpdateList()
		end
	elseif szName == "Btn_Right" then
		if HM_TargetList.nListMode < #_HM_TargetList.tListMode then
			HM_TargetList.nListMode = HM_TargetList.nListMode + 1
			_HM_TargetList.bCustom = false
			_HM_TargetList.UpdateList()
		end
	elseif szName == "Btn_Setting" then
		local m0 = {}
		table.insert(m0, { szOption = _L["Show focus target"], bCheck = true, bChecked = HM_TargetList.bShowFocus,
			fnAction = function(d, b)
				if _HM_TargetList.ui then
					_HM_TargetList.ui:Fetch("Check_Focus"):Check(b)
				else
					HM_TargetList.bShowFocus = b
					_HM_TargetList.UpdateSize(true)
				end
			end
		})
		table.insert(m0, { szOption = _L["Show target list"], bCheck = true, bChecked = HM_TargetList.bShowList,
			fnAction = function(d, b)
				if _HM_TargetList.ui then
					_HM_TargetList.ui:Fetch("Check_List"):Check(b)
				else
					HM_TargetList.bShowList = b
					_HM_TargetList.UpdateSize()
				end
			end
		})
		table.insert(m0, { szOption = _L["Show player statistics"], bCheck = true, bChecked = HM_TargetList.bShowAcct,
			fnAction = function(d, b)
				HM_TargetList.bShowAcct = b
				_HM_TargetList.UpdateSize()
			end
		})
		table.insert(m0, { bDevide = true, })
		local m1 = _HM_TargetList.GetFocusMenu()
		for _, v in ipairs(m1) do
			table.insert(m0, v)
		end
		local m1 = _HM_TargetList.GetListMenu()
		table.insert(m0, { bDevide = true, })
		for _, v in ipairs(m1) do
			table.insert(m0, v)
		end
		table.insert(m0, { bDevide = true, })
		table.insert(m0, { szOption = _L["Enable double click to focus fire"], bCheck = true, bChecked = HM_TargetList.bJihuo,
			fnDisable = function() return HM_Marker == nil end,
			fnAction = function() HM_TargetList.bJihuo = not HM_TargetList.bJihuo end
		})
		table.insert(m0, { szOption = _L["Publish nearby stats"], fnDisable = function() return HM_RedName == nil end,
			{ szOption = _L["Statistical by camp"], fnAction = function() HM_RedName.ShowAroundInfo(0) end },
			{ szOption = _L["Statistical by school"], fnAction = function() HM_RedName.ShowAroundInfo(1) end },
			{ szOption = _L["Statistical by guild"], fnAction = function() HM_RedName.ShowAroundInfo(2) end },
		})
		table.insert(m0, { szOption = _L["Background image opacity("] .. HM_TargetList.nAlphaBg .. ")", fnAction = function()
			local fX, fY = Cursor.GetPos()
			GetUserPercentage(function(f)
				HM_TargetList.nAlphaBg = math.ceil(100 * f)
				if _HM_TargetList.frame then
					_HM_TargetList.frame:Lookup("", "Image_Bg"):SetAlpha(math.ceil(f * 255))
				end
			end, nil, HM_TargetList.nAlphaBg / 100, _L["Adjust opacity of background"], { fX, fY, fX + 1, fY + 1 } )
		end })
		PopupMenu(m0)
	end
end

HM_TargetList.OnCheckBoxCheck = function()
	local szName = this:GetName()
	if szName == "Check_Minimize" then
		_HM_TargetList.bCollapse = true
		_HM_TargetList.UpdateSize()
	end
end

HM_TargetList.OnCheckBoxUncheck = function()
	local szName = this:GetName()
	if szName == "Check_Minimize" then
		_HM_TargetList.bCollapse = false
		_HM_TargetList.UpdateSize()
	end
end

HM_TargetList.OnScrollBarPosChanged = function()
	local nPos, win = this:GetScrollPos(), _HM_TargetList.frame:Lookup("Wnd_List")
	win:Lookup("", "Handle_List"):SetItemStartRelPos(0, - nPos * 10)
	_HM_TargetList.nFrameList = 0
end

HM_TargetList.OnItemMouseEnter = function()
	local szName = this:GetName()
	if szName == "Image_PlayerBg" or szName == "Text_Mana" then
		local hMana = this:GetParent():Lookup("Text_Mana")
		if hMana then
			hMana.bIn = true
			hMana:Show()
			this = hMana:GetParent()
		end
	end
	if this.dwID and not this.alone then
		if this.bList then
			local hTotal = _HM_TargetList.frame:Lookup("Wnd_List"):Lookup("", "")
			local hOver = hTotal:Lookup("Image_LOver")
			local nY = this:GetIndex() * 20 - _HM_TargetList.frame:Lookup("Wnd_List/Scroll_List"):GetScrollPos() * 10
			hOver:SetRelPos(0, nY)
			hOver:Show()
			hTotal:FormatAllItemPos()
		else
			local hTotal = _HM_TargetList.frame:Lookup("Wnd_Focus"):Lookup("", "")
			local hOver = hTotal:Lookup("Image_FOver")
			hOver:SetRelPos(0, this:GetIndex() * 63 - 3)
			hOver:Show()
			hTotal:FormatAllItemPos()
		end
	elseif szName == "Text_LCount" then
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		local szTip = GetFormatText("<" .. _L["List: live/total num"] .. ">\n", 101) .. GetFormatText(_L["Click to show nearby player statistics"], 106)
		OutputTip(szTip, 400, {nX, nY, nW, nH})
	end
end

HM_TargetList.OnItemMouseLeave = function()
	local szName = this:GetName()
	if szName == "Image_PlayerBg" or szName == "Text_Mana" then
		local hMana = this:GetParent():Lookup("Text_Mana")
		if hMana then
			hMana.bIn = false
			hMana:Hide()
			this = hMana:GetParent()
		end
	end
	if this.dwID and not this.alone then
		if this.bList then
			this:GetParent():GetParent():Lookup("Image_LOver"):Hide()
		else
			this:GetParent():GetParent():Lookup("Image_FOver"):Hide()
		end
	elseif szName == "Text_LCount" then
		HideTip()
	end
end

HM_TargetList.OnItemLButtonDown = function()
	if this:GetName() == "Handle_ATotal" then
		_HM_TargetList.ShowAcctInfo()
	elseif this:GetName() == "Text_LCount" then
		if HM_RedName and HM_TargetList.nListMode >= 4 then
			HM_RedName.ShowAroundInfo()
		end
	elseif this:GetName() == "Text_LTitle" then
		_HM_TargetList.bCustom = not _HM_TargetList.bCustom
		_HM_TargetList.UpdateListTitle()
	else
		if not HM_TargetList.bFocusTarget2 and this:GetName() == "Text_Target" then
			this = this:GetParent()
		end
		if this.dwID then
			if IsShiftKeyDown() and HM_TargetList.bAltFocus then
				_HM_TargetList.SwitchFocus(this.dwID)
			else
				HM.SetTarget(this.dwID)
			end
		end
	end
end

HM_TargetList.OnItemRButtonDown = function()
	if this.dwID and this.szName then
		if _HM_TargetList.bInArena and _HM_TargetList.nBeginArena then
			return HM.SetTarget(this.dwID)
		end
		local m0, dwID = {}, this.dwID
		table.insert(m0, _HM_TargetList.GetFocusItemMenu(dwID))
		table.insert(m0, { szOption = _L["Set as persist focus"], fnAction = function() _HM_TargetList.SetPersistFocus(dwID) end })
		if IsPlayer(this.dwID) then
			local me, dwID, szName = GetClientPlayer(), this.dwID, this.szName
			if me.IsInParty() and  InsertMarkMenu
				and me.dwID == GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
			then
				InsertMarkMenu(m0, dwID)
			end
			if me.IsInParty() and me.IsPlayerInMyParty(dwID) then
				InsertTeammateLeaderMenu(m0, dwID)
			end
			table.insert(m0, {bDevide = true})
			InsertPlayerCommonMenu(m0, dwID, szName)
			-- 查看装备，查看经脉，镇派，名剑队
			table.insert(m0, { szOption = g_tStrings.STR_LOOKUP,
				fnDisable = function() return not GetPlayer(dwID) end,
				fnAction = function() ViewInviteToPlayer(dwID) end
			})
			--[[
			table.insert(m0, { szOption = g_tStrings.LOOKUP_CHANNEL,
				fnDisable = function() return not GetPlayer(dwID) end,
				fnAction = function() ViewOtherPlayerChannels(dwID) end
			})
			table.insert(m0, { szOption = g_tStrings.LOOKUP_TANLENT,
				fnDisable = function()
					local tar = GetPlayer(dwID)
					-- FIXEME：IDENTITY.JIANG_HU = 0
					return not tar or tar.dwForceID == 0
				end,
				fnAction = function() ViewOtherZhenPaiSkill(dwID) end
			})
			--]]
			table.insert(m0, { szOption = g_tStrings.LOOKUP_CORPS,
				fnDisable = function() return not GetPlayer(dwID) end,
				fnAction = function()
					Wnd.CloseWindow("ArenaCorpsPanel")
					OpenArenaCorpsPanel(true, dwID)
				end
			})
			-- view qixue
			local t = {}
			InsertTargetMenu(t, dwID)
			for _, v in ipairs(t) do
				if v.szOption == g_tStrings.LOOKUP_INFO then
					for _, vv in ipairs(v) do
						if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then
							table.insert(m0, vv)
							break
						end
					end
					break
				end
			end
		else
			if this.bList then
				local szName = this.szName
				table.insert(m0, { szOption = _L["Filter named this NPC"],
					fnAction = function() _HM_TargetList.tFilterNpc[szName] = true end
				})
			end
		end
		-- single focus
		local dwID = this.dwID
		table.insert(m0, { szOption = _L["Lock as single focus"], fnAction = function() HM_SingleFocus.Lock(dwID) end })
		PopupMenu(m0)
	end
end

HM_TargetList.OnItemLButtonDBClick = function()
	if HM_TargetList.bJihuo and HM_Marker and this.dwID and this:GetName() ~= "Text_Target" then
		local tar = HM.GetTarget(this.dwID)
		if tar and HM_Marker.CanJihuo() then
			HM.SetTarget(this.dwID)
			HM_Marker.Jihuo(tar)
		end
	end
end

HM_TargetList.OnItemMouseWheel = function()
	if this:GetName() == "Handle_List" then
		local scroll = this:GetParent():GetParent():Lookup("Scroll_List")
		if scroll:IsVisible() then
			local nStep = Station.GetMessageWheelDelta()
			scroll:ScrollNext(nStep)
			return true
		end
	end
end

---------------------------------------------------------------------
-- 独立焦点窗口 （asked by 海尕尕）
---------------------------------------------------------------------
HM_SingleFocus = {
	bEnable2 = false,	-- 是否开启
	tAnchor = {},		-- 窗体位置
}
RegisterCustomData("HM_SingleFocus.bEnable2")
RegisterCustomData("HM_SingleFocus.tAnchor")

-- update size/pos
HM_SingleFocus.UpdateAnchor = function(frame)
	local a = HM_SingleFocus.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", -200, -70)
	end
	frame:CorrectPos()
end

-- attach callback
for _, v in ipairs({"MouseEnter", "MouseLeave", "LButtonDown", "RButtonDown", "LButtonDBClick" }) do
	local k = "OnItem" .. v
	HM_SingleFocus[k] = HM_TargetList[k]
end

-- init frame
HM_SingleFocus.OnFrameCreate = function()
	-- clear old
	local handle = this:Lookup("", "")
	handle:Clear()
	-- create element
	this.focus = _HM_TargetList.NewFocusItem(handle, 0)
	this.focus.alone = true
	this.focus:SetRelPos(0, 0)
	handle:SetSize(this.focus:GetSize())
	this:SetSize(this.focus:GetSize())
	handle:FormatAllItemPos()
	-- fetch first focus
	for _, v in ipairs(_HM_TargetList.tFocus) do
		if HM.GetTarget(v) then
			this.focus.dwID = v
			break
		end
	end
	-- adjust custom
	UpdateCustomModeWindow(this, _L["HM, focus alone"])
	HM_SingleFocus.UpdateAnchor(this)
	-- events
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("HM_ADD_FOCUS_TARGET")
	this:RegisterEvent("HM_DEL_FOCUS_TARGET")
	this:RegisterEvent("LOADING_END")
end

-- breathe frame
HM_SingleFocus.OnFrameBreathe = function()
	if not GetClientPlayer() or not this.focus then
		return
	end
	if not this.focus.dwID then
		return this.focus:Hide()
	end
	local nFrame = GetLogicFrameCount()
	if not this.nFrame or (nFrame - this.nFrame) > 1 then
		local tar = HM.GetTarget(this.focus.dwID)
		if not tar then
			this.nFrame = nFrame + 8
			this.focus:Hide()
		else
			this.nFrame = nFrame
			_HM_TargetList.UpdateFocusItem(this.focus, tar)
			this.focus.szName = tar.szName
			this.focus:Show()
		end
	end
end

-- drag end
HM_SingleFocus.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_SingleFocus.tAnchor = GetFrameAnchor(this)
end

-- events
HM_SingleFocus.OnEvent = function(event)
	if event == "ON_ENTER_CUSTOM_UI_MODE" or event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this)
	elseif event == "UI_SCALED" then
		HM_SingleFocus.UpdateAnchor(this)
	elseif event == "HM_ADD_FOCUS_TARGET" and this.focus and not this.focus.locked then
		this.focus.dwID = arg0
	elseif event == "HM_DEL_FOCUS_TARGET" and this.focus and arg0 == this.focus.dwID then
		this.focus.dwID = nil
		this.focus.locked = nil
	elseif event == "LOADING_END" then
		this.nFrame = nil
	end
end

-- switch
HM_SingleFocus.Switch = function(bEnable)
	if bEnable ~= nil then
		HM_SingleFocus.bEnable2 = bEnable
	else
		HM_SingleFocus.bEnable2 = not HM_SingleFocus.bEnable2
	end
	local frame = Station.Lookup("Normal/HM_SingleFocus")
	if not HM_SingleFocus.bEnable2 then
		if frame then
			Wnd.CloseWindow(frame)
		end
	elseif not frame then
		Wnd.OpenWindow("interface\\HM\\HM_TargetList\\HM_SingleFocus.ini", "HM_SingleFocus")
	end
end

-- lock as single focus
HM_SingleFocus.Lock = function(dwID)
	HM_SingleFocus.Switch(true)
	local frame = Station.Lookup("Normal/HM_SingleFocus")
	if frame and frame.focus then
		frame.focus.dwID = dwID
		frame.focus.locked = true
		_HM_TargetList.AddFocus(dwID)
		FireUIEvent("HM_ADD_FOCUS_TARGET", dwID, true)
	end
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
_HM_TargetList.PS = {}

-- deinit panel
_HM_TargetList.PS.OnPanelDeactive = function(frame)
	_HM_TargetList.ui = nil
end

-- init panel
_HM_TargetList.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { x = 0, y = 0, txt = _L["Feature setting"], font = 27 })
	nX = ui:Append("WndCheckBox", "Check_Show", { x = 10, y = 28, checked = HM_TargetList.bShow })
	:Text(_L["Enable focus/target list ("]):Click(function(bChecked)
		HM_TargetList.bShow = bChecked
		ui:Fetch("Check_Focus"):Enable(bChecked)
		ui:Fetch("Check_List"):Enable(bChecked)
		_HM_TargetList.Switch(bChecked)
	end):Pos_()
	nX = ui:Append("Text", { txt = _L["Hotkey"], x = nX, y = 27 }):Click(HM.SetHotKey):Pos_()
	ui:Append("Text", { txt = HM.GetHotKey("ShowTL", false) .. _L[") "], x = nX, y = 27 })
	ui:Append("WndCheckBox", "Check_Focus", { x = 10, y = 56, checked = HM_TargetList.bShowFocus })
	:Enable(HM_TargetList.bShow):Text(_L("Show focus target (up to %d)", HM_TargetList.nMaxFocus)):Click(function(bChecked)
		HM_TargetList.bShowFocus = bChecked
		_HM_TargetList.UpdateSize(true)
	end)
	ui:Append("WndCheckBox", "Check_List", { x = 10, y = 84, checked = HM_TargetList.bShowList })
	:Enable(HM_TargetList.bShow):Text(_L["Show target list"]):Click(function(bChecked)
		HM_TargetList.bShowList = bChecked
		_HM_TargetList.UpdateSize()
	end)
	nX = ui:Append("WndComboBox", { x = 10, y = 114, txt = _L["Foucs setting"] }):Menu(_HM_TargetList.GetFocusMenu):Pos_()
	ui:Append("WndComboBox", { x = nX + 20, y = 114, txt = _L["List setting"] }):Menu(_HM_TargetList.GetListMenu)
	_HM_TargetList.ui = ui
	ui:Append("Text", { x = 0, y = 150, txt = _L["Tips"], font = 27 })
	nX = ui:Append("Text", { x = 10, y = 178, txt = _L["1. Support to set/select focus by hotkey, "] }):Pos_()
	ui:Append("WndButton", { txt = _L["Enter setting"], x = nX + 5, y = 180 }):AutoSize(8):Click(HM.SetHotKey)
	ui:Append("Text", { x = 10, y = 206, txt = _L["2. Hotkey supported when mouse move over the npc/player of scene, "] })
	ui:Append("Text", { x = 10, y = 234, txt = _L["3. Press SHIFT and click target/targettarget/target list can add/remove focus"] })
	ui:Append("Text", { x = 10, y = 262, txt = _L["4. Send 33 to around player can add as focus"] })
end

-- player menu
_HM_TargetList.PS.OnPlayerMenu = function()
	return {
		szOption = _L["Enable focus targetlist"] .. HM.GetHotKey("ShowTL", true),
		bCheck = true, bChecked = HM_TargetList.bShow, fnAction = _HM_TargetList.Switch
	}
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_ENTER_GAME", function()
	_HM_TargetList.Switch(HM_TargetList.bShow)
	_HM_TargetList.HookTargetMenu()
	HM_SingleFocus.Switch(HM_SingleFocus.bEnable2)
end)
HM.RegisterEvent("LOADING_END", function()
	_HM_TargetList.bInArena = IsInArena()
	_HM_TargetList.nBeginArena = nil
	_HM_TargetList.nFrameAcct = 0
	if _HM_TargetList.bInArena or IsInSameQWG() then
		if _HM_TargetList.bInArena then
			_HM_TargetList.bShowList = HM_TargetList.bShowList
			HM_TargetList.bShowList = false
			_HM_TargetList.UpdateSize()
		end
		RegisterMsgMonitor(_HM_TargetList.MonitorArena, {"MSG_SYS"})
	else
		if _HM_TargetList.bShowList then
			HM_TargetList.bShowList = _HM_TargetList.bShowList
			_HM_TargetList.bShowList = nil
			_HM_TargetList.UpdateSize()
		end
		UnRegisterMsgMonitor(_HM_TargetList.MonitorArena, {"MSG_SYS"})
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["Focus/TargetList"], 299, _L["Target"], _HM_TargetList.PS)

-- hotkey
HM.AddHotKey("SetFocus", _L["Set target as focus"],  _HM_TargetList.SetFocus)
HM.AddHotKey("SelFocus", _L["Loop to select focus"],  _HM_TargetList.SelFocus)
HM.AddHotKey("ShowTL", _L["Enable focus targetlist"],  _HM_TargetList.Switch)

-- tracebutton menu
TraceButton_AppendAddonMenu({ function()
	return {{
		szOption = _L["HM, focus targetlist"], bCheck = true,
		bChecked = HM_TargetList.bShow,
		fnAction = _HM_TargetList.Switch
	}}
end })

-- shared with HM_Marker
HM_TargetList.AddFocus = _HM_TargetList.AddFocus
HM_TargetList.DelFocus = _HM_TargetList.DelFocus
