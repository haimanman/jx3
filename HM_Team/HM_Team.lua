--
-- 海鳗插件：保存、还原团队列表，快速标记
--

HM_Team = {
	bKeepMark = true,	-- 保留成员标记
	bKeepForm = true,	-- 保留小队阵眼
	bKeepAlly = true,		-- 清空标记时保留友方标记
}
HM.RegisterCustomData("HM_Team")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Team = {
	bDebug = false,
	tMarkName = { _L["Cloud"], _L["Sword"], _L["Ax"], _L["Hook"], _L["Drum"], _L["Shear"], _L["Stick"], _L["Jade"], _L["Dart"], _L["Fan"] },
	-- 0: 江湖，1：少林，2：万花，3：天策，4：纯阳，5：七秀，6：五毒，7：唐门，8：藏剑，9:丐帮，10：明教 --
	tForceOrder = { 0, 5, 2, 6, 4, 7, 8, 1, 3, 9, 10 },
	tRelation = { _L["Enemy"], _L["Ally"], _L["Neutral"] },
	tMarkForce = { { ["z"] = true, [0] = true, [2] = true, [4] = true, [5] = true, [6] = true }, {}, {} },
	tMarkAlly = {},
	nLastFrame = 0,
}

-- add new force
for k, v in pairs(g_tStrings.tForceTitle) do
	if k > 10 then
		table.insert(_HM_Team.tForceOrder, k)
	end
end

-- sysmsg
_HM_Team.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Team"])
end

-- debug
_HM_Team.Debug = function(szMsg)
	HM.Debug(szMsg, _L["HM_Team"])
end

-- bg hear to submit leader
_HM_Team.OnAskLeader = function(nChannel, dwID, szName, data, bSelf)
	if not bSelf then
		local me, team = GetClientPlayer(), GetClientTeam()
		if me and me.IsInParty() and me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) then
			local dwID = tonumber(data[1])
			local szName = team.GetClientTeamMemberName(dwID)
			if HM_About.CheckNameEx(szName) or szName == _L["HMM5"] then
				team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwID)
				_HM_Team.Sysmsg(_L("Automatically shift leader to trusted player [%s]", szName))
			end
		end
	end
end

-------------------------------------
-- 保存、还原团队列表
-------------------------------------
-- save
_HM_Team.Save = function()
	local tList, me, team = {}, GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return _HM_Team.Sysmsg(_L["You are not in a team"])
	end
	-- auth info
	_HM_Team.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	_HM_Team.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	_HM_Team.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	_HM_Team.nLootMode = team.nLootMode
	-- members
	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
			end
		end
	end
	-- saved ok
	_HM_Team.tSaved = tList
	_HM_Team.Sysmsg(_L["Team list data saved"])
end

-- sync member info
_HM_Team.SyncMember = function(team, dwID, szName, state)
	if  HM_Team.bKeepForm and state.bForm then
		team.SetTeamFormationLeader(dwID, state.nGroup)
		_HM_Team.Debug("restore formation of " .. string.format("%d", state.nGroup + 1) .. " group: " .. szName)
	end
	if HM_Team.bKeepMark and state.nMark then
		team.SetTeamMark(state.nMark, dwID)
		_HM_Team.Debug("restore player marked as [" .. _HM_Team.tMarkName[state.nMark] .. "]: " .. szName)
	end
end

-- get wrong index
_HM_Team.GetWrongIndex = function(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end

-- restore
_HM_Team.Restore = function()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return _HM_Team.Sysmsg(_L["You are not in a team"])
	elseif not _HM_Team.tSaved then
		return _HM_Team.Sysmsg(_L["You have  not saved team list data"])
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		local szText = _L("[%s] quick to set %d group of member [%s] as team leader, I am using HM plug-in to restore team", szLeader, nGroup, me.szName)
		HM.Talk(PLAYER_TALK_CHANNEL.RAID, szText)
		HM.Talk(szLeader, szText)
		if HM_About.CheckNameEx(me.szName) or me.szName == _L["HMM5"] then
			HM.BgTalk(szLeader, "HM_TEAM_LEADER", me.dwID)
		end
		return _HM_Team.Sysmsg(_L["You are not team leader, permission denied"])
	end
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end
	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = _HM_Team.tSaved, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				_HM_Team.Debug("unable get player of " .. string.format("%d", nGroup + 1) .. " group: #" .. dwID)
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, "@.*", "")
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					_HM_Team.Debug("unknown status: " .. szName)
				elseif state.nGroup == nGroup then
					_HM_Team.SyncMember(team, dwID, szName, state)
					_HM_Team.Debug("need not adjust: " .. szName)
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == _HM_Team.szLeader then
					dwLeader = dwID
				end
				if szName == _HM_Team.szMark then
					dwMark = dwID
				end
				if szName == _HM_Team.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					_HM_Team.Debug("restore distributor: " .. szName)
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = _HM_Team.GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = _HM_Team.GetWrongIndex(tWrong[src.state.nGroup], false)
			table.remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0)
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else
					_HM_Team.Debug("change group of [" .. dst.szName .. "] to " .. string.format("%d", nGroup + 1))
					_HM_Team.SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			_HM_Team.Debug("change group of [" .. src.szName .. "] to " .. string.format("%d", src.state.nGroup + 1))
			_HM_Team.SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = _HM_Team.GetWrongIndex(tWrong[nGroup], true)
		end
	end
	-- restore others
	if team.nLootMode ~= _HM_Team.nLootMode then
		team.SetTeamLootMode(_HM_Team.nLootMode)
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		_HM_Team.Debug("restore team leader: " .. _HM_Team.szLeader)
	end
	if dwMark  ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		_HM_Team.Debug("restore team marker: " .. _HM_Team.szMark)
	end
	_HM_Team.Sysmsg(_L["Team list restored"])
end

-- apply
_HM_Team.Apply = function()
	local scene = GetClientPlayer().GetScene()
	if scene and scene.nType == MAP_TYPE.BATTLE_FIELD then
		_HM_Team.Restore()
	else
		_HM_Team.Save()
	end
end

-------------------------------------
-- 快速标记玩家
-------------------------------------
-- get player to be marked
_HM_Team.GetAllPlayer = function(nLimit)
	local me, tAll = GetClientPlayer(), HM.GetAllPlayer()
	local tList, nCount = {}, 0
	local bArena = IsInArena()
	local tMarkForce = _HM_Team.tMarkForce
	nLimit = nLimit or 50
	for _, v in ipairs(tAll) do
		local nRel = 3
		if IsEnemy(me.dwID, v.dwID) then
			nRel = 1
		elseif IsAlly(me.dwID, v.dwID) or me.dwID == v.dwID then
			nRel = 2
		end
		local tForce = _HM_Team.tMarkForce[nRel]
		if (bArena and nRel == 1) or (tForce["z"] and tForce[v.dwForceID]) then
			if not tList[v.dwForceID] then
				tList[v.dwForceID] = {}
			end
			table.insert(tList[v.dwForceID], v)
			nCount = nCount + 1
			if nCount >= nLimit then
				break
			end
		end
	end
	_HM_Team.Sysmsg(_L["Load players to mark: "] .. nCount)
	return tList
end

-- mark one payer
_HM_Team.MarkPlayer = function(nKey, v)
	local mnt, szInfo = v.GetKungfuMount(), ""
	if v.nMaxLife > 255 then
		szInfo = _L("HP %.1fw ", v.nMaxLife / 10000)
	end
	szInfo = szInfo .. GetForceTitle(v.dwForceID)
	if mnt then
		szInfo = szInfo .. "(" .. HM.GetSkillName(mnt.dwSkillID, mnt.dwLevel) .. ")"
	else
		HM.RegisterTempTarget(v.dwID)
	end
	GetClientTeam().SetTeamMark(nKey, v.dwID)
	HM.Talk(PLAYER_TALK_CHANNEL.RAID, "[" .. v.szName .. "] " .. szInfo .. _L[", marked as ["] ..  _HM_Team.tMarkName[nKey] .. "]")
end

-- mark
_HM_Team.Mark = function(bClear, bClearOnly)
	local team, me = GetClientTeam(), GetClientPlayer()
	if not me.IsInParty() then
		return _HM_Team.Sysmsg(_L["You are not in a team"])
	end
	-- check perm
	if  me.dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) then
		if me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) then
			team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
		else
			local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
			local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
			local szText = "[" .. team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)) .. "] "
			if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) then
				szText = szText .. "[" .. szLeader .. "] "
			end
			szText = szText .. _L("Please shift mark perm to No.%d group member [%s], I am using HM plug-in to mark", nGroup, me.szName)
			HM.Talk(PLAYER_TALK_CHANNEL.RAID, szText)
			HM.Talk(szLeader, szText)
			if HM_About.CheckNameEx(me.szName) or me.szName == _L["HMM5"] then
				HM.BgTalk(PLAYER_TALK_CHANNEL.RAID, "HM_TEAM_LEADER", me.dwID)
			end
			return _HM_Team.Sysmsg(_L["You have not mark permission"])
		end
	end
	-- load exists mark
	local nCount, tIndex, tMark = 0, {}, team.GetTeamMark()
	for dwID, nKey in pairs(tMark) do
		local bKeep = not bClear
		if not bKeep and HM_Team.bKeepAlly then
			local tar = HM.GetTarget(dwID)
			if tar then
				_HM_Team.tMarkAlly[nKey] = IsAlly(me.dwID, dwID)
			end
			bKeep = _HM_Team.tMarkAlly[nKey] == true
		end
		if not bKeep then
			_HM_Team.tMarkAlly[nKey] = nil
			tMark[dwID] = nil
			team.SetTeamMark(0, dwID)
		else
			nCount = nCount + 1
			tIndex[nKey] = dwID
		end
	end
	-- clear
	if bClear == true then
		_HM_Team.Sysmsg(_L("Clear exists mark, %d left", nCount))
		if bClearOnly then
			return
		end
	end
	if nCount >= #_HM_Team.tMarkName then
		return _HM_Team.Sysmsg(_L("Exists mark %d, can not be marked", nCount))
	end
	_HM_Team.Sysmsg(_L("Exists mark %d", nCount))
	-- do mark
	local tPlayer = _HM_Team.GetAllPlayer()
	for _, k in ipairs(_HM_Team.tForceOrder) do
		local tAll = tPlayer[k] or {}
		for _, v in ipairs(tAll) do
			if not tMark[v.dwID] then
				for nKey = 1, #_HM_Team.tMarkName do
					if not tIndex[nKey] then
						_HM_Team.MarkPlayer(nKey, v)
						_HM_Team.tMarkAlly[nKey] = IsAlly(me.dwID, v.dwID)
						tIndex[nKey] = v.dwID
						nCount = nCount + 1
						break
					end
				end
				if nCount >= #_HM_Team.tMarkName then
					break
				end
			end
		end
		if nCount >= #_HM_Team.tMarkName then
			break
		end
	end
	-- finish
	if nCount > 0 then
		_HM_Team.Sysmsg(_L("Total marked %d, If you do not see HP, please re-mark after a while", nCount))
	end
end

-- clear mark
_HM_Team.ClearMark = function()
	_HM_Team.Mark(true, true)
end

-- remark
_HM_Team.ReMark = function()
	_HM_Team.Mark(true)
end

-- hotkey mark
_HM_Team.KeyMark = function()
	local nFrame = GetLogicFrameCount()
	if (nFrame - _HM_Team.nLastFrame) > 8 then
		_HM_Team.nLastFrame = nFrame
		_HM_Team.Mark()
	else
		_HM_Team.ReMark()
	end
end

-- get force menu
_HM_Team.GetForceMenu = function()
	local m0 = {}
	for nRel, szRel in ipairs(_HM_Team.tRelation) do
		local m1 = { szOption = szRel .. _L[" relation"], bCheck = true, }
		m1.bChecked = _HM_Team.tMarkForce[nRel]["z"] == true
		m1.fnAction = function(data, bCheck) _HM_Team.tMarkForce[nRel]["z"] = bCheck  end
		for _, v in ipairs(_HM_Team.tForceOrder) do
			local m2 = { szOption = g_tStrings.tForceTitle[v], bCheck = true, }
			m2.bChecked = _HM_Team.tMarkForce[nRel][v] == true
			m2.fnDisable = function() return not _HM_Team.tMarkForce[nRel]["z"] end
			m2.fnAction = function(data, bCheck) _HM_Team.tMarkForce[nRel][v] = bCheck  end
			table.insert(m1, m2)
		end
		table.insert(m0, m1)
	end
	table.insert(m0, {
		szOption = _L["Keep ally marked"],
		bCheck = true, bChecked = HM_Team.bKeepAlly,
		fnAction = function() HM_Team.bKeepAlly = not HM_Team.bKeepAlly end
	})
	return m0
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Team.PS = {}

-- marker active
_HM_Team.PS.OnMarkerActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { txt = _L["Quickly mark players"], x = 0, y = 0, font = 27 })
	nX = ui:Append("WndButton", { x = 10, y = 30 })
	:Text(_L["Markit"] .. HM.GetHotKey("TeamMark", true, true)):Click(_HM_Team.Mark):Pos_()
	nX = ui:Append("WndButton", { x = nX, y = 30 })
	:Text(_L["Remark"]):Click(_HM_Team.ReMark):Pos_()
	nX = ui:Append("WndButton", { x = nX + 10, y = 30 })
	:Text(_L["Clear mark"]):Click(_HM_Team.ClearMark):AutoSize(8):Pos_()
	ui:Append("WndCheckBox", { txt = _L["Keep ally marked"], checked = HM_Team.bKeepAlly })
	:Pos(nX + 10, 30):Click(function(bChecked)
		HM_Team.bKeepAlly = bChecked
	end)
	nX = ui:Append("WndComboBox", { txt = _L["Set mark school force"], x = 10, y = 62 }):Menu(_HM_Team.GetForceMenu):Pos_()
	nX = ui:Append("Text", { txt = _L[" (fast to double press "], x = nX + 5, y = 60 }):Pos_()
	nX = ui:Append("Text", { txt = _L["Hotkey"], x = nX, y = 60 }):Click(HM.SetHotKey):Pos_()
	ui:Append("Text", { txt = _L[" to remark"], x = nX, y = 60 })
end

-- init panel
_HM_Team.PS.OnPanelActive = function(frame)
	local ui, nX, nY = HM.UI(frame), 0, 0
	_HM_Team.PS.OnMarkerActive(frame)
	_, nY = ui:CPos_()
	nY = nY + 24
	-- marker/select
	nX = ui:Append("WndCheckBox", { txt = _L["Show marked select panel"], checked = HM_Marker.bShow, x = 10, y = nY }):Click(HM_Marker.SwitchPanel):Pos_()
	nX = ui:Append("WndButton", { txt = _L["Check plug"], x = nX + 10, y = nY }):Click(HM_Marker.Check):Pos_()
	ui:Append("Text", { txt = _L[" (Check teammates whether to install the plug-in)"], x = nX, y = nY, font = 161 })
	nY = nY + 36
	-- team save/restore
	ui:Append("Text", { txt = _L["Save/Restore team"], x = 0, y = nY, font = 27 })
	nX = ui:Append("WndButton", { x = 10, y = nY + 30 })
	:Text(_L["Save"] .. HM.GetHotKey("TeamSave", true, true)):AutoSize(8):Click(_HM_Team.Apply):Pos_()
	nX = ui:Append("WndButton", { x = nX, y = nY + 30 }):Text(_L["Restore list"]):Click(_HM_Team.Restore):Pos_()
	nX = ui:Append("Text", { txt = _L["Recommended to use"], x = nX + 5, y = nY + 28 }):Pos_()
	ui:Append("Text", { x = nX, y = nY + 28, txt = _L["Hotkey"] }):Click(HM.SetHotKey)
	-- options
	ui:Append("WndCheckBox", { txt = _L["Keep marked party"], checked = HM_Team.bKeepMark })
	:Pos(10, nY + 58):Click(function(bChecked)
		HM_Team.bKeepMark = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Keep group formation leader"], checked = HM_Team.bKeepForm })
	:Pos(10, nY + 86):Click(function(bChecked)
		HM_Team.bKeepForm = bChecked
	end)
	-- tips
	ui:Append("Text", { txt = _L["Tips"], x = 0, y = nY + 122, font = 27 })
	ui:Append("Text", { txt = _L["1. Much suitable for the battlefield of 25 people"], x = 10, y = nY + 150 })
	ui:Append("Text", { txt = _L["2. Restore team list in battle map, save team list in other map"], x = 10, y = nY + 175 })
end

-- player menu
_HM_Team.PS.OnPlayerMenu = function()
	return {
		{ szOption = _L["Show marked select panel"], bCheck = true, bChecked = HM_Marker.bShow, fnAction = HM_Marker.SwitchPanel },
		{ szOption = _L["Save/Restore team"] .. HM.GetHotKey("TeamSave", true), fnAction = _HM_Team.Apply },
		{ szOption = _L["Quickly mark players"] .. HM.GetHotKey("TeamMark", true), fnAction = _HM_Team.Mark },
	}
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterBgMsg("HM_TEAM_LEADER", _HM_Team.OnAskLeader)
-- add to HM collector
HM.RegisterPanel(_L["Team save/marker"], 2147, nil, _HM_Team.PS)

-- hotkey
HM.AddHotKey("TeamSave", _L["Save/Restore team"],  _HM_Team.Apply)
HM.AddHotKey("TeamMark", _L["Quick mark(2*remark)"],  _HM_Team.KeyMark)

-- shared with HM_Marker
HM_Team.OnMarkerActive = _HM_Team.PS.OnMarkerActive
HM_Team.GetForceMenu = _HM_Team.GetForceMenu
HM_Team.Mark = _HM_Team.Mark
HM_Team.ClearMark = _HM_Team.ClearMark
