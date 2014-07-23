--
-- 海鳗插件：关于插件、简介、更新检测，上线喊话、内部名单
--

HM_About = {
	bPlayOpen = true,	-- 播放开场音乐
	szCheckDate = "",	-- 更新检测日期
	nSkipAlert = 0,			-- 忽略更新提醒天数（取消后忽略7天）
}
HM.RegisterCustomData("HM_About")

-- 暂不记录的选项
HM_About.bDebug = false	-- 启用 DEBUG

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_About = {}

-- check deny
_HM_About.CheckLocalDeny = function()
	local me = GetClientPlayer()
	if me and me.dwTongID > 0 then
		local szTong = GetTongClient().ApplyGetTongName(me.dwTongID)
		if _HM_About.tBlackTong[szTong] then
			HM = {}
		end
	end
end

-------------------------------------
-- 特殊名字处理
-------------------------------------
-- Base Url
_HM_About.szHost = { 0x2F, 0x6E, 0x63, 0x2E, 0x6E, 0x61, 0x6D, 0x74, 0x68, 0x67, 0x69, 0x68, 0x2E, 0x33, 0x78, 0x6A, 0x2F, 0x2F, 0x3A, 0x70, 0x74, 0x74, 0x68 }

-- 作者帮会
_HM_About.szTongEx = { 0xC9, 0xC4, 0xA3, 0xBA, }

-- 作才名字
_HM_About.tNameEx = { 0xA9, 0xF7, 0xA9, 0xF7, 0xA3, 0xBA, }

-- 帮会黑名单
_HM_About.tBlackTong = {}

-- decode string data
_HM_About.LoadDataEx = function()
	local tName = HM.Split(_HM_About.Confuse(_HM_About.tNameEx), "|")
	_HM_About.tNameEx = {}
	for _, v in ipairs(tName) do
		_HM_About.tNameEx[v] = true
 	end
	_HM_About.szTongEx = _HM_About.Confuse(_HM_About.szTongEx)
	-- black tong
	local tBlack = HM.Split(_HM_About.Confuse(_HM_About.tBlackTong), "|")
	_HM_About.tBlackTong = {}
	for _, v in ipairs(tBlack) do
		_HM_About.tBlackTong[v] = true
 	end
	-- host url
	_HM_About.szHost = _HM_About.Confuse(_HM_About.szHost)
end

-- add special name
_HM_About.AddNameEx = function(szName)
	if type(szName) == "table" then
		szName = _HM_About.Confuse(szName)
	end
	_HM_About.tNameEx[szName] = true
end

-- check special name
_HM_About.CheckNameEx = function(szName)
	szName = string.gsub(szName, "@.*$", "")
	return _HM_About.tNameEx[szName] ~= nil
end

-- check special target
_HM_About.CheckTarEx = function(tar, bTong)
	local me = GetClientPlayer()
	if not IsEnemy(me.dwID, tar.dwID) then
		return false
	end
	local szName = string.gsub(tar.szName, "@.*$", "")
	if _HM_About.tNameEx[szName] and not _HM_About.tNameEx[me.szName] then
		return true
	end
	if bTong and tar.dwTongID and tar.dwTongID ~= 0 and IsEnemy(me.dwID, tar.dwID) then
		if _HM_About.dwTongEx then
			return tar.dwTongID == _HM_About.dwTongEx
		else
			local tong = GetTongClient()
			if tong.ApplyGetTongName(tar.dwTongID) == _HM_About.szTongEx then
				_HM_About.dwTongEx = tar.dwTongID
				return true
			end
		end
	end
	return false
end

-- confuse code
_HM_About.Confuse = function(tCodes) return string.reverse(string.char(unpack(tCodes))) end

-- check update
_HM_About.CheckUpdate = function(btn)
	local szVer, dwVer = HM.GetVersion()
	local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)
	local szDate = t.year .. "-" .. t.month .. "-" .. t.day
	local szUrl = _HM_About.szHost .. "update.php?version=" .. szVer
	if btn then
		szUrl = szUrl .. "&manual=yes"
		btn:Text(_L["Checking..."]):Enable(false)
	else
		if szDate == HM_About.szCheckDate then
			_HM_About.bChecked = true
			return
		end
		local me, szTong = GetClientPlayer(), ""
		if me.dwTongID > 0 then
			szTong = tostring(GetTongClient().ApplyGetTongName(me.dwTongID))
		end
		if GetUserServer then
			local _, szServer = GetUserServer()
			szUrl = szUrl .. "&server=" .. szServer
		end
		szUrl = szUrl .. "&name=" .. me.szName .. "&tong=" .. szTong
		szUrl = szUrl .. "&role=" .. me.nRoleType .. "&camp=" .. me.nCamp .. "&force=" .. me.dwForceID
	end
	HM.RemoteRequest(szUrl, function(szTitle)
		if szTitle == "OK" then
			if btn then
				HM.Alert(_L["Already up to date!"])
			end
		elseif btn or HM_About.nSkipAlert <= 0 then
			--[[
			HM.Confirm(_L("The new HM version: %s, Goto download page?", szTitle), function()
				OpenInternetExplorer(_HM_About.szHost .. "down/", true)
			end, function()
				if not btn then
					HM_About.nSkipAlert = 7
				end
			end)
			--]]
		end
		if btn then
			btn:Text(_L["Check update"]):Enable(true)
		else
			if HM_About.nSkipAlert > 0 then
				HM_About.nSkipAlert = HM_About.nSkipAlert - 1
			end
			HM_About.szCheckDate = szDate
			_HM_About.bChecked = true
		end
	end)
end

-- data sync
_HM_About.SyncData = function(t)
	local me = GetClientPlayer()
	local szUrl = _HM_About.szHost .. "sync.php?id=" .. tostring(me.dwID)
	-- forced parameters
	t.name = me.szName
	t.mount = me.GetKungfuMount().dwSkillID
	t.map = me.GetMapID()
	t.score = me.GetTotalEquipScore()
	t.role = me.nRoleType
	if GetUserServer then
		t.region, t.server = GetUserServer()
	end
	for k, v in pairs(t) do
		szUrl = szUrl .. "&" .. k .. "=" .. HM.UrlEncode(tostring(v))
	end
	HM.RemoteRequest(szUrl)
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_About.PS = {}

-- init
_HM_About.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	-- basic
	ui:Append("Text", { txt = _L["Simple, Utility, Focus on PVP"], font = 27 })
	ui:Append("Text", { x = 0, y = 28, w = 500, h = 40, multi = true })
	:Align(0, 0):Text(_L["This is an auxiliary PVP plug-in of JX3 game written by player named HMM, Follow the white list API, does not destroy the game balance."])
	ui:Append("Text", { x = 0, y = 74, w = 500, h = 40, multi = true })
	:Align(0, 0):Text(_L["The plug-in is developed based on my own needs and interests, no any WARRANTIES, please understand that!"])
	-- update
	ui:Append("Text", { txt = _L["Version (YY-group: 6685583)"], x = 0, y = 122, font = 27 })
	local nX = ui:Append("Text", { txt = HM.GetVersion() .. "  (Build: " .. HM.szBuildDate .. ")", x = 0, y = 150 }):Pos_()
	nX = ui:Append("WndButton", { txt = _L["Set hotkeys"], x = nX + 10, y = 152 }):AutoSize(8):Click(HM.SetHotKey):Pos_()
	--nX = ui:Append("WndButton", { txt = _L["Check update"], x = nX + 10, y = 152 }):AutoSize(8):Click(function()
	--	_HM_About.CheckUpdate(HM.UI.Fetch(this))
	--end):Pos_()
	-- author
	ui:Append("Text", { txt = _L["About HMM"], x = 0, y = 188, font = 27 })
	ui:Append("Text", { x = 0, y = 216, w = 500, h = 40, multi = true }):Align(0, 0):Text(_L["A pure PVP TianCe player of evil camp. Third-class operation, but first-class crazy and lazy!"])
	-- other
	ui:Append("Text", { txt = _L["Others"], x = 0, y = 264, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 0, y = 292, checked = HM_About.bPlayOpen })
	:Text(_L["Play music on hourly first time to open panel"]):Click(function(bChecked) HM_About.bPlayOpen = bChecked end):Pos_()
	ui:Append("WndCheckBox", { x = nX + 10, y = 292, checked = HM_About.bDebug == true })
	:Text("Enable Debug"):Click(function(bChecked) HM_About.bDebug = bChecked end)
end

-- author
_HM_About.PS.GetAuthorInfo = function()
	return _L["HMM@Buliantai"]
end

-- tab box switch
_HM_About.PS.OnTaboxCheck = function(frame, nIndex, szTitle)
	local ui = HM.UI(frame)
	local szName, me = _L["You"], GetClientPlayer()
	if me then szName = me.szName end
	-- info
	local nF = 0
	local t = TimeToDate(GetCurrentTime())
	local nT = t.month * 100 + t.day
	if nT > 720 and nT < 804 then
		nF = 1
	end
	ui:Append("Image", { x = 0, y = 5, w = 532, h = 168 }):File(HM.GetCustomFile("image.UITEX", "interface\\HM\\HM_0Base\\image.UITEX"), nF):Click(function()
		if nF == 1 and HM_Love then
			HM.OpenPanel(HM_Love.szTitle)
		end
	end)
	ui:Append("Text", { txt = _L("%s are welcome to use HM plug-in", szName), x = 10, y = 190, font = 19 })
	ui:Append("Text", { txt = _L["Free & open source, Utility, Focus on PVP!"], x = 10, y = 220, font = 19 })
	ui:Append("Text", { txt = _L["YY-group: 6685583"], x = 10, y = 280, font = 27 })
	-- buttons
	local nX = ui:Append("Text", { txt = _L["<Opening music>"], x = 10, y = 305, font = 27 }):Click(function()
		PlaySound(SOUND.UI_SOUND, HM.GetCustomFile("opening.wav", "interface\\HM\\HM_0Base\\opening.wav"))
	end):Pos_()
	nX = ui:Append("Text", { txt = _L["<About plug-in>"], x = nX + 10, y = 305, font = 27 }):Click(function()
		HM.OpenPanel(_L["About plug-in"])
	end):Pos_()
	--nX = ui:Append("Text", { txt = _L["<Latest version>"], x = nX + 10, y = 305, font = 27 }):Click(function()
	--	OpenInternetExplorer(_HM_About.szHost .. "down/")
	--end):Pos_()
	nX = ui:Append("Text", { txt = _L["<Set hotkeys>"], x = nX + 10, y = 305, font = 27 }):Click(HM.SetHotKey):Pos_()
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("LOADING_END", function()
	if not _HM_About.bChecked then
		_HM_About.CheckLocalDeny()
		_HM_About.CheckUpdate()
	end
end)
HM.RegisterEvent("CALL_LUA_ERROR", function()
	if HM_About.bDebug then
		OutputMessage("MSG_SYS", arg0)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["About plug-in"], 368, _L["Others"], _HM_About.PS)

-- init global caller
_HM_About.LoadDataEx()

-- protect HM_About
local _About = {
	AddNameEx = _HM_About.AddNameEx,
	CheckTarEx = _HM_About.CheckTarEx,
	CheckNameEx = _HM_About.CheckNameEx,
	OnTaboxCheck = _HM_About.PS.OnTaboxCheck,
	OnPanelActive = _HM_About.PS.OnTaboxCheck,
	GetAuthorInfo = _HM_About.PS.GetAuthorInfo,
	SyncData = _HM_About.SyncData,
}
setmetatable(HM_About, { __metatable = true, __index = _About, __newindex = function() end } )
