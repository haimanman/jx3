--
-- 海鳗插件：五毒仙王蛊鼎显示、自动吃
--

HM_Guding = {
	bEnable = true,			-- 总开关
	bAutoUse = true,		-- 路过时自动吃
	nAutoMp = 80,			-- 自动吃的 MP 百分比
	nAutoHp = 80,			-- 自动吃的 HP 百分比
	bAutoSay = true,			-- 摆鼎后自动说话
	szSay = _L["I have put the GUDING, hurry to eat if you lack of mana. *la la la*"],
	color = { 255, 0, 128 },	-- 名称颜色，默认绿色
}
HM.RegisterCustomData("HM_Guding")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Guding = {
	nMaxDelay = 500,	-- 释放和出现的最大时差，单位毫秒
	nMaxTime = 60000, -- 存在的最大时间，单位毫秒
	dwSkillID = 2234,
	dwTemplateID = 2418,
	szIniFile = "interface\\HM\\ui\\HM_Guding.ini",
	tList = {},					-- 显示记录 (#ID => nTime)
	tCast = {},				-- 技能释放记录
	nUseFrame = 0,		-- 上次自动吃鼎时间
}

-- sysmsg
_HM_Guding.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Guding"])
end

-- debug
_HM_Guding.Debug = function(szMsg)
	HM.Debug(szMsg, _L["HM_Guding"])
end

-- add to list
_HM_Guding.AddToList = function(tar, dwCaster, dwTime, szEvent)
	_HM_Guding.tList[tar.dwID] = { dwCaster = dwCaster, dwTime = dwTime }
	-- bg notify
	local me = GetClientPlayer()
	if szEvent == "DO_SKILL_CAST" and me.IsInParty() then
		HM.BgTalk(PLAYER_TALK_CHANNEL.RAID, "HM_GUDING_NOTIFY", tar.dwID, dwCaster)
	end
	if HM_Guding.bAutoSay and me.dwID == dwCaster then
		local nChannel = PLAYER_TALK_CHANNEL.RAID
		if not me.IsInParty() then
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		end
		HM.Talk(nChannel, HM_Guding.szSay)
	end
end

-- remove record
_HM_Guding.RemoveFromList = function(dwID)
	local data = _HM_Guding.tList[dwID]
	local nTime = GetTime() - data.dwTime
	if nTime >=  _HM_Guding.nMaxTime then
		if data.label then
			_HM_Guding.pLabel:Free(data.label)
		end
		_HM_Guding.tList[dwID] = nil
	elseif data.label then
		data.label:Hide()
	end
end

-- auto eat (fast to eat twice)
_HM_Guding.AutoUse = function(tar)
	local me, nFrame = GetClientPlayer(), GetLogicFrameCount()
	if nFrame >= _HM_Guding.nUseFrame and (nFrame - _HM_Guding.nUseFrame) <= 8 then
		return
	end
	_HM_Guding.nUseFrame = nFrame
	if me.nMoveState == MOVE_STATE.ON_STAND
		and not me.bOnHorse
		and me.GetOTActionState() == 0
		and HM.GetDistance(tar) < 6
		and ((me.nCurrentMana / me.nMaxMana) <= (HM_Guding.nAutoMp / 100)
			or (me.nCurrentLife / me.nMaxLife) <= (HM_Guding.nAutoHp / 100))
	then
		InteractDoodad(tar.dwID)
		_HM_Guding.Sysmsg(_L["Auto use GUDING"])
	end
end

-- show name
_HM_Guding.ShowName = function(tar)
	local data = _HM_Guding.tList[tar.dwID]
	local label = data.label
	if not label or not label:IsValid() then
		label = _HM_Guding.pLabel:New()
		label:SetFontColor(unpack(HM_Guding.color))
		data.label = label
	end
	local nX, nY = HM.GetTopPoint(tar, 768)
	if not nX or not nY then
		return label:Hide()
	end
	-- adjust text
	local szText = tar.szName .. _L["-"] .. math.floor((data.dwTime + _HM_Guding.nMaxTime - GetTime())/1000)
	local player = GetPlayer(data.dwCaster)
	if player then
		szText = player.szName .. _L["-"] .. szText
	end
	label:SetText(szText)
	-- adjust alpha (eat/not, auto eat ...)
	local tBuff = GetClientPlayer().GetBuffList() or {}
	label:SetAlpha(200)
	for _, v in ipairs(tBuff) do
		if v.dwID == 3448 and not v.bCanCancel then
			label:SetAlpha(120)
			break
		end
	end
	-- adjust pos & show
	local nW, nH = label:GetSize()
	label:SetAbsPos(nX - math.ceil(nW/2), nY - math.ceil(nH/2))
	label:Show()
	-- check to use
	if HM_Guding.bAutoUse and label:GetAlpha() > 199 then
		_HM_Guding.AutoUse(tar)
	end
end

-------------------------------------
-- 事件处理函数
-------------------------------------
-- skill cast log
_HM_Guding.OnSkillCast = function(dwCaster, dwSkillID, dwLevel, szEvent)
	local myID, player = GetClientPlayer().dwID, GetPlayer(dwCaster)
	if player and dwSkillID == _HM_Guding.dwSkillID and (dwCaster == myID or HM.IsParty(dwCaster)) then
		table.insert(_HM_Guding.tCast, { dwCaster = dwCaster, dwTime = GetTime(), szEvent = szEvent })
		_HM_Guding.Debug("[" .. player.szName .. "] cast [" .. HM.GetSkillName(dwSkillID, dwLevel) .. "#" .. szEvent .. "]")
	end
end

-- doodad enter
_HM_Guding.OnDoodadEnter = function()
	local tar = GetDoodad(arg0)
	if not tar or _HM_Guding.tList[arg0] or tar.dwTemplateID ~= _HM_Guding.dwTemplateID then
		return
	end
	_HM_Guding.Debug("[" .. tar.szName .. "] enter scene")
	-- find caster
	for k, v in ipairs(_HM_Guding.tCast) do
		local nTime = GetTime() - v.dwTime
		_HM_Guding.Debug("checking [#" .. v.dwCaster .. "], delay [" .. nTime .. "]")
		if nTime < _HM_Guding.nMaxDelay then
			table.remove(_HM_Guding.tCast, k)
			_HM_Guding.AddToList(tar, v.dwCaster, v.dwTime, v.szEvent)
			return _HM_Guding.Debug("matched [" .. tar.szName .. "] casted by [#" .. v.dwCaster .. "]")
		end
	end
	-- purge
	for k, v in pairs(_HM_Guding.tCast) do
		if (GetTime() - v.dwTime) > _HM_Guding.nMaxDelay then
			table.remove(_HM_Guding.tCast, k)
		end
	end
end

-- notify
_HM_Guding.OnSkillNotify = function()
	local data = HM.BgHear("HM_GUDING_NOTIFY")
	if data then
		local dwID = tonumber(data[1])
		if not _HM_Guding.tList[dwID] then
			_HM_Guding.tList[dwID] = { dwCaster = tonumber(data[2]), dwTime = GetTime() }
			_HM_Guding.Debug("received notify from [#" .. data[2] .. "]")
		end
	end
end

-- draw name
_HM_Guding.OnRender = function()
	for k, v in pairs(_HM_Guding.tList) do
		local tar = GetDoodad(k)
		if not tar or not HM_Guding.bEnable then
			if not v.bHide or (GetTime() - v.dwTime) >= _HM_Guding.nMaxTime then
				v.bHide = true
				_HM_Guding.RemoveFromList(k)
			end
		else
			v.bHide = false
			_HM_Guding.ShowName(tar)
		end
	end
end

-------------------------------------
-- 窗口函数
-------------------------------------
-- create
function HM_Guding.OnFrameCreate()
	local hnd = this:Lookup("", "")
	local xml = "<text>w=10 h=36 halign=1 valign=2 alpha=185 font=199 lockshowhide=1</text>"
	_HM_Guding.pLabel = HM.HandlePool(hnd, xml)
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("DO_SKILL_CAST")
	this:RegisterEvent("DOODAD_ENTER_SCENE")
	this:RegisterEvent("ON_BG_CHANNEL_MSG")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
end

-- event
function HM_Guding.OnEvent(event)
	if not HM_Guding.bEnable then
		return
	elseif event == "SYS_MSG" then
		if arg0 == "UI_OME_SKILL_HIT_LOG" then
			_HM_Guding.OnSkillCast(arg1, arg4, arg5, arg0)
		elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then
			_HM_Guding.OnSkillCast(arg1, arg5, arg6, arg0)
		end
	elseif event == "DO_SKILL_CAST" then
		_HM_Guding.OnSkillCast(arg0, arg1, arg2, event)
	elseif event == "DOODAD_ENTER_SCENE" then
		_HM_Guding.OnDoodadEnter()
	elseif event == "ON_BG_CHANNEL_MSG" then
		_HM_Guding.OnSkillNotify()
	elseif event == "RENDER_FRAME_UPDATE" then
		_HM_Guding.OnRender()
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Guding.PS = {}

-- init panel
_HM_Guding.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	ui:Append("Text", { txt = _L["Options"], font = 27 })
	local nX = ui:Append("WndCheckBox", { txt = _L["Display GUDING of teammate, change color"], checked = HM_Guding.bEnable })
	:Pos(10, 28):Click(function(bChecked)
		HM_Guding.bEnable = bChecked
		ui:Fetch("Check_Use"):Enable(bChecked)
		ui:Fetch("Check_Say"):Enable(bChecked)
		ui:Fetch("Track_MP"):Enable(bChecked)
		ui:Fetch("Track_HP"):Enable(bChecked)
		if not bChecked then
			_HM_Guding.pLabel:Clear()
		end
	end):Pos_()
	nX = ui:Append("Shadow", "Shadow_Color", { x = nX + 2, y = 32, w = 18, h = 18 })
	:Color(unpack(HM_Guding.color)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Shadow_Color"):Color(r, g, b)
			HM_Guding.color = { r, g, b }
			_HM_Guding.pLabel:Clear()
		end)
	end):Pos_()
	ui:Append("WndCheckBox", "Check_Use", { txt = _L["Auto use GUDING in some condition (only when standing)"], checked = HM_Guding.bAutoUse })
	:Pos(10, 56):Enable(HM_Guding.bEnable):Click(function(bChecked)
		HM_Guding.bAutoUse = bChecked
		ui:Fetch("Track_MP"):Enable(bChecked)
		ui:Fetch("Track_HP"):Enable(bChecked)
	end)
	nX = ui:Append("Text", { txt = _L["While MP less than"], x = 38, y = 84 }):Pos_()
	ui:Append("WndTrackBar", "Track_MP", { x = nX, y = 88, enable = HM_Guding.bAutoUse })
	:Range(0, 100, 50):Value(HM_Guding.nAutoMp):Change(function(nVal) HM_Guding.nAutoMp = nVal end)
	nX = ui:Append("Text", { txt = _L["While HP less than"], x = 38, y = 112 }):Pos_()
	ui:Append("WndTrackBar", "Track_HP", { x = nX, y = 116, enable = HM_Guding.bAutoUse })
	:Range(0, 100, 50):Value(HM_Guding.nAutoHp):Change(function(nVal) HM_Guding.nAutoHp = nVal end)
	ui:Append("WndCheckBox", "Check_Say", { txt = _L["Auto talk in team channel after puting GUDING"], checked = HM_Guding.bAutoSay })
	:Pos(10, 140):Enable(HM_Guding.bEnable):Click(function(bChecked)
		HM_Guding.bAutoSay = bChecked
		ui:Fetch("Edit_Say"):Enable(bChecked)
	end)
	ui:Append("Text", { txt = _L["Talk message"], font = 27, x = 0, y = 176 })
	ui:Append("WndEdit", "Edit_Say", { x = 14, y = 204, multi = true, limit = 512, w = 430, h = 60 })
	:Text(HM_Guding.szSay):Enable(HM_Guding.bAutoSay):Change(function(szText)
		HM_Guding.szSay = szText
	end)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM panel
HM.RegisterPanel(_L["5D GUDING"], 2747, nil, _HM_Guding.PS)

-- open hidden window
local frame = Station.Lookup("Lowest/HM_Guding")
if frame then Wnd.CloseWindow(frame) end
Wnd.OpenWindow(_HM_Guding.szIniFile, "HM_Guding")
