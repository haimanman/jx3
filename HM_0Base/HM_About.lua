--
-- 海鳗插件：关于插件、简介、更新检测，上线喊话、内部名单
--

HM_About = {
	bPlayOpen = false,	-- 播放开场音乐
	bShowButton = false, -- 始终显示 HM 小按钮
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

-- get sync data
_HM_About.GetSyncData = function()
	local me = GetClientPlayer()
	local data = {
		gid = me.GetGlobalID(),
		name = GetUserRoleName(),
		server = select(6, GetUserServer()),
		school = me.dwForceID,
		camp = me.nCamp,
		body = me.nRoleType,
		-- rank
		avatar = me.dwMiniAvatarID,
		pet = me.GetAcquiredFellowPetScore() + me.GetAcquiredFellowPetMedalScore(),
		score = me.GetTotalEquipScore(),
		point = me.GetAchievementRecord(),
		-- weapon, horse
		__lang = HM.szClientLang,
	}
	-- back cloak
	if me.dwBackCloakItemIndex and me.dwBackCloakItemIndex > 0 then
		local info = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, me.dwBackCloakItemIndex)
		if info then
			data.cloak = info.szName
		end
	end
	-- weapon
	local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	if item then
		data.weapon = item.szName
	end
	if me.dwForceID == 8 then
		local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
		if item then
			if not data.weapon then
				data.weapon = item.szName
			else
				data.weapon = data.weapon .. ";" .. item.szName
			end
		end
	end
	-- horse
	local item = me.GetEquippedHorse()
	if item then
		data.horse = item.szName
	end
	-- sign
	data.__sum = 0
	for _, v in ipairs({"gid", "name", "server", "school", "camp", "body", "avatar", "pet", "score", "point", "cloak", "weapon", "horse" }) do
		if data[v] then
			local n = 0
			local s = v .. "=" .. data[v]
			for i = 1, string.len(s) do
				n = (n + string.byte(s, i)) % 0x7fff
			end
			data.__sum = (data.__sum + n) % 0x7fffff
		end
	end
	return data
end

-------------------------------------
-- 特殊名字处理
-------------------------------------
-- Base Url
_HM_About.szHost = { 0x2F, 0x6E, 0x63, 0x2E, 0x6E, 0x61, 0x6D, 0x74, 0x68, 0x67, 0x69, 0x68, 0x2E, 0x33, 0x78, 0x6A, 0x2F, 0x2F, 0x3A, 0x70, 0x74, 0x74, 0x68 }

-- 作者帮会
_HM_About.szTongEx = { 0xC9, 0xC4, 0xA3, 0xBA, }

-- 作者名字
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
	--[[
	szName = string.gsub(szName, "@.*$", "")
	return _HM_About.tNameEx[szName] ~= nil
	--]]
	return false
end

-- check special target
_HM_About.CheckTarEx = function(tar, bTong)
	--[[
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
	--]]
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
		szUrl = szUrl .. "&name=" .. me.szName .. "&tong=" .. szTong .. "&score=" .. me.GetTotalEquipScore()
		szUrl = szUrl .. "&role=" .. me.nRoleType .. "&camp=" .. me.nCamp .. "&force=" .. me.dwForceID .. "&id=" .. me.dwID
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

-- insert keju tips
_HM_About.AppendExampTip = function(frame)
	local ui = HM.UI(frame)
	ui:Append("Text", "Text_Tip", { txt = _L["Tip: answer by guess? It is better to get help from [HM-WeChat]."], w = 640, h = 27, x = 100, y = 482, font = 7 }):Hover(function()
		local x, y = Cursor.GetPos()
		OutputTip(GetFormatImage("interface\\HM\\HM_0Base\\image.UiTex", 2, 148, 148), 200, {x, y, 0, 0})
	end, function()
		HideTip()
	end)
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
	ui:Append("Text", { txt = _L["Version (QQ-group: 54516791)"], x = 0, y = 122, font = 27 })
	local nX = ui:Append("Text", { txt = HM.GetVersion() .. "  (Build: " .. HM.szBuildDate .. ")", x = 0, y = 150 }):Pos_()
	nX = ui:Append("WndButton", { txt = _L["Set hotkeys"], x = nX + 10, y = 152 }):AutoSize(8):Click(HM.SetHotKey):Pos_()
	--nX = ui:Append("WndButton", { txt = _L["Check update"], x = nX + 10, y = 152 }):AutoSize(8):Click(function()
	--	_HM_About.CheckUpdate(HM.UI.Fetch(this))
	--end):Pos_()
	-- author
	ui:Append("Text", { txt = _L["About HMM"], x = 0, y = 188, font = 27 })
	ui:Append("Text", { x = 0, y = 216, w = 500, h = 20, multi = true }):Align(0, 0):Text(_L["A pure PVP TianCe player of evil camp. Third-class operation, but first-class crazy and lazy!"])
	-- other
	nX = 0
	ui:Append("Text", { txt = _L["Others"], x = 0, y = 244, font = 27 })
	ui:Append("WndCheckBox", { x = 0, y = 272, checked = HM_About.bShowButton })
	:Text(_L["Always display HM button near the player avatar"]):Click(function(bChecked)
		HM_About.bShowButton = bChecked
		HM.InitButton()
	end)
	--nX = ui:Append("WndCheckBox", { x = 0, y = 300 checked = HM_About.bPlayOpen })
	--:Text(_L["Play music on hourly first time to open panel"]):Click(function(bChecked) HM_About.bPlayOpen = bChecked end):Pos_()
	nX = ui:Append("WndCheckBox", { x = nX, y = 300, checked = HM_About.bDebug == true }):Text("Enable Debug"):Click(function(bChecked)
		HM_About.bDebug = bChecked
	end):Pos_()
	ui:Append("Text", { x = nX + 10, y = 300, txt = "<" .. _L["Haiman Site"] .. ">" }):Click(function()
		if HM_Secret then
			HM.OpenPanel(_L["Haiman Site"])
		else
			HM.Sysmsg(HM.szRemoteHost .. " 或微信公众号【海鳗插件】")
			HM.Sysmsg(HM.szRemoteHost .. " 或微信公众号【海鳗插件】")
		end
	end)
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
	--ui:Append("Image", { x = 0, y = 5, w = 532, h = 168 }):File(HM.GetCustomFile("image.UITEX", "interface\\HM\\HM_0Base\\image.UITEX"), nF):Click(function()
	--	if nF == 1 and HM_Love then
	--		HM.OpenPanel(HM_Love.szTitle)
	--	end
	--end)
	ui:Append("Shadow", { x = 0, y = 5, w = 532, h = 168, alpha = 128 }):Color(128, 128, 128)
	if HM.szClientLang == "zhcn" then
		ui:Append("Text", { x = 0, y = 5, font = 239,  w = 532, h = 100, txt = "海鳗插件官网" }):Align(1, 1):Click(function()
			if HM_Secret then
				HM.OpenPanel(_L["Haiman Site"])
			else
				HM.Sysmsg(HM.szRemoteHost .. " 或微信公众号【海鳗插件】")
				HM.Sysmsg(HM.szRemoteHost .. " 或微信公众号【海鳗插件】")
			end
		end)
		ui:Append("Text", { x = 0, y = 90, font = 61,  w = 532, h = 20, txt = "游戏辅助  资料查询  科举题库" }):Align(1, 1)
		ui:Append("Text", { x = 0, y = 120, font = 61,  w = 532, h = 20, txt = "开服监控  日常提醒  玩家交流" }):Align(1, 1)
	else
		ui:Append("Text", { x = 0, y = 5, font = 239,  w = 532, h = 100, txt = "Empty color is the color that is empty." }):Align(1, 1)
	end
	ui:Append("Text", { txt = _L("%s are welcome to use HM plug-in", szName), x = 10, y = 200, font = 239 })
	ui:Append("Text", { txt = _L["Free & open source, Utility, Focus on PVP!"], x = 10, y = 230, font = 239 })
	ui:Append("Text", { txt = _L["QQ-group: 54516791"], x = 10, y = 280, font = 27 })
	-- buttons
	local nX = 0
	--[[
	ui:Append("Text", { txt = _L["<Opening music>"], x = 10, y = 305, font = 27 }):Click(function()
		local szSound = "interface\\HM\\HM_0Base\\open" .. math.ceil(math.random() * 3) .. ".wav"
		PlaySound(SOUND.UI_SOUND, HM.GetCustomFile("opening.wav", szSound))
	end):Pos_()
	--]]
	nX = ui:Append("Text", { txt = _L["<About plug-in>"], x = nX + 10, y = 305, font = 27 }):Click(function()
		HM.OpenPanel(_L["About plug-in"])
	end):Pos_()
	--nX = ui:Append("Text", { txt = _L["<Latest version>"], x = nX + 10, y = 305, font = 27 }):Click(function()
	--	OpenInternetExplorer(_HM_About.szHost .. "down/")
	--end):Pos_()
	nX = ui:Append("Text", { txt = _L["<Set hotkeys>"], x = nX + 10, y = 305, font = 27 }):Click(HM.SetHotKey):Pos_()
	nX = ui:Append("Text", { txt = _L["<Weibo@haimanman>"], x = nX + 10, y = 305, font = 27 }):Click(function()
		OpenInternetExplorer("https://weibo.com/haimanman")
	end):Pos_()
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("LOADING_END", function()
	if not _HM_About.bChecked then
		_HM_About.CheckLocalDeny()
		--_HM_About.CheckUpdate()
	end
end)
HM.RegisterEvent("CALL_LUA_ERROR", function()
	if HM_About.bDebug then
		OutputMessage("MSG_SYS", arg0)
	end
end)
--[[
HM.RegisterEvent("ON_FRAME_CREATE.exam", function()
	if arg0:GetName() == "ExaminationPanel" then
		_HM_About.AppendExampTip(arg0)
	end
end)
--]]

-- add to HM panel
HM.RegisterPanel(_L["About plug-in"], 368, _L["Others"], _HM_About.PS)

-- init global caller
_HM_About.LoadDataEx()
--_HM_About.AddNameEx(_L["HMM5"])

-- protect HM_About
local _About = {
	AddNameEx = _HM_About.AddNameEx,
	CheckTarEx = _HM_About.CheckTarEx,
	CheckNameEx = _HM_About.CheckNameEx,
	OnTaboxCheck = _HM_About.PS.OnTaboxCheck,
	OnPanelActive = _HM_About.PS.OnTaboxCheck,
	GetAuthorInfo = _HM_About.PS.GetAuthorInfo,
	SyncData = _HM_About.SyncData,
	GetSyncData = _HM_About.GetSyncData,
}
setmetatable(HM_About, { __metatable = true, __index = _About, __newindex = function() end } )
