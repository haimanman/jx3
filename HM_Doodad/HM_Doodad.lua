--
-- 海鳗插件：Doodad 物品采集拾取助手
--
HM_Doodad = {
	bLoot = true,				-- 自动拾取
	bLootFight = true,		-- 战斗中拾取
	bLootGray = false,		-- 拾取灰色
	bLootWhite = true,		-- 拾取白色
	bLootGreen = true,	-- 拾取绿色
	tLootFilter = {},			-- 过滤不捡的物品 [名称] => true/false,
	bLootOnly = false,		-- 只拾取指定物品
	tLootOnly = {},				-- 指定物品列表 [名称] => true/false,
	bManualFilter2 = false,	-- 手动拾取也过滤？=> true/false
	bQuest = true,				-- 自动采集任务物品
	bShowName = true,	-- 显示物品名称
	bMiniFlag = true,		-- 显示小地图标记
	--bInteract = true,			-- 自动采集
	tCraft = {},						-- 草药、矿石列表
	bCustom = true,			-- 启用自定义
	tCustom = {},				-- 自定义列表
	tNameColor = { 196, 64, 255 },	-- 头顶名称颜色
	bShowAll2 = false,
}
HM.RegisterCustomData("HM_Doodad")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local function _d(dwID)
	return GetDoodadTemplate(dwID).szName
end

local _HM_Doodad = {
	-- 草药、矿石列表
	tCraft = {
		1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
		1010, 1011, 1012, 1015, 1016, 1017, 1018, 1019, 2641,
		2642, 2643, 3321, 3358, 3359, 3360, 3361, 4227, 4228,
		0,	-- switch
		1020, 1021, 1022, 1023, 1024, 1025, 1027, 2644, 2645,
		4229, 4230,
	},
	tDoodad = {},	-- 待处理的 doodad 列表
	szIniFile = "interface\\HM\\HM_Doodad\\HM_Doodad.ini",
	nToLoot = 0,	-- 待拾取处理数量（用于修复判断）
}

-- filter menu
_HM_Doodad.GetFilterMenu = function()
	local m0 = {
		{
			szOption = _L["Filter on manual"], bCheck = true, bChecked = HM_Doodad.bManualFilter2,
			fnAction = function(d, b) HM_Doodad.bManualFilter2 = b end,
		}, {
			bDevide = true,
		}, {
			szOption = _L["Filter gray items"], bCheck = true, bChecked = not HM_Doodad.bLootGray,
			fnDisable = function() return HM_Doodad.bLootOnly end,
			fnAction = function(d, b) HM_Doodad.bLootGray = not b end,
		}, {
			szOption = _L["Filter white items"], bCheck = true, bChecked = not HM_Doodad.bLootWhite,
			fnDisable = function() return HM_Doodad.bLootOnly end,
			fnAction = function(d, b) HM_Doodad.bLootWhite = not b end,
		}, {
			szOption = _L["Filter green items"], bCheck = true, bChecked = not HM_Doodad.bLootGreen,
			fnDisable = function() return HM_Doodad.bLootOnly end,
			fnAction = function(d, b) HM_Doodad.bLootGreen = not b end,
		}
	}
	-- filter special
	local m1 = {
		szOption = _L["Filter specified items"],
		fnDisable = function() return HM_Doodad.bLootOnly end,
		{
			szOption = _L["* New *"],
			fnAction = function()
				GetUserInput(_L["Name of item"], function(szText)
					local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
					if szText ~= "" then
						HM_Doodad.tLootFilter[szText] = true
					end
				end)
			end
		}, {
			bDevide = true,
		}
	}
	for k, v in pairs(HM_Doodad.tLootFilter) do
		table.insert(m1, {
			szOption = k, bCheck = true, bChecked = v,
			fnAction = function(d, b) HM_Doodad.tLootFilter[k] = b end,
			{ szOption = _L["Remove"], fnAction = function() HM_Doodad.tLootFilter[k] = nil end }
		})
	end
	table.insert(m0, m1)
	-- loot special
	local m1 = {
		szOption = _L["Loot specified items"], bCheck = true, bChecked = HM_Doodad.bLootOnly,
		fnAction = function(d, b) HM_Doodad.bLootOnly = b end,
		{
			szOption = _L["* New *"],
			fnAction = function()
				GetUserInput(_L["Name of item"], function(szText)
					local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
					if szText ~= "" then
						HM_Doodad.tLootOnly[szText] = true
					end
				end)
			end
		}, {
			bDevide = true,
		}
	}
	for k, v in pairs(HM_Doodad.tLootOnly) do
		table.insert(m1, {
			szOption = k, bCheck = true, bChecked = v,
			fnAction = function(d, b) HM_Doodad.tLootOnly[k] = b end,
			{ szOption = _L["Remove"], fnAction = function() HM_Doodad.tLootOnly[k] = nil end }
		})
	end
	table.insert(m0, { bDevide = true })
	table.insert(m0, m1)
	return m0
end

-- get custom text
_HM_Doodad.GetCustomText = function()
	local szText = ""
	for k, _ in pairs(HM_Doodad.tCustom) do
		if szText == "" then
			szText = k
		else
			szText = szText .. "|" .. k
		end
	end
	return szText
end

-- try to add
_HM_Doodad.TryAdd = function(dwID, bDelay)
	local d = GetDoodad(dwID)
	if d then
		local data, me = nil, GetClientPlayer()
		if d.nKind == DOODAD_KIND.CORPSE or d.nKind == DOODAD_KIND.NPCDROP then
			if bDelay then
				--HM.Debug("delay to try add [" .. d.szName .. "#" .. d.dwID .. "]")
				return HM.DelayCall(500, function() _HM_Doodad.TryAdd(dwID) end)
			end
			if HM_Doodad.bLoot and d.CanLoot(me.dwID) then
				data = { loot = true }
			elseif HM_Doodad.bCustom and HM_Doodad.tCustom[d.szName]
				and GetDoodadTemplate(d.dwTemplateID).dwCraftID == 3
			then
				data = { craft = true }
			end
		elseif HM_Doodad.bQuest and (d.dwTemplateID == 3713 or d.dwTemplateID == 3714) then
			data = { craft = true }
		elseif HM_Doodad.tCraft[d.szName] or (HM_Doodad.bCustom and HM_Doodad.tCustom[d.szName]) then
			data = { craft = true }
		elseif d.HaveQuest(me.dwID) then
			if HM_Doodad.bQuest then
				data = { quest = true }
			end
		elseif d.dwTemplateID == 4733 or d.dwTemplateID == 4734 and HM_Doodad.bQuest then
			data = { craft = true }
		elseif HM_Doodad.bShowAll2 and d.nKind ~= DOODAD_KIND.QUEST and d.IsSelectable() then
			data = { other = true }
		end
		if data then
			_HM_Doodad.tDoodad[dwID] = data
			_HM_Doodad.bUpdateLabel = true
		end
	end
end

-- remove doodad
_HM_Doodad.Remove = function(dwID)
	local data = _HM_Doodad.tDoodad[dwID]
	if data then
		_HM_Doodad.tDoodad[dwID] = nil
		_HM_Doodad.bUpdateLabel = true
	end
end

-- reload doodad
_HM_Doodad.Reload = function()
	_HM_Doodad.tDoodad = {}
	for k, _ in pairs(HM.GetAllDoodadID()) do
		_HM_Doodad.TryAdd(k)
	end
	_HM_Doodad.bUpdateLabel = true
end

-- switch name
_HM_Doodad.SwitchName = function(bEnable)
	if bEnable == nil then
		HM_Doodad.bShowName = not HM_Doodad.bShow
	else
		HM_Doodad.bShowName = bEnable == true
	end
	local frame = Station.Lookup("Lowest/HM_Doodad")
	if HM_Doodad.bShowName then
		if not frame then
			Wnd.OpenWindow(_HM_Doodad.szIniFile, "HM_Doodad")
		end
	elseif frame then
		Wnd.CloseWindow(frame)
		_HM_Doodad.pLabel = nil
		_HM_Doodad.Reload()
	end
end

-- find & get opened dooad ID
_HM_Doodad.GetOpenDoodadID = function()
	local dwID = _HM_Doodad.dwOpenID
	if dwID then
		_HM_Doodad.dwOpenID = nil
	elseif HM_Doodad.bManualFilter2 then
		local tObject = Scene_SelectObject("all") or {}
		for _, v in pairs(tObject) do
			if v["Type"] == TARGET.DOODAD and IsCorpseAndCanLoot(v["ID"]) then
				dwID = v["ID"]
				break
			end
		end
	end
	return dwID
end

-------------------------------------
-- 事件处理
-------------------------------------
-- head name
_HM_Doodad.OnUpdateHeadName = function()
	local sha = _HM_Doodad.pLabel
	if not sha then return end
	local r, g, b = unpack(HM_Doodad.tNameColor)
	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()
	for k, v in pairs(_HM_Doodad.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(GetClientPlayer().dwID)) then
				_HM_Doodad.Remove(k)
			else
				local szName = tar.szName
				if tar.dwTemplateID == 3713 or tar.dwTemplateID == 3714 then
					szName = Table_GetNpcTemplateName(1622)
				end
				sha:AppendDoodadID(tar.dwID, r, g, b, 255, 128, 40, szName, 0, 1)
			end
		end
	end
	sha:Show()
end

-- auto interact
_HM_Doodad.OnAutoDoodad = function()
	local me = GetClientPlayer()
	-- auto interact
	if not me or me.GetOTActionState() ~= 0
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		or IsDialoguePanelOpened()
	then
		return
	end
	for k, v in pairs(_HM_Doodad.tDoodad) do
		local d, bKeep, bIntr = GetDoodad(k), false, false
		if not d or not d.CanDialog(me) or v.other then
			-- 若存在却不能对话只简单保留
			bKeep = d ~= nil
		elseif v.loot then		-- 尸体只摸一次
			bKeep = true	-- 改在 opendoodad 中删除
			bIntr = not me.bFightState or HM_Doodad.bLootFight
			if bIntr then
				_HM_Doodad.dwOpenID = k
			end
		elseif v.craft or d.HaveQuest(me.dwID) then		-- 任务和普通道具尝试 5 次
			bIntr = not me.bFightState and not me.bOnHorse and HM_Doodad.bInteract
			bKeep = true
		end
		if not bKeep then
			_HM_Doodad.Remove(k)
		end
		if bIntr then
			HM.Debug("auto interact [" .. d.szName .. "]")
			HM.BreatheCallDelayOnce("AutoDoodad", 500)
			return InteractDoodad(k)
		end
	end
end

-- open doodad (loot)
_HM_Doodad.OnOpenDoodad = function(dwID)
	_HM_Doodad.Remove(dwID)	-- 从列表删除
	local d = GetDoodad(dwID)
	if d then
		local bP, bClear, me = false, true, GetClientPlayer()
		-- 如需庖丁，则不要过滤灰色
		if HM_Doodad.bInteract and HM_Doodad.bCustom
			and HM_Doodad.tCustom[d.szName] and GetDoodadTemplate(d.dwTemplateID).dwCraftID == 3
		then
			_HM_Doodad.tDoodad[dwID] = { craft = true }
			_HM_Doodad.bUpdateLabel = true
			bP = true
		end
		-- money
		local nM = d.GetLootMoney() or 0
		if nM > 0 then
			LootMoney(d.dwID)
		end
		-- items
		for i = 0, 31 do
			local it, bRoll, bDist = d.GetLootItem(i, me)
			if it then
				-- 如有待分配物品，则取消庖丁并且不清空列表
				if bDist and bClear then
					bClear = false
					if bP then
						_HM_Doodad.Remove(dwID)
						bP = false
					end
				end
				local bLoot, szName = true, GetItemNameByItem(it)
				if bP then
					bLoot = true
				elseif HM_Doodad.bLootOnly then
					bLoot = HM_Doodad.tLootOnly[szName] == true
				elseif (it.nQuality == 0 and not HM_Doodad.bLootGray)
					or (it.nQuality == 1 and not HM_Doodad.bLootWhite)
					or (it.nQuality == 2 and not HM_Doodad.bLootGreen)
					or HM_Doodad.tLootFilter[szName] == true
				then
					bLoot = false
				end
				if bLoot then
					LootItem(d.dwID, it.dwID)
					HM.Debug("auto loot [" .. szName .. "]")
				else
					HM.Debug("filter loot [" .. szName .. "]")
				end
			end
		end
		if bClear then
			local hL = Station.Lookup("Normal/LootList", "Handle_LootList")
			if hL then
				hL:Clear()
			end
		end
	end
end

-- save manual doodad
_HM_Doodad.OnLootDoodad = function()
	if not HM_Doodad.bCustom then
		return
	end
	local d = GetDoodad(arg0)
	if not d or d.CanLoot(GetClientPlayer().dwID) then
		return
	end
	local t = GetDoodadTemplate(d.dwTemplateID)
	if t.dwCraftID >= 1 and t.dwCraftID <= 3 then
		HM_Doodad.tCustom[d.szName] = true
	end
end

-- mini flag
_HM_Doodad.OnUpdateMiniFlag = function()
	if not HM_Doodad.bMiniFlag then return end
	local me = GetClientPlayer()
	if not me then return end
	for k, v in pairs(_HM_Doodad.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(me.dwID)) then
				_HM_Doodad.Remove(k)
			else
				local dwType, nF1, nF2 = 5, 169, 48
				local tpl = GetDoodadTemplate(tar.dwTemplateID)
				if v.quest then
					nF1 = 114
				elseif tpl.dwCraftID == 1 then	-- 采金类
					nF1, nF2 = 16, 47
				elseif tpl.dwCraftID == 2 then	-- 神农类
					nF1 = 2
				end
				HM.UpdateMiniFlag(dwType, tar, nF1, nF2)
			end
		end
	end
end

-------------------------------------
-- 头顶名称绘制
-------------------------------------
function HM_Doodad.OnFrameCreate()
	-- label shadow
	_HM_Doodad.pLabel = this:Lookup("", "Shadow_Label")
	_HM_Doodad.bUpdateLabel = true
	-- events
end

function HM_Doodad.OnFrameBreathe()
	if _HM_Doodad.bUpdateLabel then
		_HM_Doodad.bUpdateLabel = false
		_HM_Doodad.OnUpdateHeadName()
	end
end

function HM_Doodad.OnEvent(event)
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Doodad.PS = {}

-- init
_HM_Doodad.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame)
	-- loot
	ui:Append("Text", { txt = _L["Pickup items"], x = 0, y = 0, font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["Enable auto pickup"], x = 10, y = 28, checked = HM_Doodad.bLoot })
	:Click(function(bChecked)
		HM_Doodad.bLoot = bChecked
		ui:Fetch("Check_Fight"):Enable(bChecked)
		ui:Fetch("Combo_Filter"):Enable(bChecked)
		_HM_Doodad.Reload()
	end):Pos_()
	local nX1 = nX
	nX = ui:Append("WndCheckBox", "Check_Fight", { txt = _L["Pickup in fight"], x = nX1 + 40, y = 28, checked = HM_Doodad.bLootFight, enable = HM_Doodad.bLoot })
	:Click(function(bChecked)
		HM_Doodad.bLootFight = bChecked
	end):Pos_()
	local nX2 = nX
	ui:Append("WndComboBox", "Combo_Filter", { txt = _L["Set pickup filter"], x = nX2 + 20, y = 28, enable = HM_Doodad.bLoot }):Menu(_HM_Doodad.GetFilterMenu)
	-- doodad
	ui:Append("Text", { txt = _L["Craft assit"], x = 0, y = 64, font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["Show the head name"], x = 10, y = 92, checked = HM_Doodad.bShowName })
	:Click(_HM_Doodad.SwitchName):Pos_()
	ui:Append("Shadow", "Shadow_Color", { x = nX + 2, y = 96, w = 18, h = 18 })
	:Color(unpack(HM_Doodad.tNameColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Shadow_Color"):Color(r, g, b)
			HM_Doodad.tNameColor = { r, g, b }
			_HM_Doodad.Reload()
		end)
	end):Pos_()
	nX = ui:Append("WndCheckBox", { txt = _L["Display minimap flag"], x = nX1 + 40, y = 92, checked = HM_Doodad.bMiniFlag })
	:Click(function(bChecked)
		HM_Doodad.bMiniFlag = bChecked
	end):Pos_()
	nX = ui:Append("WndCheckBox", { txt = _L["Quest items"], x = nX2 + 20, y = 92, checked = HM_Doodad.bQuest })
	:Click(function(bChecked)
		HM_Doodad.bQuest = bChecked
		_HM_Doodad.Reload()
	end):Pos_()
	nX = ui:Append("WndCheckBox", { txt = _L["All other"], x = nX + 10, y = 92, checked = HM_Doodad.bShowAll2 })
	:Click(function(bChecked)
		HM_Doodad.bShowAll2 = bChecked
		_HM_Doodad.Reload()
	end):Pos_()
	-- craft
	nX = 10
	local nY = 124
	for _, v in ipairs(_HM_Doodad.tCraft) do
		if v == 0 then
			nY = nY + 8
			if nX ~= 10 then
				nY = nY + 24
				nX = 10
			end
		else
			local k = _d(v)
			ui:Append("WndCheckBox", { txt = k, x = nX, y = nY, checked = HM_Doodad.tCraft[k] ~= nil })
			:Click(function(bChecked)
				if bChecked then
					HM_Doodad.tCraft[k] = true
				else
					HM_Doodad.tCraft[k] = nil
				end
				_HM_Doodad.Reload()
			end)
			nX = nX + 90
			if nX > 500 then
				nX = 10
				nY = nY + 24
			end
		end
	end
	-- custom
	nY = nY + 8
	if nX ~= 10 then
		nY = nY + 28
	end
	nX = ui:Append("WndCheckBox", { txt = _L["Customs (split by | )"], x = 10, y = nY, checked = HM_Doodad.bCustom })
	:Click(function(bChecked)
		HM_Doodad.bCustom = bChecked
		ui:Fetch("Edit_Custom"):Enable(bChecked)
		_HM_Doodad.Reload()
	end):Pos_()
	ui:Append("WndEdit", "Edit_Custom", { x = nX + 5, y = nY, limit = 1024, h = 27, w = 280 })
	:Text(_HM_Doodad.GetCustomText()):Enable(HM_Doodad.bCustom)
	:Change(function(szText)
		local t = {}
		szText = StringReplaceW(szText, _L[" | "], "|")
		for _, v in ipairs(HM.Split(szText, "|")) do
			v = HM.Trim(v)
			if v ~= "" then
				t[v] = true
			end
		end
		HM_Doodad.tCustom = t
		_HM_Doodad.Reload()
	end)
	ui:Append("Text", { txt = _L["Tip: Enter the name of dead animals can be automatically Paoding!"], x = 10, y = nY + 28 })
end

_HM_Doodad.PS.OnConflictCheck  = function()
	if IsEmpty(HM_Doodad.tCustom) then
		-- 粮草堆，散落的镖银，阵营首领战利品
		for _, v in ipairs({ 3996, 3874, 4255, 4315 }) do
			HM_Doodad.tCustom[_d(v)] = true
		end
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_ENTER_GAME", function() _HM_Doodad.SwitchName(HM_Doodad.bShowName) end)
HM.RegisterEvent("DOODAD_ENTER_SCENE", function() _HM_Doodad.TryAdd(arg0, true) end)
HM.RegisterEvent("DOODAD_LEAVE_SCENE", function() _HM_Doodad.Remove(arg0) end)
HM.RegisterEvent("OPEN_DOODAD", _HM_Doodad.OnLootDoodad)
HM.RegisterEvent("HELP_EVENT", function()
	if arg0 == "OnOpenpanel" and arg1 == "LOOT" and HM_Doodad.bLoot then
		local dwOpenID =  _HM_Doodad.GetOpenDoodadID()
		if dwOpenID then
			_HM_Doodad.OnOpenDoodad(dwOpenID)
		end
	end
end)
HM.RegisterEvent("QUEST_ACCEPTED", function()
	if HM_Doodad.bQuest then
		_HM_Doodad.Reload()
	end
end)
HM.BreatheCall("AutoDoodad", _HM_Doodad.OnAutoDoodad)
HM.BreatheCall("UpdateMiniFlag", _HM_Doodad.OnUpdateMiniFlag, 500)

-- add to HM collector
HM.RegisterPanel(_L["Doodad helper"], 90, _L["Others"], _HM_Doodad.PS)
HM_Doodad.OnAutoDoodad = _HM_Doodad.OnAutoDoodad
