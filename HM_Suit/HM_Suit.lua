-- 海鳗单体：套装更换增强
-- 可以在第1和第2套装之间共用部分装备（默认共用武器，橙武哥、橙武姐双修必备啊）
-- 用法：左键点击玩家头像右边的按纽可正常换装、脱装，右键点击可设置共用的装备列表
--

HM_Suit = {
	tShare = { [0] = true, },		-- 1、2套装共用部位
	tUnmount = {						-- 脱掉装备包含的部位
		[0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
		[8] = true, [10] = true,  [11] = true, [12] = true,
	},
	bShowChange = true,
	bShowUmount = true,
}
HM.RegisterCustomData("HM_Suit")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Suit = {}

-- 装备位置及名称
_HM_Suit.tEquipType = {
	[0] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.MELEE_WEAPON],
	[1] = g_tStrings.WeapenDetail[WEAPON_DETAIL.BIG_SWORD],
	[2] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.RANGE_WEAPON],
	[3] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.CHEST],
	[4] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.HELM],
	[5] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.AMULET],
	[6] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.RING] .. "1",
	[7] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.RING] .. "2",
	[8] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.WAIST],
	[9] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.PENDANT],
	[10] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.PANTS],
	[11] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.BOOTS],
	[12] = g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.BANGLE],
}

-- 输出信息
_HM_Suit.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Suit"])
end

-- 获取共享菜单
_HM_Suit.GetShareMenu = function()
	local m0 = {}
	table.insert(m0, { szOption = _L["Shared equip for No.1/2 suit"], fnDisable = function() return true end, })
	table.insert(m0, { bDevide = true, })
	for i = 0, 12 do
		table.insert(m0, {
			szOption = _HM_Suit.tEquipType[i],
			bCheck = true, bChecked = HM_Suit.tShare[i] == true,
			fnAction = function(d, b) HM_Suit.tShare[i] = b end
		})
	end
	return m0
end

-- 获取脱掉装备清单
_HM_Suit.GetUnmountMenu = function()
	local m0 = {}
	table.insert(m0, { szOption = _L["Equipments to unmount: "], fnDisable = function() return true end, })
	table.insert(m0, { bDevide = true, })
	for i = 0, 12 do
		table.insert(m0, {
			szOption = _HM_Suit.tEquipType[i],
			bCheck = true, bChecked = HM_Suit.tUnmount[i] == true,
			fnAction = function(d, b) HM_Suit.tUnmount[i] = b end
		})
	end
	return m0
end

-- 取下身上的装备，返回背包列表
_HM_Suit.TakeToBag = function(tPos)
	local me, tEquip = GetClientPlayer(), {}
	for k, v in pairs(tPos) do
		if v == true and me.GetItem(INVENTORY_INDEX.EQUIP, k) ~= nil then
			table.insert(tEquip, k)
		end
	end
	local tBox = {}
	for i = 1, BigBagPanel_nCount do
		local nSize = me.GetBoxSize(i) or 0
		for j = 0, nSize - 1 do
			if not me.GetItem(i, j) then
				local k = table.remove(tEquip)
				if k then
					tBox[k] = { i, j }
					OnExchangeItem(INVENTORY_INDEX.EQUIP, k, i, j)
				end
				if #tEquip == 0 then
					return tBox
				end
			end
		end
	end
	return tBox
end

-- 循环换装处理
_HM_Suit.ChangeSuit = function()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nCur, nTo = me.GetEquipIDArray(0), 1
	if nCur == 0 or nCur == 1 then
		if nCur == 0 then
			nTo = 2
		end
		_HM_Suit.tBagShare = _HM_Suit.TakeToBag(HM_Suit.tShare)
	end
	PlayerChangeSuit(nTo)
	_HM_Suit.Sysmsg(_L["Swith to No."] .. nTo .. _L["suit"])
end

-- 循环脱装备、穿装备
_HM_Suit.UnmountEquip = function()
	local txt = Player_GetFrame():Lookup("Btn_Umount"):Lookup("", "Text_Umount")
	if _HM_Suit.tBagUmount then
		txt:SetText(_L["Off"])
		for k, v in pairs(_HM_Suit.tBagUmount) do
			OnExchangeItem(v[1], v[2], INVENTORY_INDEX.EQUIP, k)
		end
		_HM_Suit.tBagUmount = nil
		_HM_Suit.Sysmsg(_L["Take on equipments"])
	else
		txt:SetText(_L["On"])
		_HM_Suit.tBagUmount = _HM_Suit.TakeToBag(HM_Suit.tUnmount)
		_HM_Suit.Sysmsg(_L["Take off equipments"])
	end
end

-- 恢复装备切换数据（装备切换后）
_HM_Suit.OnEquipChange = function()
	if _HM_Suit.tBagShare then
		for k, v in pairs(_HM_Suit.tBagShare) do
			OnExchangeItem(v[1], v[2], INVENTORY_INDEX.EQUIP, k)
		end
		_HM_Suit.tBagShare = nil
	end
end

-- 按纽鼠标进入
_HM_Suit.OnMouseEnter = function(this)
	local nX, nY = this:GetAbsPos()
	local nW, nH = this:GetSize()
	local szName = this:GetName()
	if szName == "Btn_Change" then
		local szTip = GetFormatText(_L["<Switch 1/2 suit>"], 101) .. GetFormatText(_L["Right click can set shared equipments!"], 106)
		OutputTip(szTip, 400, {nX, nY, nW, nH})
	elseif szName == "Btn_Umount" then
		local szTip = GetFormatText(_L["<On/Off equipments>"], 101) .. GetFormatText(_L["Right click can set unmount equipments!"], 106)
		OutputTip(szTip, 400, {nX, nY, nW, nH})
	elseif szName == "Btn_Three" then
		local szTip = GetFormatText(_L["<Change to 3rd suit>"], 101)
		OutputTip(szTip, 400, {nX, nY, nW, nH})
	end
end

-- 按纽鼠标移出
_HM_Suit.OnMouseLeave = function(this)
	HideTip()
end

-- 按纽左键点击
_HM_Suit.OnLButtonClick = function(this)
	local szName = this:GetName()
	if szName == "Btn_Change" then
		_HM_Suit.ChangeSuit()
	elseif szName == "Btn_Umount" then
		_HM_Suit.UnmountEquip()
	elseif szName == "Btn_Three" then
		PlayerChangeSuit(3)
	end
end

-- 按纽右键点击
_HM_Suit.OnRButtonClick = function(this)
	local szName = this:GetName()
	if szName == "Btn_Change" then
		PopupMenu(_HM_Suit.GetShareMenu())
	elseif szName == "Btn_Umount" then
		PopupMenu(_HM_Suit.GetUnmountMenu())
	end
end

-- 按纽 HOOK (人物进入游戏后)
_HM_Suit.OnEnterGame = function()
	local frame = Player_GetFrame()
	if frame:Lookup("Btn_Change") then
		return
	end
	local nW, _ = frame:GetSize()
	local temp = Wnd.OpenWindow("interface\\HM\\HM_Suit\\HM_Suit.ini")
	for k, v in ipairs({"Btn_Three", "Btn_Change", "Btn_Umount"}) do
		local btn = temp:Lookup(v)
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(nW - 27 * k, 15)
		btn.OnMouseEnter = function() _HM_Suit.OnMouseEnter(btn) end
		btn.OnMouseLeave = function() _HM_Suit.OnMouseLeave(btn) end
		btn.OnLButtonClick = function() _HM_Suit.OnLButtonClick(btn) end
		if v ~= "Btn_Three" then
			btn.OnRButtonClick = function() _HM_Suit.OnRButtonClick(btn) end
			if not HM_Suit["bShow" .. string.sub(v, 5)] then
				btn:Hide()
			end
			if v == "Btn_Change" then
				btn:Lookup("", "Text_Change"):SetText(_L["Chg"])
			elseif v == "Btn_Umount" then
				btn:Lookup("", "Text_Umount"):SetText(_L["Off"])
			end
		elseif not HM_Suit.bShowChange then
			btn:Hide()
		end
	end
	Wnd.CloseWindow(temp)
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Suit.PS = {}

-- init panel
_HM_Suit.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	ui:Append("Text", { txt = _L["Switch 1/2 suit"], font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Show suit switch button in player panel"], x = 10, y = 28, checked = HM_Suit.bShowChange })
	:Click(function(bChecked)
		HM_Suit.bShowChange = bChecked
		if bChecked then
			Player_GetFrame():Lookup("Btn_Change"):Show()
			Player_GetFrame():Lookup("Btn_Three"):Show()
		else
			Player_GetFrame():Lookup("Btn_Change"):Hide()
			Player_GetFrame():Lookup("Btn_Three"):Hide()
		end
	end)
	ui:Append("WndComboBox", { txt = _L["Set shared equips"], x = 12, y = 56 }):Menu(_HM_Suit.GetShareMenu)
	-- unmount
	ui:Append("Text", { txt = _L["Quick unmount equipments"], x = 0, y = 92, font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Show suit unmount button in player panel"], x = 10, y = 120, checked = HM_Suit.bShowUmount })
	:Click(function(bChecked)
		HM_Suit.bShowUmount = bChecked
		if bChecked then
			Player_GetFrame():Lookup("Btn_Umount"):Show()
		else
			Player_GetFrame():Lookup("Btn_Umount"):Hide()
		end
	end)
	ui:Append("WndComboBox", { txt = _L["Set unmount equips"], x = 12, y = 148 }):Menu(_HM_Suit.GetUnmountMenu)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("EQUIP_CHANGE", _HM_Suit.OnEquipChange)
HM.RegisterEvent("PLAYER_ENTER_GAME", _HM_Suit.OnEnterGame)

-- add to HM panel
HM.RegisterPanel(_L["Suit helper"], 44, _L["Others"], _HM_Suit.PS)

-- hotkey
HM.AddHotKey("ChangeSuit", _L["Switch 1/2 suit"],  _HM_Suit.ChangeSuit)
HM.AddHotKey("UnmountEquip", _L["Tak on/off equip"],  _HM_Suit.UnmountEquip)
