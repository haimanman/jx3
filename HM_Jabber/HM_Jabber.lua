--
-- 海鳗插件：斩杀喊话、技能喊话、人头统计
--

HM_Jabber = {
	nChannelKill1 = PLAYER_TALK_CHANNEL.TONG,
	nChannelKilled1 = PLAYER_TALK_CHANNEL.TONG_ALLIANCE,
	nChannelSkill1 = 0,
	tMessage = {
		kill = {
			["default"] = {		-- $zj：自己，$killer：杀手, $dead：死者，$map：地图
				[_L["Kill"]] = _L["$killer successfully kill $dead"],					-- 默认击杀
				[_L["Killed"]] = _L["I was cruel killed by $killer at $map"],	-- 默认被杀
				[_L["Assist kill"]] = _L["$zj assist $killer to kill $dead"],			-- 默认协助击杀
			},
		},
		skill = {},					-- $zj：自己，$mb：目标/技能释放或接收者：命中，闪躲，被命中，被闪躲，读条，中断读条
		auto =  _L["Hello, world!"],
	},
}
HM.RegisterCustomData("HM_Jabber")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Jabber = {
	nBeginTime = GetTime(),		-- 上线时间
	bAuto = false,			-- 是否开启自动喊话
	nKill = 0,					-- 杀人次数
	nKilled = 0,				-- 被杀次数
	nKilled2 = 0,			-- 摔死次数
	nAssist = 0,				-- 协助击杀次数
	tCampKill = {},			-- 阵营击杀次数
	tTongKill = {},			-- 帮会击杀次数
	nAutoTime = 30,		-- 隔几秒自动喊一次，默认 30 秒
	tAutoChannel = {
		[PLAYER_TALK_CHANNEL.TONG] = true,
	},	-- 自动喊话的频道选择（多选）
	bStopFull = false,		-- 组满不喊
}

-- talk channels
_HM_Jabber.tChannel = {
	{ PLAYER_TALK_CHANNEL.NEARBY, "MSG_NORMAL" },
	{ PLAYER_TALK_CHANNEL.FRIENDS, "MSG_FRIEND" },
	{ PLAYER_TALK_CHANNEL.TONG_ALLIANCE, "MSG_GUILD_ALLIANCE" },
	{ PLAYER_TALK_CHANNEL.RAID, "MSG_TEAM" },
	{ PLAYER_TALK_CHANNEL.TONG, "MSG_GUILD" },
	{ PLAYER_TALK_CHANNEL.SENCE, "MSG_MAP" },
	{ PLAYER_TALK_CHANNEL.FORCE, "MSG_SCHOOL" },
	{ PLAYER_TALK_CHANNEL.CAMP, "MSG_CAMP" },
	{ PLAYER_TALK_CHANNEL.WORLD, "MSG_WORLD" },
	{ PLAYER_TALK_CHANNEL.WHISPER, "MSG_WHISPER" }
}

-- get channel name
_HM_Jabber.GetChannelName = function(nChannel)
	if nChannel == PLAYER_TALK_CHANNEL.RAID then
		return _L["Team/Battle"]
	end
	for _, v in ipairs(_HM_Jabber.tChannel) do
		if v[1] == nChannel then
			local szType = v[2]
			return g_tStrings.tChannelName[szType]
		end
	end
	return _L["Not publish"]
end

-- get channel color
_HM_Jabber.GetChannelColor = function(nChannel)
	for _, v in ipairs(_HM_Jabber.tChannel) do
		if v[1] == nChannel then
			return GetMsgFontColor(v[2], true)
		end
	end
	return { 200, 200, 200 }
end

-- get channel menu  fnAction(newChannel)
_HM_Jabber.GetChannelMenu = function(nChannel, fnAction, bWhisper)
	local m0 = {}
	local bCheck = nChannel ~= nil
	local bMCheck = type(nChannel) == "number"
	if bMCheck then
		table.insert(m0, {
			szOption = _HM_Jabber.GetChannelName(0), rgb = { 200, 200, 200 },
			bCheck = bCheck, bMCheck = true, bChecked = nChannel == 0,
			fnAction = function() fnAction(0) end
		})
	end
	for k, v in ipairs(_HM_Jabber.tChannel) do
		k, v = v[1], v[2]
		if (k ~= PLAYER_TALK_CHANNEL.WHISPER or bWhisper)
			and (not bWhisper or HM.CanTalk(k))
		then
			local m1 = {
				szOption = _HM_Jabber.GetChannelName(k), rgb = GetMsgFontColor(v, true),
				bCheck = bCheck, bMCheck = bMCheck
			}
			if type(nChannel) == "table" then
				m1.bChecked = nChannel[k] == true
				m1.fnAction = function(d, b) nChannel[k] = b end
			else
				m1.bChecked = nChannel == k
				m1.fnAction = function() fnAction(k) end
			end
			table.insert(m0, m1)
		end
	end
	return m0
end

-- post count
_HM_Jabber.PostAccount = function(nChannel)
	local szText, szPart = _L["From online"], ""
	local nMin = math.ceil((GetTime() - _HM_Jabber.nBeginTime) / 60000)
	for k, v in pairs(_HM_Jabber.tCampKill) do
		szPart = szPart .. _L(", %s: %d players", g_tStrings.STR_CAMP_TITLE[k], v)
	end
	local tTong = {}
	for k, v in pairs(_HM_Jabber.tTongKill) do
		local szTong = GetTongClient().ApplyGetTongName(k)
		if szTong and szTong ~= "" then
			table.insert(tTong, { szTong, v })
		end
	end
	if #tTong > 1 then
		table.sort(tTong, function(a, b) return a[2] > b[2] end)
	end
	for i = 1, 2 do
		if tTong[i] then
			szPart = szPart .. _L(", %s: %d players", tTong[i][1], tTong[i][2])
		end
	end
	if nMin >= 60 then
		szText = szText .. _L("%d hours", nMin / 60)
		nMin = nMin % 60
	end
	if nMin > 0 then
		szText = szText .. _L("%dm", nMin)
	end
	szText = szText .. _L(", be killed %d times", _HM_Jabber.nKilled)
	if _HM_Jabber.nKilled2 > 0 then
		szText = szText .. _L("(unexpectedly dead %d times)", _HM_Jabber.nKilled2)
	end
	szText = szText .. _L(", kill %d players", _HM_Jabber.nKill)
	if szPart ~= "" then
		szText = szText .. _L("(%s)", string.sub(szPart, 3))
	end
	if not HM.IsDps() then
		szText = szText .. _L(", assist killing %d times", _HM_Jabber.nAssist)
	end
	HM.Talk2(nChannel, szText)
end

-- time delay name
_HM_Jabber.GetTimeShow = function(nSec)
	local szShow = ""
	if nSec > 60 then
		szShow = _L("%dm", nSec / 60)
		nSec = nSec % 60
	end
	if nSec > 0 then
		szShow = szShow .. _L("%ds", nSec)
	end
	return szShow
end

-- new/edit kill say
_HM_Jabber.EditMsgKill = function(szTong, szType)
	local frm, tMessage = _HM_Jabber.kFrame, HM_Jabber.tMessage.kill
	if not frm then
		local box, nX
		-- type
		frm = HM.UI.CreateFrame("HM_JABBER_KILL", { close = false, w = 381, h = 420 })
		frm:Append("Text", { txt = _L["Type"], x = 0, y = 0, font = 27 })
		box = frm:Append("WndRadioBox", "Radio_1", { txt = _L["Kill"], x = 0, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Kill"] end end)
		nX, _ = box:Pos_()
		box = frm:Append("WndRadioBox", "Radio_2", { txt = _L["Be killed"], x = nX + 10, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Killed"] end end)
		nX, _ = box:Pos_()
		box = frm:Append("WndRadioBox", "Radio_3", { txt = _L["Assist killing"], x = nX + 10, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Assist kill"] end end)
		-- tong
		frm:Append("Text", { txt = _L["Guild/Player name"], x = 0, y = 60, font = 27 }):Pos_()
		frm:Append("WndEdit", "Edit_Name", { x = 0, y = 88, limit = 100, w = 290, h = 25 } )
		-- message
		local nLimit = 128
		if HM_About.CheckNameEx(GetClientPlayer().szName) then
			nLimit = 1024
		end
		frm:Append("Text", { txt = _L["Talk message"], x = 0, y = 120, font = 27 })
		frm:Append("WndEdit", "Edit_Msg", { x = 0, y = 148, w = 290, h = 50, multi = true, limit = 160 })
		-- buttons
		frm:Append("WndButton", "Btn_Save", { txt = _L["Save"], x = 45, y = 210 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			local szType, szMsg = frm.szType, frm:Fetch("Edit_Msg"):Text()
			if szName == "" or szMsg == "" then
				HM.Alert(_L["Guild name and msg can not be empty"])
			else
				if not tMessage[szName] then tMessage[szName] = {} end
				tMessage[szName][szType] = szMsg
				frm:Toggle(false)
			end
		end)
		frm:Append("WndButton", "Btn_Delete", { txt = _L["Remove"], x = 145, y = 210 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			if szName ~= "default" then
				local szType = frm.szType
				tMessage[szName][szType] = nil
			end
			frm:Toggle(false)
		end)
		-- tips variable
		frm:Append("Text", { txt = _L["Message variables"], x = 0, y = 250, font = 27 })
		frm:Append("Text", { txt = _L["$zj: myself, $map: map, $gh guild"], x = 5, y = 278 })
		frm:Append("Text", { txt = _L["$killer: killer, $dead: dead"], x = 5, y = 303 })
		_HM_Jabber.kFrame = frm
	end
	-- title
	if not szTong then
		frm:Title(_L["Add kill saying"])
		frm:Fetch("Edit_Name"):Text(""):Enable(true)
		frm:Fetch("Edit_Msg"):Text(_L["I successfully kill $gh member of $dead in $map"]):Enable(true)
		frm:Fetch("Radio_1"):Enable(true):Check(true)
		frm:Fetch("Radio_2"):Enable(true)
		frm:Fetch("Radio_3"):Enable(not HM.IsDps())
	else
		frm:Title(_L["Edit kill saying"])
		frm:Fetch("Edit_Name"):Text(szTong):Enable(szTong ~= "default")
		frm:Fetch("Edit_Msg"):Text(tMessage[szTong][szType]):Enable(true)
		if szType == _L["Assist kill"] then
			frm:Fetch("Radio_3"):Check(true)
		elseif szType == _L["Killed"] then
			frm:Fetch("Radio_2"):Check(true)
		else
			frm:Fetch("Radio_1"):Check(true)
		end
		frm:Fetch("Radio_1"):Enable(false)
		frm:Fetch("Radio_2"):Enable(false)
		frm:Fetch("Radio_3"):Enable(false)
	end
	frm:Fetch("Btn_Delete"):Enable(szTong ~= nil and szTong ~= "default")
	frm:Toggle(true)
end

-- get kill say menu
_HM_Jabber.GetMsgKillMenu = function()
	local m0 = {
		{ szOption = _L["* New *"], fnAction = _HM_Jabber.EditMsgKill },
		{ bDevide = true, }
	}
	for k, v in pairs(HM_Jabber.tMessage.kill) do
		local szOptionEx = " [" .. k .. "]"
		if k == "default" then
			szOptionEx = _L[" (default)"]
		end
		for kk, vv in pairs(v) do
			table.insert(m0, { szOption = kk .. szOptionEx, fnAction = function() _HM_Jabber.EditMsgKill(k, kk) end })
		end
		if IsEmpty(v) then
			HM_Jabber.tMessage.kill[k] = nil
		end
	end
	return m0
end

-- simple check skill name
_HM_Jabber.IsValidSkill = function(szName)
	local nCount = g_tTable.Skill:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.Skill:GetRow(i)
		if tLine.szName == szName then
			return true
		end
	end
	return false
end

-- new/edit skill say
_HM_Jabber.EditMsgSkill = function(szName, szType)
	local frm, tMessage = _HM_Jabber.sFrame, HM_Jabber.tMessage.skill
	if not frm then
		local box, nX
		-- type 命中，偏离，被命中，闪躲
		frm = HM.UI.CreateFrame("HM_JABBER_SKILL", { close = false, w = 381, h = 420 })
		frm:Append("Text", { txt = _L["Type"], x = 0, y = 0, font = 27 })
		box = frm:Append("WndRadioBox", "Radio_1", { txt = _L["Hit"], x = 0, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Hit"] end end)
		nX, _ = box:Pos_()
		box = frm:Append("WndRadioBox", "Radio_2", { txt = _L["Miss"], x = nX + 5, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Miss"] end end)
		nX, _ = box:Pos_()
		box = frm:Append("WndRadioBox", "Radio_5", { txt = _L["Prepare"], x = nX + 5, y = 0, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Prepare"] end end)
		box = frm:Append("WndRadioBox", "Radio_3", { txt = _L["Be hit"], x = nX + 5, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Be hit"] end end)
		nX, _ = box:Pos_()
		box = frm:Append("WndRadioBox", "Radio_6", { txt = _L["Prepare broken"], x = nX + 5, y = 0, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Prepare broken"] end end)
		box = frm:Append("WndRadioBox", "Radio_4", { txt = _L["Be missed"], x = nX + 5, y = 28, group = "Radio" })
		box:Click(function(bChecked) if bChecked then frm.szType = _L["Be missed"] end end)
		-- tong
		frm:Append("Text", { txt = _L["Skill name"], x = 0, y = 60, font = 27 })
		frm:Append("WndEdit", "Edit_Name", { x = 0, y = 88, limit = 100, w = 290, h = 25 } )
		-- message
		frm:Append("Text", { txt = _L["Talk message"], x = 0, y = 120, font = 27 })
		frm:Append("WndEdit", "Edit_Msg", { x = 0, y = 148, w = 290, h = 50, multi = true, limit = 128 })
		-- buttons
		frm:Append("WndButton", "Btn_Save", { txt = _L["Save"], x = 45, y = 210 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			local szType, szMsg = frm.szType, frm:Fetch("Edit_Msg"):Text()
			if szName == "" or szMsg == "" then
				HM.Alert(_L["Skill name and talk msg can not be empty"])
			elseif not _HM_Jabber.IsValidSkill(szName) then
				HM.Alert(_L("Invalid skill name [%s]", szName))
			else
				if not tMessage[szName] then tMessage[szName] = {} end
				tMessage[szName][szType] = szMsg
				frm:Toggle(false)
			end
		end)
		frm:Append("WndButton", "Btn_Delete", { txt = _L["Remove"], x = 145, y = 210 }):Click(function()
			local szType, szName = frm.szType, frm:Fetch("Edit_Name"):Text()
			tMessage[szName][szType] = nil
			frm:Toggle(false)
		end)
		-- tips variable
		frm:Append("Text", { txt = _L["Message variables"], x = 0, y = 250, font = 27 })
		frm:Append("Text", { txt = _L["$zj: my name, $jn: skill name"], x = 5, y = 278 })
		frm:Append("Text", { txt = _L["$mb: target/caster name"], x = 5, y = 303 })
		_HM_Jabber.sFrame = frm
	end
	-- title
	if not szName then
		frm:Title(_L["Add skill saying"])
		frm:Fetch("Edit_Name"):Text(""):Enable(true)
		frm:Fetch("Edit_Msg"):Text(_L["Hey, $mb, $jn fun or not?"]):Enable(true)
		frm:Fetch("Radio_1"):Enable(true):Check(true)
		frm:Fetch("Radio_2"):Enable(true)
		frm:Fetch("Radio_3"):Enable(true)
		frm:Fetch("Radio_4"):Enable(true)
		frm:Fetch("Radio_5"):Enable(true)
		frm:Fetch("Radio_6"):Enable(true)
	else
		frm:Title(_L["Edit skill saying"])
		frm:Fetch("Edit_Name"):Text(szName):Enable(false)
		frm:Fetch("Edit_Msg"):Text(tMessage[szName][szType]):Enable(true)
		if szType == _L["Prepare broken"] then
			frm:Fetch("Radio_6"):Check(true)
		elseif szType == _L["Prepare"] then
			frm:Fetch("Radio_5"):Check(true)
		elseif szType == _L["Be missed"] then
			frm:Fetch("Radio_4"):Check(true)
		elseif szType == _L["Be hit"] then
			frm:Fetch("Radio_3"):Check(true)
		elseif szType == _L["Miss"] then
			frm:Fetch("Radio_2"):Check(true)
		else
			frm:Fetch("Radio_1"):Check(true)
		end
		frm.szType = szType
		frm:Fetch("Radio_1"):Enable(false)
		frm:Fetch("Radio_2"):Enable(false)
		frm:Fetch("Radio_3"):Enable(false)
		frm:Fetch("Radio_4"):Enable(false)
		frm:Fetch("Radio_5"):Enable(false)
		frm:Fetch("Radio_6"):Enable(false)
	end
	frm:Fetch("Btn_Delete"):Enable(szName ~= nil)
	frm:Toggle(true)
end

-- get skill say menu
_HM_Jabber.GetMsgSkillMenu = function()
	local m0 = {
		{ szOption = _L["* New *"], fnAction = _HM_Jabber.EditMsgSkill },
		{ bDevide = true, }
	}

	for k, v in pairs(HM_Jabber.tMessage.skill) do
		local szOptionEx = k
		if k == "default" then
			szOptionEx = _L[" (default)"]
		end
		table.insert(m0, { szOption = szOptionEx })
		for kk, vv in pairs(v) do
			table.insert(m0[#m0], { szOption = kk, fnAction = function() _HM_Jabber.EditMsgSkill(k, kk) end })
		end
		if IsEmpty(v) then
			HM_Jabber.tMessage.skill[k] = nil
		end
	end
	return m0
end

-- get auto say text
_HM_Jabber.GetAutoText = function()
	if type(HM_Jabber.tMessage.auto) == "table" then
		local szText = ""
		for _, v in ipairs(HM_Jabber.tMessage.auto) do
			if v.text then
				szText = szText .. v.text
			end
		end
		return szText
	end
	return HM_Jabber.tMessage.auto
end

-- event talk
_HM_Jabber.tEventTalk = { _L["On entering game"], _L["On changing map"], _L["On joining guild"], _L["On joining team"] }

-- default talk
_HM_Jabber.tEventDefault = {
	{
		_L["The tall handsome $zj came the game!"],
		_L["The gentle beautiful $zj came the game!"],
	}, {
		_L["The handsome $zj came the map $map, quick to welcome me."],
		_L["The beautiful $zj came the map $map, quick to welcome me."],
	},
	_L["Welcome to $mb joined $gh!"],
	_L["Welcome to $mb joined the team lead by $dz!"],
}

-- set talk message
_HM_Jabber.SetEventMessage = function(data)
	GetUserInput(_L["$map=map, $zj=own"], function(szText)
		data.szMsg = szText
	end, nil, nil, nil, data.szMsg, 128)
end

-- do event talk
_HM_Jabber.DoEventTalk = function(nEvent)
	if not HM_Jabber.tMessage.event then
		return
	end
	local m, me = HM_Jabber.tMessage.event[nEvent], GetClientPlayer()
	if not m or not me or m.nChannel == 0 or m.szMsg == "" then
		return
	end
	local szMsg = string.gsub(m.szMsg, "%$zj", me.szName)
	if nEvent == 3 then
		-- $mb, $gh
		szMsg = string.gsub(szMsg, "%$mb", arg0)
		szMsg = string.gsub(szMsg, "%$gh", GetTongClient().ApplyGetTongName(me.dwTongID))
	elseif nEvent == 4 then
		-- $mb, $dz
		local team = GetClientTeam()
		local dwLeader = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		szMsg = string.gsub(szMsg, "%$mb", team.GetClientTeamMemberName(arg1))
		szMsg = string.gsub(szMsg, "%$dz", team.GetClientTeamMemberName(dwLeader))
	end
	szMsg = string.gsub(szMsg, "%$map", Table_GetMapName(me.GetScene().dwMapID))
	HM.Talk(m.nChannel, szMsg)
end

-- get event menu
_HM_Jabber.GetEventMenu = function()
	if not HM_Jabber.tMessage.event then
		HM_Jabber.tMessage.event = {}
	end
	local tMessage, m0 = HM_Jabber.tMessage.event, {}
	for k, v in ipairs(_HM_Jabber.tEventTalk) do
		if not tMessage[k] or tMessage[k].szMsg == "" then
			tMessage[k] = { nChannel = 0 }
			if k == 3 then
				tMessage[k].nChannel = PLAYER_TALK_CHANNEL.TONG
				tMessage[k].szMsg = _HM_Jabber.tEventDefault[k]
			elseif k == 4 then
				--tMessage[k].nChannel = PLAYER_TALK_CHANNEL.RAID
				tMessage[k].szMsg = _HM_Jabber.tEventDefault[k]
			else
				tMessage[k].szMsg = _HM_Jabber.tEventDefault[k][GetClientPlayer().nGender] or ""
			end
		end
		local ms, m1 = tMessage[k], { szOption = v }
		local m2 =  _HM_Jabber.GetChannelMenu(ms.nChannel, function(nChannel) ms.nChannel = nChannel end)
		m2.szOption = _L["Sel channel"]
		table.insert(m1, m2)
		table.insert(m1, { szOption = _L["Set content"], UserData = ms, fnAction = _HM_Jabber.SetEventMessage })
		table.insert (m0, m1)
	end
	return m0
end

-- check current is in duel
HM_Jabber.IsInDuel = function()
	if _HM_Jabber.dwDuelID then
		local _, dwID = GetClientPlayer().GetTarget()
		return dwID == _HM_Jabber.dwDuelID
	end
	return false
end

-- register revive message
_HM_Jabber.RegisterReviveTalk = function(dwSkillID)
	local t = HM_Jabber.tMessage.skill
	local szName = HM.GetSkillName(dwSkillID)
	if not t[szName] then
		t[szName] = {
			[_L["Hit"]] = _L["$mb, hurry up and thank me."],				-- 成功救治
			[_L["Prepare"]] = _L["$mb, $jn, picking up your dead body yet."],		-- 开始救治
			[_L["Prepare broken"]] = _L["$mb, fraud dead, what a pity."]		-- 中止救治
		}
		-- 如果没开启喊话则强行开启
		if HM_Jabber.nChannelSkill1 == 0 then
			HM_Jabber.nChannelSkill1 = PLAYER_TALK_CHANNEL.RAID
		end
	end
end

-- init revive message (after loading)
_HM_Jabber.InitReviveTalk = function()
	local me = GetClientPlayer()
	if not me or HM_Jabber.tMessage.bRevived2 then
		return
	end
	HM_Jabber.tMessage.bRevived2 = true
	local mnt = me.GetKungfuMount()
	if mnt.dwMountType == 2 then      -- 万花
		_HM_Jabber.RegisterReviveTalk(139)   -- 锋针
	elseif mnt.dwMountType == 4 then  -- 七秀
		_HM_Jabber.RegisterReviveTalk(551)   -- 心鼓弦
		_HM_Jabber.RegisterReviveTalk(3003)  -- 妙舞神扬
	elseif mnt.dwMountType == 9 then  -- 五毒
		_HM_Jabber.RegisterReviveTalk(2229)  -- 涅槃重生
	elseif mnt.dwMountType == 19 then -- 长歌
		_HM_Jabber.RegisterReviveTalk(14084) -- 杯水留影
	end
end

---------------------------------------------------------------------
-- 事件处理函数
---------------------------------------------------------------------
-- 图标为 13 的特殊喊话技能
_HM_Jabber.tSpecialSkill = {
	[9007] = true,	[53] = true,	[54] = true,
	[4097] = true,	[3691] = true,	[4972] = true,
	[4973] = true,	[5129] = true,	[5130] = true,
	[5209] = true,	[5210] = true,	[5211] = true,
	[5212] = true,	[5215] = true,	[5218] = true,
	[5244] = true,	[4099] = true,	[4113] = true,
	[4114] = true,	[4117] = true,	[4131] = true,
	[4132] = true,	[4133] = true,	[4134] = true,
}

_HM_Jabber.OnSkillHit = function(dwCaster, dwTarget, dwID, dwLevel, nType)
	local me = GetClientPlayer()
	if dwID == _HM_Jabber.dwPrepareID then
		_HM_Jabber.dwPrepareID, _HM_Jabber.dwPrepareLevel = nil, nil		-- clear prepare data
	end
	if HM_Jabber.nChannelSkill1 == 0 or not me then
		return
	end
	if dwCaster ~= me.dwID and dwTarget ~= me.dwID then
		return
	end
	local tMessage = HM_Jabber.tMessage.skill
	local szName, dwIcon = HM.GetSkillName(dwID, dwLevel)
	HM.Debug3("#" .. dwCaster .. "#" .. arg0 .. " (" .. szName .. ", Lv" .. dwLevel .. ")")
	if szName ~= "" and (dwIcon ~= 13 or _HM_Jabber.tSpecialSkill[dwID]) and tMessage[szName] then
		local tar, szMsg = nil, nil
		if dwCaster == me.dwID then
			tar = HM.GetTarget(dwTarget)
			if nType == 3 then
				szMsg = tMessage[szName][_L["Prepare broken"]]
			elseif nType == 2 then
				szMsg = tMessage[szName][_L["Prepare"]]
			elseif nType == 1 then
				szMsg = tMessage[szName][_L["Be missed"]]
			else
				szMsg = tMessage[szName][_L["Hit"]]
			end
		elseif dwTarget == me.dwID then
			tar = HM.GetTarget(dwCaster)
			if nType == 1 then
				szMsg = tMessage[szName][_L["Miss"]]
			else
				szMsg = tMessage[szName][_L["Be hit"]]
			end
		end
		if szMsg and tar then
			szMsg = string.gsub(szMsg, "%$mb", tar.szName)
			szMsg = string.gsub(szMsg, "%$zj", me.szName)
			szMsg = string.gsub(szMsg, "%$jn", szName)
			if HM_Jabber.nChannelSkill1 == PLAYER_TALK_CHANNEL.WHISPER then
				HM.Talk(tar.szName, szMsg)
			else
				HM.Talk(HM_Jabber.nChannelSkill1, szMsg)
			end
		end
	end
end

_HM_Jabber.OnSkillMiss = function(dwCaster, dwTarget, dwID, dwLevel)
	_HM_Jabber.OnSkillHit(dwCaster, dwTarget, dwID, dwLevel, 1)
end

_HM_Jabber.OnSkillPrepare = function(dwID, dwLevel, nType)
	local me = GetClientPlayer()
	local _, dwTarget = me.GetTarget()
	if dwTarget == 0 then
		dwTarget = me.dwID
	end
	_HM_Jabber.OnSkillHit(me.dwID, dwTarget, dwID, dwLevel, nType or 2)
end

_HM_Jabber.OnSkillPrepareBroken = function(dwID, dwLevel)
	_HM_Jabber.OnSkillPrepare(dwID, dwLevel, 3)
end

_HM_Jabber.OnPlayerDeath = function(dwID, szKiller, nFrame)
	if not IsPlayer(dwID) then return end
	local me, szTong, nChannel, szMsg = GetClientPlayer(), "", 0, nil
	local tar, tMessage = GetTargetHandle(me.GetTarget()), HM_Jabber.tMessage.kill
	if me.dwID == dwID then
		-- be killed
		tar = me
		if szKiller ~= "" then
			_HM_Jabber.nKilled = _HM_Jabber.nKilled + 1
		else
			_HM_Jabber.nKilled2 = _HM_Jabber.nKilled2 + 1
		end
		if HM_Jabber.nChannelKilled1 ~= 0 then
			nChannel = HM_Jabber.nChannelKilled1
			if tMessage[szKiller] and tMessage[szKiller][_L["Killed"]] then
				szMsg = tMessage[szKiller][_L["Killed"]]
			else
				szMsg = tMessage["default"][_L["Killed"]]
			end
			-- whisper
			if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
				nChannel = szKiller
			end
		end
	elseif szKiller == me.szName
		or (not HM.IsDps(me) and me.bFightState
			and tar and IsAlly(me.dwID, tar.dwID) and tar.szName == szKiller)
	then
		-- kill/assist
		tar = GetPlayer(dwID)
		local szKey = _L["Kill"]
		if szKiller == me.szName then
			nChannel = HM_Jabber.nChannelKill1
			_HM_Jabber.nKill = _HM_Jabber.nKill + 1
			if tar then
				-- camp
				if not _HM_Jabber.tCampKill[tar.nCamp] then
					_HM_Jabber.tCampKill[tar.nCamp] = 1
				else
					_HM_Jabber.tCampKill[tar.nCamp] = _HM_Jabber.tCampKill[tar.nCamp] + 1
				end
				-- tong
				if tar.dwTongID and tar.dwTongID ~= 0 then
					if not _HM_Jabber.tTongKill[tar.dwTongID] then
						_HM_Jabber.tTongKill[tar.dwTongID] = 1
					else
						_HM_Jabber.tTongKill[tar.dwTongID] = _HM_Jabber.tTongKill[tar.dwTongID] + 1
					end
				end
			end
		else
			_HM_Jabber.nAssist = _HM_Jabber.nAssist + 1
			nChannel = HM_Jabber.nChannelKill1
			szKey = _L["Assist kill"]
		end
		if nChannel ~= 0 and tar then
			if tMessage[tar.szName] then
				szMsg =  tMessage[tar.szName][szKey]
			end
			if not szMsg and tar.dwTongID and tar.dwTongID ~= 0 then
				szTong = GetTongClient().ApplyGetTongName(tar.dwTongID)
				if szTong and tMessage[szTong] then
					szMsg = tMessage[szTong][szKey]
				end
			end
			if not szMsg then
				szMsg = tMessage["default"][szKey]
			end
			if HM_About.CheckNameEx(tar.szName) then
				szMsg = _L["$dead, sorry, I am wrong, I am really wrong"]
			end
			-- whisper
			if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
				nChannel = tar.szName
			end
		end
	end
	if szMsg and tar then
		if szKiller == "" then
			szKiller = _L["<OUTER GUEST>"]
		end
		szMsg = string.gsub(szMsg, "%$killer", szKiller)
		szMsg = string.gsub(szMsg, "%$zj", me.szName)
		if type(szTong) == "string" then
			szMsg = string.gsub(szMsg, "%$gh", szTong)
		end
		szMsg = string.gsub(szMsg, "%$dead", tar.szName)
		szMsg = string.gsub(szMsg, "%$map", Table_GetMapName(me.GetScene().dwMapID))
		HM.DelayCall(125, function() HM.Talk(nChannel, szMsg) end)
	end
end

_HM_Jabber.OnCheckJabber = function()
	if arg0 == "UI_OME_FINISH_DUEL" then
		_HM_Jabber.dwDuelID = nil
	elseif arg0 == "UI_OME_START_DUEL" then
		_HM_Jabber.dwDuelID = arg1
	elseif arg0 == "UI_OME_SKILL_CAST_LOG" and arg1 == GetClientPlayer().dwID then
		_HM_Jabber.OnSkillPrepare(arg2, arg3)
		_HM_Jabber.dwPrepareID, _HM_Jabber.dwPrepareLevel = arg2, arg3
	elseif arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
		_HM_Jabber.OnSkillHit(arg1, arg2, arg4, arg5)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
		_HM_Jabber.OnSkillHit(arg1, arg2, arg5, arg6)
	elseif (arg0 == "UI_OME_SKILL_BLOCK_LOG" or arg0 == "UI_OME_SKILL_SHIELD_LOG"
			or arg0 == "UI_OME_SKILL_MISS_LOG" or arg0 == "UI_OME_SKILL_DODGE_LOG")
		and arg3 == SKILL_EFFECT_TYPE.SKILL
	then
		_HM_Jabber.OnSkillMiss(arg1, arg2, arg4, arg5)
	elseif arg0 == "UI_OME_DEATH_NOTIFY" then
		_HM_Jabber.OnPlayerDeath(arg1, arg3, arg2)
	end
end

_HM_Jabber.OnActionBreak = function()
	if _HM_Jabber.dwPrepareID and arg0 == GetClientPlayer().dwID then
		_HM_Jabber.OnSkillPrepareBroken(_HM_Jabber.dwPrepareID, _HM_Jabber.dwPrepareLevel)
	end
end

_HM_Jabber.OnLoadingEnd = function()
	if not _HM_Jabber.bLogined then
		local nMax = #_HM_Jabber.tEventTalk
		if not HM_Jabber.tMessage.event or not HM_Jabber.tMessage.event[nMax] then
			_HM_Jabber.GetEventMenu()
		end
		_HM_Jabber.bLogined = true
		_HM_Jabber.DoEventTalk(1)
	else
		_HM_Jabber.DoEventTalk(2)
	end
	_HM_Jabber.InitReviveTalk()
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
_HM_Jabber.PS = {}

-- init panel
_HM_Jabber.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	local _GetColor, _GetName, _GetMenu = _HM_Jabber.GetChannelColor, _HM_Jabber.GetChannelName, _HM_Jabber.GetChannelMenu
	ui:Append("Text", { txt = _L["Kill saying"], font = 27 })
	-- kill player
	nX = ui:Append("Text", { txt = _L["Select kill channel"], x = 10, y = 28 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Kill", { x = nX + 5, y = 30, w = 120, h = 25 })
	:Text(_GetName(HM_Jabber.nChannelKill1)):Color(unpack(_GetColor(HM_Jabber.nChannelKill1)))
	:Menu(function()
		return _GetMenu(HM_Jabber.nChannelKill1, function(nChannel)
			HM_Jabber.nChannelKill1 = nChannel
			ui:Fetch("Combo_Kill"):Text(_GetName(nChannel)):Color(unpack(_GetColor(nChannel)))
		end, true)
	end):Pos_()
	-- be killed
	local nX1 = nX
	nX = ui:Append("Text", { txt = _L["Killed"], x = nX + 20, y = 28 }):Pos_()
	ui:Append("WndComboBox", "Combo_Killed", { x = nX + 5, y = 30, w = 120, h = 25 })
	:Text(_GetName(HM_Jabber.nChannelKilled1)):Color(unpack(_GetColor(HM_Jabber.nChannelKilled1)))
	:Menu(function()
		return _GetMenu(HM_Jabber.nChannelKilled1, function(nChannel)
			HM_Jabber.nChannelKilled1 = nChannel
			ui:Fetch("Combo_Killed"):Text(_GetName(nChannel)):Color(unpack(_GetColor(nChannel)))
		end, true)
	end)
	-- count
	nX = ui:Append("Text", { txt = _L["Post kill statistics"], x = 10, y = 58 }):Pos_()
	ui:Append("WndComboBox", "Combo_Account", { x = nX + 5, y = 58, w = 120, h = 25 }):Color(255, 0, 0)
	:Text(_L["Sel channel"]):Menu(function()
		return _GetMenu(nil, _HM_Jabber.PostAccount)
	end)
	-- content set
	ui:Append("WndComboBox", { x = 10, y = 90 }):Text(_L["Set kill saying"]):Menu(_HM_Jabber.GetMsgKillMenu)
	-- event talk
	ui:Append("WndComboBox", { x = nX1 + 20, y = 90 }):Text(_L["Saying on other event"]):Menu(_HM_Jabber.GetEventMenu)
	-- skill
	ui:Append("Text", { txt = _L["Skill saying"], font = 27, x = 0, y = 126 })
	nX = ui:Append("Text", { txt = _L["Select skill saying channel"], x = 10, y = 154 }):Pos_()
	ui:Append("WndComboBox", "Combo_Skill", { x = nX + 5, y = 154, w = 120, h = 25 })
	:Text(_GetName(HM_Jabber.nChannelSkill1)):Color(unpack(_GetColor(HM_Jabber.nChannelSkill1)))
	:Menu(function()
		return _GetMenu(HM_Jabber.nChannelSkill1, function(nChannel)
			HM_Jabber.nChannelSkill1 = nChannel
			ui:Fetch("Combo_Skill"):Text(_GetName(nChannel)):Color(unpack(_GetColor(nChannel)))
		end, true)
	end)
	ui:Append("WndComboBox", { x = 10, y = 186 }):Text(_L["Set skill saying channel"]):Menu(_HM_Jabber.GetMsgSkillMenu)
	-- auto
	ui:Append("Text", { txt = _L["Auto saying"], font = 27, x = 0, y = 222 })
	nX = ui:Append("Text", { txt = _L["Interval"], x = 10, y = 250 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Speed", { x = nX + 5, y = 252, w = 90, h = 25 })
	:Text(_HM_Jabber.GetTimeShow(_HM_Jabber.nAutoTime)):Menu(function()
		local m0, tSec = {}, { 10, 20, 30, 60, 120, 180, 300, 600 }
		if HM_About.CheckNameEx(GetClientPlayer().szName) then
			table.insert(tSec, 1, 5)
			table.insert(tSec, 1, 3)
			table.insert(tSec, 1, 2)
			table.insert(tSec, 1, 1)
		end
		for _, v in ipairs(tSec) do
			table.insert(m0, {
				szOption = _HM_Jabber.GetTimeShow(v),
				fnAction = function()
					_HM_Jabber.nAutoTime = v
					ui:Fetch("Combo_Speed"):Text(_HM_Jabber.GetTimeShow(v))
					ui:Fetch("Check_Auto"):Check(false)
				end
			})
		end
		return m0
	end):Pos_()
	nX = ui:Append("WndComboBox", { txt = _L["Saying channel"], x = nX + 20, y = 252, w = 140, h = 25 })
	:Menu(function()
		return _GetMenu(_HM_Jabber.tAutoChannel)
	end):Pos_()
	ui:Append("Text", { txt = _L["(multiple)"], x = nX + 5, y = 248 })
	nX = ui:Append("Text", { txt = _L["Saying content (expressable)"], x = 10, y = 280 }):Pos_()
	nX = ui:Append("WndButton", { x = nX + 10, y = 282 })
	:Text(_L["Import"]):Click(function()
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		HM_Jabber.tMessage.auto = edit:GetTextStruct()
		ui:Fetch("Edit_Auto"):Text(_HM_Jabber.GetAutoText(), true)
		HM.Sysmsg(_L["Import successfully, but modify content will lead to link broken"])
	end):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Auto", { txt = _L["Start yelling"], x = nX + 10, y = 282, checked = _HM_Jabber.bAuto })
	:Click(function(bChecked)
		_HM_Jabber.bAuto = bChecked
		ui:Fetch("Check_Stop"):Enable(bChecked)
		if bChecked then
			HM.BreatheCall("HM_Jabber_Auto", function()
				local szText = HM_Jabber.tMessage.auto
				local team = GetClientTeam()
				if _HM_Jabber.bStopFull and team.GetTeamSize() == team.nGroupNum * 5 then
					return
				end
				if szText and szText ~= "" then
					for k, v in pairs(_HM_Jabber.tAutoChannel) do
						if v == true then
							HM.Talk(k, szText)
						end
					end
				end
			end, _HM_Jabber.nAutoTime * 1000)
		else
			HM.BreatheCall("HM_Jabber_Auto", nil)
		end
	end):Pos_()
	ui:Append("WndCheckBox", "Check_Stop", { txt = _L["Stop when team full"], x = nX + 10, y = 282, checked = _HM_Jabber.bStopFull })
	:Enable(_HM_Jabber.bAuto):Click(function(bChecked)
		_HM_Jabber.bStopFull = bChecked
	end)
	local nLimit = 128
	if HM_About.CheckNameEx(GetClientPlayer().szName) then
		nLimit = 1024
	end
	ui:Append("WndEdit", "Edit_Auto", { x = 10, y = 310, w = 460, h = 60, limit = nLimit, multi = true })
	:Text(_HM_Jabber.GetAutoText()):Change(function(szText)
		HM_Jabber.tMessage.auto = szText
	end)
end

-- check conflict
_HM_Jabber.PS.OnConflictCheck = function()
	if Ly_Battle then
		Ly_Battle.a1 = false
		Ly_Battle.a2 = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("SYS_MSG", _HM_Jabber.OnCheckJabber)
HM.RegisterEvent("OT_ACTION_PROGRESS_BREAK", _HM_Jabber.OnActionBreak)
HM.RegisterEvent("LOADING_END", _HM_Jabber.OnLoadingEnd)
HM.RegisterEvent("TONG_MEMBER_JOIN", function() _HM_Jabber.DoEventTalk(3) end)
HM.RegisterEvent("PARTY_ADD_MEMBER", function() _HM_Jabber.DoEventTalk(4) end)

-- add to HM panel
HM.RegisterPanel(_L["Skill/Kill jabber"], 2150, nil, _HM_Jabber.PS)

-- init global caller
HM_Jabber.IsInDuel = _HM_Jabber.IsInDuel
