-- 海鳗插件：ROLL 点娱乐坊
-- 团长为庄家，每局由团长点击按纽开始、结束，中间的 ROLL 大家开始 ROLL 点
-- 比团长大的记 +1，与团长数值相等或更小的记为 -1
-- 输的一方点数为 1 点则记 -2，赢的一方点数为 100 点则记 +2
-- 在团长开始之前的 ROLL 点无效，开始后的首次 ROLL 点有效，结束会同时发布统计数据
--

HM_Roll = {}

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Roll = {
	bBegin = false,	-- 是否已开始
	nIndex = 0,	-- 第几局
	tSum = {},	-- 累计数据（团长累计另算）
}

-- format result
_HM_Roll.FormatLine = function(szName, nResult, nNum)
	local szLine = _L("%s: ", szName)
	if nResult > 0 then
		szLine = szLine .. "+" .. nResult
	elseif nResult < 0 then
		szLine = szLine .. nResult
	else
		szLine = szLine .. "0"
	end
	if nNum then
		szLine = szLine .. _L("(%d times)", nNum)
	end
	return szLine
end

-- update data (edit)
_HM_Roll.UpdateData = function()
	if not _HM_Roll.ui then
		return
	end
	local szText, nSum, nIndex = "", 0, 1
	for k, v in pairs(_HM_Roll.tSum) do
		szText = szText .. nIndex .. ". " .. _HM_Roll.FormatLine(k, v.nResult, v.nNum) .. "\n"
		nSum = nSum - v.nResult
		nIndex = nIndex + 1
	end
	if nIndex > 1 then
		szText = szText .. "--------------------\n" .. _HM_Roll.FormatLine(_L["(Dealer)"] .. GetClientPlayer().szName, nSum)
	end
	_HM_Roll.ui:Fetch("Edit_Result"):Text(szText)
end

-- post result
_HM_Roll.PostResult = function()
	if IsEmpty(_HM_Roll.tSum) then
		return
	end
	local nSum, nIndex = 0, 1
	for k, v in pairs(_HM_Roll.tSum) do
		HM.Talk(PLAYER_TALK_CHANNEL.RAID, nIndex .. ". " .. _HM_Roll.FormatLine(k, v.nResult, v.nNum))
		nSum = nSum - v.nResult
		nIndex = nIndex + 1
	end
	HM.Talk(PLAYER_TALK_CHANNEL.RAID, "--------------------")
	HM.Talk(PLAYER_TALK_CHANNEL.RAID, _HM_Roll.FormatLine(_L["(Dealer)"] .. GetClientPlayer().szName, nSum, _HM_Roll.nIndex))
end

-- clear data
_HM_Roll.ClearData = function()
	if _HM_Roll.ui then
		_HM_Roll.ui:Fetch("Btn_Begin"):Enable(true)
		_HM_Roll.ui:Fetch("Btn_End"):Enable(false)
	end
	_HM_Roll.bBegin = false
	_HM_Roll.tSum = {}
	_HM_Roll.nIndex = 0
	_HM_Roll.UpdateData()
end

-------------------------------------
-- 事件处理、初始化
-------------------------------------
_HM_Roll.OnLeaveParty = function()
	if arg1 == GetClientPlayer().dwID then
		_HM_Roll.ClearData()
	end
end

_HM_Roll.OnChangeLeader = function()
	if arg0 == TEAM_AUTHORITY_TYPE.LEADER then
		_HM_Roll.ClearData()
	end
end

_HM_Roll.MonitorRoll = function(szMsg, nFont, bRich, r, g, b, szType)
	if not _HM_Roll.bBegin then
		return
	elseif szType == "MSG_TEAM" then
		local nScale, szName
		-- get name
		for k in string.gmatch(szMsg, "text=\"%[(.-)%]\"") do
			if k ~= _L["Team"] then
				szName = k
				break
			end
		end
		-- get scale
		if szName and szName ~= GetClientPlayer().szName then
			local t = GetClientPlayer().GetTalkData()
			if t and t[1] and t[1].type == "text" then
				nScale = tonumber(t[1].text)
			end
		end
		-- rec
		if szName and nScale and nScale >= 1 and nScale <= 10 and not _HM_Roll.tCur[szName] then
			_HM_Roll.tScale[szName] = nScale
			HM.Talk(PLAYER_TALK_CHANNEL.RAID, _L("The diameter of [%s] has been changed to %d for this time", szName, nScale))
		end
	elseif StringFindW(szMsg, _L["point. (1-100)"]) then
		local _, _, szName, szPoint = string.find(szMsg, _L["\"(.-) rolled (%d+) point."])
		if szName == GetClientPlayer().szName then
			if not _HM_Roll.nPoint then
				_HM_Roll.nPoint = tonumber(szPoint)
			end
		elseif not _HM_Roll.tCur[szName] then
			_HM_Roll.tCur[szName] = tonumber(szPoint)
		end
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Roll.PS = {}

-- init panel
_HM_Roll.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- begin
	nX = ui:Append("WndButton", "Btn_Begin", { x = nX + 0, y = 0, txt = _L["Begin roll"] })
	:Enable(_HM_Roll.bBegin ~= true):Click(function()
		local me, team = GetClientPlayer(), GetClientTeam()
		if not me.IsInParty() or me.dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) then
			return HM.Alert(_L["You must be a team leader"])
		end
		ui:Fetch("Btn_Begin"):Enable(false)
		ui:Fetch("Btn_End"):Enable(true)
		_HM_Roll.bBegin = true
		_HM_Roll.tCur = {}
		_HM_Roll.tScale = {}
		_HM_Roll.nPoint = nil
		_HM_Roll.nIndex = _HM_Roll.nIndex + 1
		HM.Talk(PLAYER_TALK_CHANNEL.RAID, _L("--- No.%d times, begin ---", _HM_Roll.nIndex))
	end):Pos_()
	-- end
	nX = ui:Append("WndButton", "Btn_End", { x = nX + 10, y = 0, txt = _L["End roll"] })
	:Enable(true):Enable(_HM_Roll.bBegin == true):Click(function()
		if not _HM_Roll.nPoint then
			return HM.Alert(_L["You should roll first"])
		end
		HM.Talk(PLAYER_TALK_CHANNEL.RAID, _L("--- No.%d times end (dealer: %d) ---", _HM_Roll.nIndex, _HM_Roll.nPoint))
		-- count
		for k, v in pairs(_HM_Roll.tCur) do
			if v > _HM_Roll.nPoint then
				if v == 100 or _HM_Roll.nPoint == 1 then
					v = 2	-- +2
				else
					v = 1	-- +1
				end
			else
				if v == 1 or _HM_Roll.nPoint == 100 then
					v = -2	-- -2
				else
					v = -1	-- -1
				end
			end
			if _HM_Roll.tScale[k] then
				v = v * _HM_Roll.tScale[k]
			end
			local t = _HM_Roll.tSum[k]
			if not t then
				_HM_Roll.tSum[k] = { nNum = 0, nResult = 0 }
				t = _HM_Roll.tSum[k]
			end
			t.nNum = t.nNum + 1
			t.nResult = t.nResult + v
		end
		-- result
		ui:Fetch("Btn_Begin"):Enable(true)
		ui:Fetch("Btn_End"):Enable(false)
		_HM_Roll.bBegin = false
		_HM_Roll.UpdateData()	-- update input text
		_HM_Roll.PostResult()	-- post result
	end):Pos_()
	-- post
	nX = ui:Append("WndButton", "Btn_Post", { x = nX + 10, y = 0, txt = _L["Publish roll"] }):Click(_HM_Roll.PostResult):Pos_()
	--clear
	nX = ui:Append("WndButton", "Btn_Clear", { x = nX + 10, y = 0, txt = _L["Clear roll"] }):Click(function()
		HM.Confirm(_L["Are you sure to clear all roll records?"], _HM_Roll.ClearData)
	end):Pos_()
	-- text edit
	ui:Append("WndEdit", "Edit_Result", { x = 0, y = 30, w = 430, h = 240, multi = true, limit = 999999 }):Raw():Enable(0)
	-- text tips
	ui:Append("Text", { x = 0, y = 280, txt = _L["Game rule"], font = 27 })
	ui:Append("Text", { x = 10, y = 305, txt = _L["1. Only valid for the first time to ROLL."] })
	ui:Append("Text", { x = 10, y = 330, txt = _L["2. Roll point bigger than dealer +1, otherwise -1."] })
	ui:Append("Text", { x = 10, y = 355, txt = _L["3. Team leader become dealer automatically."]})
	ui:Append("Text", { x = 10, y = 380, txt = _L["4. Twice score when lost with 1 point or win with 100 point."]})
	_HM_Roll.ui = ui
	_HM_Roll.UpdateData()
end

-- deinit panel
_HM_Roll.PS.OnPanelDeactive = function(frame)
	_HM_Roll.ui = nil
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PARTY_DELETE_MEMBER", _HM_Roll.OnLeaveParty)
HM.RegisterEvent("TEAM_AUTHORITY_CHANGED", _HM_Roll.OnChangeLeader)
RegisterMsgMonitor(_HM_Roll.MonitorRoll, {"MSG_SYS", "MSG_TEAM"})

-- add to HM panel
HM.RegisterPanel(_L["Roll lottery"], 287, _L["Recreation"], _HM_Roll.PS)
