--
-- 海鳗插件：关于插件、简介、更新检测，上线喊话、内部名单
--

HM_About = {
	bPlayOpen = true,	-- 播放开场音乐
	bDebug = false,	-- 启用 DEBUG
}
RegisterCustomData("HM_About.bPlayOpen")

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

-- 作者帮会
_HM_About.szTongEx = { 0xBE, 0xBD, 0xEC, 0xCC }

-- 亲友名字
_HM_About.tNameEx = { 0xA9, 0xF7, 0xA9, 0xF7, 0xA3, 0xBA, }

-- 帮会黑名
-- 恶贯满盈|电锯惊魂|南诏宫|东灵水阁|朝歌暮弦|战你姨|度高社|荣耀|龙啸神州|东城卫|情义永恒|紫金之巅|一蝶恋花一|燕云十八骑@空雾峰
_HM_About.tBlackTong = { 0xE5, 0xB7, 0xED, 0xCE, 0xD5, 0xBF, 0x40, 0xEF, 0xC6, 0xCB, 0xB0, 0xAE, 0xCA, 0xC6, 0xD4, 0xE0, 0xD1, 0x7C, 0xBB, 0xD2, 0xA8, 0xBB, 0xB5, 0xC1, 0xFB, 0xB5, 0xBB, 0xD2, 0x7C, 0xDB, 0xE1, 0xAE, 0xD6, 0xF0, 0xBD, 0xCF, 0xD7, 0x7C, 0xE3, 0xBA, 0xC0, 0xD3, 0xE5, 0xD2, 0xE9, 0xC7, 0x7C, 0xC0, 0xCE, 0xC7, 0xB3, 0xAB, 0xB6, 0x7C, 0xDD, 0xD6, 0xF1, 0xC9, 0xA5, 0xD0, 0xFA, 0xC1, 0x7C, 0xAB, 0xD2, 0xD9, 0xC8, 0x7C, 0xE7, 0xC9, 0xDF, 0xB8, 0xC8, 0xB6, 0x7C, 0xCC, 0xD2, 0xE3, 0xC4, 0xBD, 0xD5, 0x7C, 0xD2, 0xCF, 0xBA, 0xC4, 0xE8, 0xB8, 0xAF, 0xB3, 0x7C, 0xF3, 0xB8, 0xAE, 0xCB, 0xE9, 0xC1, 0xAB, 0xB6, 0x7C, 0xAC, 0xB9, 0xAF, 0xDA, 0xCF, 0xC4, 0x7C, 0xEA, 0xBB, 0xAA, 0xBE, 0xE2, 0xBE, 0xE7, 0xB5, 0x7C, 0xAF, 0xD3, 0xFA, 0xC2, 0xE1, 0xB9, 0xF1, 0xB6, }

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
	if _HM_About.bDisableEx then
		return false
	end
	szName = string.gsub(szName, "@.*$", "")
	return _HM_About.tNameEx[szName] ~= nil
end

-- check special target
_HM_About.CheckTarEx = function(tar, bTong)
	local me = GetClientPlayer()
	if _HM_About.bDisableEx or not IsEnemy(me.dwID, tar.dwID) then
		return false
	end
	local szName = string.gsub(tar.szName, "@.*$", "")
	if _HM_About.tNameEx[szName] and not _HM_About.tNameEx[me.szName] then
		return true
	end
	--[[
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
	ui:Append("WndButton", { txt = _L["Set hotkeys"], x = nX + 10, y = 152 }):AutoSize(8):Click(HM.SetHotKey)
	-- author
	ui:Append("Text", { txt = _L["About HMM"], x = 0, y = 188, font = 27 })
	ui:Append("Text", { x = 0, y = 216, w = 500, h = 40, multi = true }):Align(0, 0):Text(_L["A pure PVP TianCe player of evil camp. Third-class operation, but first-class crazy and lazy!"])
	-- other
	ui:Append("Text", { txt = _L["Others"], x = 0, y = 264, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 0, y = 292, checked = HM_About.bPlayOpen })
	:Text(_L["Play music on hourly first time to open panel"]):Click(function(bChecked) HM_About.bPlayOpen = bChecked end):Pos_()
	if HM.bDevelopper then
		ui:Append("WndCheckBox", { x = nX + 10, y = 292, checked = HM_About.bDebug == true })
		:Text("Enable Debug"):Click(function(bChecked) HM_About.bDebug = bChecked end)
	end
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
	ui:Append("Image", { x = 0, y = 5, w = 532, h = 168 }):File("interface\\HM\\ui\\image.UITEX", 0)
	ui:Append("Text", { txt = _L("%s are welcome to use HM plug-in", szName), x = 10, y = 190, font = 19 })
	ui:Append("Text", { txt = _L["Free & open source, Utility, Focus on PVP!"], x = 10, y = 220, font = 19 })
	ui:Append("Text", { txt = _L["YY-group: 6685583"], x = 10, y = 280, font = 27 })
	-- buttons
	local nX = ui:Append("Text", { txt = _L["<Opening music>"], x = 10, y = 305, font = 27 }):Click(function()
		PlaySound(SOUND.UI_SOUND, "interface\\HM\\ui\\opening.wav")
	end):Pos_()
	nX = ui:Append("Text", { txt = _L["<About plug-in>"], x = nX + 10, y = 305, font = 27 }):Click(function()
		HM.OpenPanel(_L["About plug-in"])
	end):Pos_()
	nX = ui:Append("Text", { txt = _L["<Set hotkeys>"], x = nX + 10, y = 305, font = 27 }):Click(HM.SetHotKey):Pos_()
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
--[[
HM.RegisterEvent("LOADING_END", function()
	if not _HM_About.bChecked then
		_HM_About.CheckLocalDeny()
		_HM_About.bChecked = true
	end
end)
--]]
HM.RegisterEvent("CALL_LUA_ERROR", function()
	if HM_About.bDebug then
		OutputMessage("MSG_SYS", arg0)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["About plug-in"], 368, _L["Others"], _HM_About.PS)

-- add macro command
AppendCommand(_L["haiman"], function()
	_HM_Locker.bDisableEx = true
	HM.Sysmsg(_L("Good %s, thank you for choosing and using HM plug-in!", GetClientPlayer().szName))
end)

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
}
setmetatable(HM_About, { __metatable = true, __index = _About, __newindex = function() end } )
