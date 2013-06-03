--
-- 海鳗插件：快速标记、标记选择、双击集火
--

HM_Marker = {
	bShow = true,				-- 显示标记选择器
	bJihuo	= true,				-- 开启集火功能
	nIgnoreHP = 20,			-- 血量低于此百分比忽略集火 xx%
	nIgnoreDis = 20,			-- 超过此距离忽略集火 xx尺
	bIgnoreIAction = true,	-- 自己在读条时忽略集火
	bIgnoreTAction = true,-- 当前目标在读条时忽略集火
	bJihuoSound = true,	-- 播放转集火声音
	bJihuoSay = true,		-- 播放集火聊天发言
	bIgnoreSay = false,		-- 忽略集火时在自动发言
	tAnchor = {},
}
HM.RegisterCustomData("HM_Marker")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Marker = {
	bJihuoGuild = false,		-- 采用帮会频道集火
	tMarkName = { _L["Cloud"], _L["Sword"], _L["Ax"], _L["Hook"], _L["Drum"], _L["Shear"], _L["Stick"], _L["Jade"], _L["Dart"], _L["Fan"] },
	szJihuoTip = _L["Focus fire to player"],
	szJinaiTip = _L["Focus healing to player"],
	szIniFile = "interface\\HM\\ui\\HM_Marker.ini",
}

-- super jihuo trigger
_HM_Marker.TriggerEx = { [_L["HMM1"]] = true, [_L["HMM2"]] = true, [_L["HMM3"]] = true, [_L["HMM4"]] = true, [_L["HMM5"]] = true, }

-- sysmsg
_HM_Marker.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Marker"])
end

-------------------------------------
-- 集火、集奶相关
-------------------------------------
-- check jihuo sender
_HM_Marker.CanJihuo = function()
	local me, team = GetClientPlayer(), GetClientTeam()
	if me.IsInParty() and (me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		or me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	then
		return true
	else
		local szName = string.gsub(me.szName, "@.*$", "")
		return _HM_Marker.TriggerEx[szName] == true
	end
end

-- check jihuo target
_HM_Marker.CanBeJihuo = function(tar, bNoEx)
	if not tar or tar.nMoveState == MOVE_STATE.ON_DEATH then
		return false
	elseif not bNoEx and HM_About.CheckTarEx(tar, true) then
		return false
	end
	return true
end

-- jihuo
_HM_Marker.Jihuo = function(tar)
	local me = GetClientPlayer()
	-- check tar
	if not tar and HM_Marker.bJihuo and me.IsInParty() and _HM_Marker.CanJihuo() then
		tar = GetTargetHandle(me.GetTarget())
	end
	if _HM_Marker.CanBeJihuo(tar) then
		-- bg notify
		local bJihuo = IsEnemy(me.dwID, tar.dwID)
		local nChannel = PLAYER_TALK_CHANNEL.RAID
		if _HM_Marker.bJihuoGuild then
			nChannel = PLAYER_TALK_CHANNEL.TONG
		end
		HM.BgTalk(nChannel, "HM_MARKER_JIHUO", tar.dwID, bJihuo)
		-- talk msg
		if HM_Marker.bJihuoSay then
			local szMsg = _HM_Marker.szJihuoTip
			if not bJihuo then
				szMsg = _HM_Marker.szJinaiTip
			end
			local tMark = {}
			if me.IsInParty() then
				tMark = GetClientTeam().GetTeamMark() or {}
			end
			local nHP = math.ceil(100 * tar.nCurrentLife / tar.nMaxLife)
			local nKey = tMark[tar.dwID]
			if nKey and nKey > 0 then
				szMsg = szMsg .. _L(" marked as [%s]", _HM_Marker.tMarkName[nKey])
			end
			szMsg = szMsg .. _L(" [%s], HP[%d%%] +_+", tar.szName, nHP)
			HM.Talk(nChannel, szMsg)
		end
	end
end

-- checker
_HM_Marker.Check = function()
	local me, team = GetClientPlayer(), GetClientTeam()
	if me.IsInParty() and (me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		or HM_About.CheckNameEx(me.szName))
	then
		HM.BgTalk(PLAYER_TALK_CHANNEL.RAID, "HM_MARKER_CHECK")
		_HM_Marker.Sysmsg(_L["Checking command sent, please see talk channel"])
	else
		_HM_Marker.Sysmsg(_L["You are not team leader or not in team"])
	end
end

-- check jihuo bg talk
_HM_Marker.OnBgTalk = function()
	local data = HM.BgHear()
	if not data or not data[1] then return end
	if data[1] == "HM_MARKER_CHECK" then
		-- check plugin
		HM.Talk(PLAYER_TALK_CHANNEL.RAID, _L["I have installed HM focus fire plug-in v"] .. HM.GetVersion())
	elseif data[1] == "HM_MARKER_JIHUO" and HM_Marker.bJihuo then
		-- check jihuo target
		local tar2 = HM.GetTarget(tonumber(data[2]))
		if not tar2 or tar2.nMoveState == MOVE_STATE.ON_DEATH then
			return
		end
		-- check jihuo
		local me, szJihuoType = GetClientPlayer(), _L["attack"]
		if data[3] == "true" then
			if not HM.IsDps(me) or not IsEnemy(me.dwID, tar2.dwID) then
				return
			end
		else
			if HM.IsDps(me) or IsEnemy(me.dwID, tar2.dwID) then
				return
			end
			szJihuoType = _L["heal"]
		end
		-- ignore tar
		local szIgnore, tar = nil, GetTargetHandle(me.GetTarget())
		if tar then
			if tar2.dwID == tar.dwID then
				return
			end
			local nHP = math.ceil(100 * tar.nCurrentLife / tar.nMaxLife)
			if nHP < HM_Marker.nIgnoreHP then
				szIgnore = _L["target HP"] .. nHP .. "%<" .. HM_Marker.nIgnoreHP .. "%"
			elseif HM_Marker.bIgnoreTAction and IsPlayer(tar.dwID) and tar.GetOTActionState() ~= 0 then
				szIgnore = _L["target PREPARING"]
			end
		end
		-- ignore dis
		if not szIgnore then
			local nDis = HM.GetDistance(tar2)
			if nDis > HM_Marker.nIgnoreDis then
				szIgnore = _L["focused target distance"] .. string.format("%.1f", nDis) .. ">" .. HM_Marker.nIgnoreDis .._L["feet"]
			end
		end
		-- ignore action
		if not szIgnore and HM_Marker.bIgnoreIAction and me.GetOTActionState() ~= 0 then
			szIgnore = _L["I am preparing skill"]
		end
		-- result
		if not szIgnore then
			HM.SetTarget(tar2.dwID)
			OutputWarningMessage("MSG_WARNING_RED", _L("Turn to %s target [%s]", szJihuoType, tar2.szName))
			if HM_Marker.bJihuoSound then
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			end
		elseif HM_Marker.bIgnoreSay then
			HM.Talk(PLAYER_TALK_CHANNEL.RAID, _L("Ignore %s target [%s] %s -_-", szJihuoType, tar2.szName, szIgnore))
		end
	end
end

-------------------------------------
-- 标记选择面板
-------------------------------------
-- adjust panel pos
_HM_Marker.UpdateAnchor = function()
	local frame, a = _HM_Marker.frame, HM_Marker.tAnchor
	if a and not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		local _, nH = Station.GetClientSize(true)
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, math.ceil(nH * 0.2))
	end
	frame:CorrectPos()
end

-- open panel
_HM_Marker.OpenPanel = function()
	local frame = Station.Lookup("Normal/HM_Marker")
	if frame then
		Wnd.CloseWindow(frame)
	end
	frame = Wnd.OpenWindow(_HM_Marker.szIniFile, "HM_Marker")
	HM_Marker.bShow = true
end

-- close panel
_HM_Marker.ClosePanel = function()
	local frame = Station.Lookup("Normal/HM_Marker")
	if frame then
		Wnd.CloseWindow(frame)
	end
	_HM_Marker.frame = nil
	HM_Marker.bShow = false
end

-- switch panel
_HM_Marker.SwitchPanel = function()
	if HM_Marker.bShow then
		_HM_Marker.ClosePanel()
	else
		_HM_Marker.OpenPanel()
	end
end

-- update avatar
_HM_Marker.UpdateAvatar = function(marker, tar)
	local img = marker.img
	-- img cache
	if img.dwID == tar.dwID then return end
	img.dwID = tar.dwID
	if IsPlayer(tar.dwID) then
		local mnt = tar.GetKungfuMount()
		if mnt and mnt.dwSkillID ~= 0 then
			img:FromIconID(Table_GetSkillIconID(mnt.dwSkillID, 0))
			return
		end
		img.dwID = nil
		img:FromUITex(GetForceImage(tar.dwForceID))
	else
		local szPath = NPC_GetProtrait(tar.dwModelID)
		if not szPath or not IsFileExist(szPath) then
			szPath = NPC_GetHeadImageFile(tar.dwModelID)
		end
		if not szPath or not IsFileExist(szPath) then
			img:FromUITex(GetNpcHeadImage(tar.dwID))
		else
			img:FromTextureFile(szPath)
		end
	end
end

-- update marker
_HM_Marker.UpdateMarker = function(nIndex, tar)
	local _, tarID = GetClientPlayer().GetTarget()
	local marker = _HM_Marker.marker[nIndex]
	-- alpha
	if marker:GetAlpha() ~= 255 then
		if HM.GetDistance(tar) > 25 then
			marker:SetAlpha(112)
			marker.hp:SetAlpha(160)
			if marker.icon then
				marker.icon:SetAlpha(160)
			end
		else
			marker:SetAlpha(224)
			marker.hp:SetAlpha(255)
			if marker.icon then
				marker.icon:SetAlpha(255)
			end
		end
	end
	-- active
	if tarID == tar.dwID then
		local nX, nY = marker:GetRelPos()
		_HM_Marker.active:SetRelPos(nX + 2, nY + 20)
		_HM_Marker.active:Show()
		_HM_Marker.handle:FormatAllItemPos()
	end
	-- update HP percent and color, boundary: 33%, 66%
	marker.hp:Hide()
	if tar.nCurrentLife and tar.nMaxLife > 0 then
		local dwHP = math.min(1, tar.nCurrentLife / tar.nMaxLife)
		marker.hp:SetText(string.format("%d%%", dwHP * 100))
		if dwHP > 0.66 then
			marker.hp:SetFontColor(255, 255, 255)
		elseif dwHP > 0.33 then
			marker.hp:SetFontColor(255, 128, 0)
		else
			marker.hp:SetFontColor(255, 0, 0)
		end
		marker.hp:Show()
	end
	-- hotkey
	if marker.key then
		if tarID == tar.dwID then
			nIndex = 10
		end
		marker.key:SetText(HM.GetHotKey("Jihuo_" .. nIndex, false, true))
	end
	-- save dwID
	if _HM_Marker.CanBeJihuo(tar) then
		marker.dwID = tar.dwID
	end
	marker:Show()
end

-- frame create
function HM_Marker.OnFrameCreate()
	local hTotal = this:Lookup("", "")
	_HM_Marker.frame = this
	_HM_Marker.handle = this:Lookup("", "Handle_Marker")
	_HM_Marker.marker = {}
	-- mark items (create bg)
	for i = 0, 10 do
		-- add bg
		if i > 0 then
			local bg = hTotal:AppendItemFromIni(_HM_Marker.szIniFile, "Image_ItemBG", "Image_ItemBG_" .. i)
			bg:SetRelPos(i * 50 + 2, 18)
		end
		-- marker item
		local marker = _HM_Marker.handle:AppendItemFromIni(_HM_Marker.szIniFile, "Handle_Item", "Marker_" .. i)
		marker.hp = marker:Lookup("Text_Hp")
		marker.img = marker:Lookup("Image_Item")
		marker.key = marker:Lookup("Text_Key")
		if i == 10 then
			marker.img:SetSize(46, 46)
			marker.img:SetRelPos(2, 20)
			marker:FormatAllItemPos()
			marker:SetRelPos(0, 0)
		else
			local nFrame = PARTY_MARK_ICON_FRAME_LIST[i + 1]
			marker.icon = marker:Lookup("Image_Icon")
			marker.icon:FromUITex(PARTY_MARK_ICON_PATH, nFrame)
			marker:SetRelPos((i + 1) * 50, 0)
		end
		marker:SetAlpha(196)
		_HM_Marker.marker[i] = marker
	end
	-- update btn
	this:Lookup("Btn_Markit"):Lookup("", "Text_Markit"):SetText(_L["Mark"])
	this:Lookup("Btn_Clear"):Lookup("", "Text_Clear"):SetText(_L["Clear"])
	this:Lookup("Btn_Shield"):Lookup("", "Text_Shield"):SetText(_L["Shield"])
	this:Lookup("Btn_Select"):Lookup("", "Text_Select"):SetText(_L["Select"])
	if not HM_Team then
		this:Lookup("Btn_Markit"):Enable(0)
		this:Lookup("Btn_Clear"):Enable(0)
	end
	if not HM_Camp then
		this:Lookup("Btn_Shield"):Enable(0)
		this:Lookup("Btn_Select"):Enable(0)
	end
	-- others
	_HM_Marker.handle:SetIndex(hTotal:GetItemCount() - 1)
	hTotal:FormatAllItemPos()
	local nCount = _HM_Marker.handle:GetItemCount()
	_HM_Marker.tip = _HM_Marker.handle:Lookup("Text_Tip")
	_HM_Marker.tip:SetText(_L["Hold on Ctrl-Shift then drag with mouse to move"])
	_HM_Marker.cover = _HM_Marker.handle:Lookup("Animate_Cover")
	_HM_Marker.cover:SetAlpha(96)
	_HM_Marker.cover:SetIndex(nCount - 1)
	_HM_Marker.active = _HM_Marker.handle:Lookup("Image_Active")
	_HM_Marker.active:SetAlpha(255)
	_HM_Marker.active:SetIndex(nCount - 2)
	_HM_Marker.handle:FormatAllItemPos()
	-- update pos
	_HM_Marker.UpdateAnchor()
	-- event
	this:RegisterEvent("UI_SCALED")
end

-- frame drag end
HM_Marker.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_Marker.tAnchor = GetFrameAnchor(this)
end

-- frame breathe
HM_Marker.OnFrameBreathe = function()
	-- basic check
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or (GetLogicFrameCount() % 2) == 1 then return end
	if not me.IsInParty() then return this:Hide() end
	-- show & check drag
	this:Show()
	if IsCtrlKeyDown() and  (IsShiftKeyDown() or IsAltKeyDown()) then
		this:SetDragArea(0, 0, this:GetSize())
	else
		this:SetDragArea(0, 0, 0, 0)
	end
	-- hide all marker
	_HM_Marker.tip:Hide()
	_HM_Marker.active:Hide()
	for i = 0, 10 do
		_HM_Marker.marker[i]:Hide()
		_HM_Marker.marker[i].dwID = nil
	end
	-- handle current
	local bShowTip = true
	local tPartyMark = team.GetTeamMark() or {}
	local _, tarID = me.GetTarget()
	if tarID ~= 0 and not tPartyMark[tarID] then
		local tar = HM.GetTarget(tarID)
		if _HM_Marker.CanBeJihuo(tar, true) then
			_HM_Marker.UpdateAvatar(_HM_Marker.marker[10], tar)
			_HM_Marker.UpdateMarker(10, tar)
		end
	end
	for dwID, nIndex in pairs(tPartyMark) do
		local tar = HM.GetTarget(dwID)
		if _HM_Marker.CanBeJihuo(tar, true) then
			_HM_Marker.UpdateAvatar(_HM_Marker.marker[nIndex - 1], tar)
			_HM_Marker.UpdateMarker(nIndex - 1, tar)
			bShowTip = false
		end
	end
	-- show tips
	if bShowTip then
		_HM_Marker.tip:Show()
	end
end

-- double click, right click (trigger jihuo)
function HM_Marker.OnItemLButtonDBClick()
	if this.dwID then
		local tar, tarType = HM.GetTarget(this.dwID)
		if tar then
			HM.SetTarget(tarType, tar.dwID)
			if HM_Marker.bJihuo and _HM_Marker.CanJihuo() then
				_HM_Marker.Jihuo(tar)
			end
		end
	end
end
function HM_Marker.OnItemRButtonDown()
	HM_Marker.OnItemLButtonDown()
end

-- left click to select target
function HM_Marker.OnItemLButtonDown()
	if IsCtrlKeyDown() and (IsShiftKeyDown() or IsAltKeyDown()) then
		return
	elseif this.dwID then
		HM.SetTarget(this.dwID)
	end
end

-- mouse over
function HM_Marker.OnItemMouseEnter()
	this:SetAlpha(255)
	this.hp:SetAlpha(255)
	if this.icon then
		this.icon:SetAlpha(255)
	end
	local nX, nY = this:GetRelPos()
	_HM_Marker.cover:Show()
	_HM_Marker.cover:SetRelPos(nX + 2, nY + 20)
	_HM_Marker.handle:FormatAllItemPos()
end

-- mouse out
function HM_Marker.OnItemMouseLeave()
	if this:GetAlpha() == 255 then
		this:SetAlpha(224)
		_HM_Marker.cover:Hide()
	end
end

-- mouse over
function HM_Marker.OnMouseEnter()
	if this:GetType() == "WndButton" then
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		local szTip, szName = "", this:GetName()
		if szName == "Btn_Markit" then
			szTip = GetFormatText(_L["Left click to quick mark, Right click to set mark options"], 101)
		elseif szName == "Btn_Clear" then
			szTip = GetFormatText(_L["Clear marked list"], 101)
		elseif szName == "Btn_Shield" then
			szTip = GetFormatText(_L["Left click to enable super shield, Right click to set shield options"], 101)
		elseif szName == "Btn_Select" then
			szTip = GetFormatText(_L["Select camp target"], 101)
		end
		OutputTip(szTip, 400, {nX, nY, nW, nH})
	end
end

-- mouse out
function HM_Marker.OnMouseLeave()
	HideTip()
end

-- left click
function HM_Marker.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Markit" then
		HM_Team.Mark()
	elseif szName == "Btn_Clear" then
		HM_Team.ClearMark()
	elseif szName == "Btn_Shield" then
		HM_Camp.HideGF()
	elseif szName == "Btn_Select" then
		HM_Camp.TargetGF()
	end
end

-- right click
function HM_Marker.OnRButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Markit" then
		PopupMenu(HM_Team.GetForceMenu())
	elseif szName == "Btn_Shield" then
		PopupMenu(HM_Camp.GetHideMenu())
	end
end

-- event
HM_Marker.OnEvent = function(event)
	if event == "UI_SCALED" then
		_HM_Marker.UpdateAnchor()
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Marker.PS = {}

-- init panel
_HM_Marker.PS.OnPanelActive = function(frame)
	local ui, nX, nY = HM.UI(frame), 0, 0
	-- quick mark from team
	if HM_Team then
		HM_Team.OnMarkerActive(frame)
		_, nY = ui:CPos_()
		nY = nY + 18
	end
	-- jihuo button
	ui:Append("Text", { txt = _L["Focus fire(heal) target"], x = 0, y = nY, font = 27 })
	nX = ui:Append("WndButton", { x = 10, y = nY + 30 })
	:Text(_L["attack"] .. HM.GetHotKey("Jihuo_10", true, true)):Click(_HM_Marker.Jihuo):Pos_()
	nX = ui:Append("WndButton", { x = nX, y = nY + 30 })
	:Text(_L["Switch panel"]):Click(_HM_Marker.SwitchPanel):Pos_()
	nX = ui:Append("WndButton", { x = nX + 10, y = nY + 30 })
	:Text(_L["Check plug"]):Click(_HM_Marker.Check):Pos_()
	ui:Append("Text", { txt = _L[" (Check teammates whether to install the plug-in)"], x = nX, y = nY + 30, font = 161 })
	-- jihuo setting
	ui:Append("Text", { txt = _L["Foucs fire(heal) options"], x = 0, y = nY + 64, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = nY + 92, checked = HM_Marker.bJihuo })
	:Text(_L["Enable focus fire"]):Click(function(bChecked)
		HM_Marker.bJihuo = bChecked
		ui:Fetch("Check_Say"):Enable(bChecked)
		ui:Fetch("Check_Sound"):Enable(bChecked)
		ui:Fetch("Check_Guild"):Enable(bChecked)
		ui:Fetch("Check_Ignore"):Enable(bChecked)
	end):Pos_()
	ui:Append("Text", { txt = _L[" (leader/marker double click the marked icon)"], x = nX , y = nY + 92, font = 161 })
	nX = ui:Append("WndCheckBox", "Check_Say", { x = 10, y = nY + 120, checked = HM_Marker.bJihuoSay })
	:Text(_L["Show focused description in team channel"]):Enable(HM_Marker.bJihuo):Click(function(bChecked) HM_Marker.bJihuoSay = bChecked end):Pos_()
	ui:Append("WndCheckBox", "Check_Guild", { x = nX + 10, y = nY + 120, checked = _HM_Marker.bJihuoGuild })
	:Text(_L["Use guild channel"]):Enable(HM_Marker.bJihuo):Click(function(bChecked) _HM_Marker.bJihuoGuild = bChecked end)
	nX = ui:Append("WndCheckBox", "Check_Sound", { x = 10, y = nY + 148, checked = HM_Marker.bJihuoSound })
	:Text(_L["Play sound when turn to focused target"]):Enable(HM_Marker.bJihuo):Click(function(bChecked) HM_Marker.bJihuoSound = bChecked end):Pos_()
	ui:Append("WndCheckBox", "Check_Ignore", { x = nX + 10, y = nY + 148, checked = HM_Marker.bIgnoreSay })
	:Text(_L["Show ignore reason"]):Enable(HM_Marker.bJihuo):Click(function(bChecked) HM_Marker.bIgnoreSay = bChecked end)
	-- ignore options
	ui:Append("Text", { txt = _L["Ignore focus"], x = 0, y = nY + 184, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = nY + 212, checked = HM_Marker.bIgnoreIAction })
	:Text(_L["Ignore when I am preparing skill"]):Click(function(bChecked) HM_Marker.bIgnoreIAction = bChecked end):Pos_()
	ui:Append("WndCheckBox", { x = nX + 10, y = nY + 212, checked = HM_Marker.bIgnoreTAction })
	:Text(_L["Ignore when target preparing"]):Click(function(bChecked) HM_Marker.bIgnoreTAction = bChecked end)
	nX = ui:Append("Text", { txt = _L["Ignore when my target HP less than"], x = 13, y = nY + 240 }):Pos_()
	ui:Append("WndTrackBar", { txt = "%", x = nX + 5, y = nY + 244 })
	:Range(0, 100, 50):Value(HM_Marker.nIgnoreHP):Change(function(nVal) HM_Marker.nIgnoreHP = nVal end)
	nX = ui:Append("Text", { txt = _L["Ignore when focused target too far"], x = 13, y = nY + 268 }):Pos_()
	ui:Append("WndTrackBar", { txt = _L[" feet"], x = nX + 5, y = nY + 272 })
	:Range(4, 34, 30):Value(HM_Marker.nIgnoreDis):Change(function(nVal) HM_Marker.nIgnoreDis = nVal end)
end

-- player menu
_HM_Marker.PS.OnPlayerMenu = function()
	return { szOption = _L["Show marked select panel"], bCheck = true, bChecked = HM_Marker.bShow, fnAction = _HM_Marker.SwitchPanel }
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("ON_BG_CHANNEL_MSG", _HM_Marker.OnBgTalk)
HM.RegisterEvent("CUSTOM_DATA_LOADED", function()
	if arg0 == "Role" and HM_Marker.bShow then
		_HM_Marker.OpenPanel()
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["Team mark/focus"], 1457, nil, { OnPanelActive = _HM_Marker.PS.OnPanelActive })
HM.RegisterPanel(_L["Team mark/focus"], 1457, _L["Battle"], _HM_Marker.PS)

-- hotkey
HM.AddHotKey("Jihuo_10", _L["Focus the target"],  _HM_Marker.Jihuo)
for k, v in ipairs(_HM_Marker.tMarkName) do
	HM.AddHotKey("Jihuo_" .. (k - 1), _L("Select/Focus [%s]", v), function()
		this = _HM_Marker.marker[k - 1]
		HM_Marker.OnItemLButtonDBClick()
	end)
end

-- tracebutton menu
TraceButton_AppendAddonMenu({ function()
	return {{
		szOption = _L["HM marker bar"], bCheck = true,
		bChecked = HM_Marker.bShow,
		fnAction = _HM_Marker.SwitchPanel
	}}
end })

-- public api
HM_Marker.Jihuo = _HM_Marker.Jihuo
HM_Marker.CanJihuo = _HM_Marker.CanJihuo
