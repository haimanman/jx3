--
-- 海鳗插件：实用小工具
--

local _i = Table_GetItemName
HM_ToolBox = {
	bAutoRepair = true,	-- 打开 NPC 后自动修理
	bSellGray = true,		-- 打开 NPC 后自动卖掉灰色物品
	bSellWhiteBook = true,	-- 自动出售已读白书
	bSellGreenBook = false,	-- 自动出售已读绿书
	bSellBlueBook = false,	-- 自动出售已读蓝书
	tSellItem = {
		[_i(3098)--[[银叶子]]] = true,
		[_i(7954)--[[真银叶子]]] = true,
		[_i(7955)--[[大片真银叶子]]] = true,
		[_i(7956)--[[金粉末]]] = true,
		[_i(7957)--[[金叶子]]] = true,
		[_i(7958)--[[大片金叶子]]] = true,
		[_i(69697)--[[金条]]] = true,
		[_i(69698)--[[金块]]] = true,
		[_i(69699)--[[金砖]]] = true,
		[_i(70471)--[[银叶子·试练之地]]] = true,
	},
	bBuyMore = true,		-- 买得更多
	-- 自动确认
	bIgnoreSell = true,		-- 卖蓝色装备免确认
	--bIgnoreRaid = false,	-- 自动团队确认
	bIgnoreTrade = false,	-- 自动交易确认 TradingInvite
	bIgnoreHorse = false,	-- 自动双骑确认  OnInviteFollow
	bQuestItem = true,		-- 自动采集任务物品
	bCustomDoodad = false,	-- 自动采集指定物品
	bShiftAuction = true,	-- 按 shift 一键寄卖
	bAutoStack = true,	-- 一键堆叠（背包+仓库）
	bAutoDiamond = true,	-- 五行石精炼完成后自动再摆上次材料
	bAnyDiamond = false,	-- 忽略五行石颜色，只考虑等级
	szCustomDoodad = _L["HuiZhenYan"],
	nBroadType = 0,
	szBroadText = "Hi",
}
HM.RegisterCustomData("HM_ToolBox")

-- 暂不记录的选项
HM_ToolBox.bIgnoreRaid = false

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_ToolBox = {
	nRaidID = 0,
	tDoodad = {},	-- 待处理的 doodad 列表
}

-- 获取自动售卖设置菜单
_HM_ToolBox.GetSellMenu = function()
	local m0 = {
		{ szOption = _L["Sell grey items"], bCheck = true, bChecked = HM_ToolBox.bSellGray,
			fnAction = function(d, b) HM_ToolBox.bSellGray = b end,
		}, { szOption = _L["Sell white books"], bCheck = true, bChecked = HM_ToolBox.bSellWhiteBook,
			fnAction = function(d, b) HM_ToolBox.bSellWhiteBook = b end,
			fnDisable = function() return not HM_ToolBox.bSellGray end
		}, { szOption = _L["Sell green books"], bCheck = true, bChecked = HM_ToolBox.bSellGreenBook,
			fnAction = function(d, b) HM_ToolBox.bSellWhiteBook = b end,
			fnDisable = function() return not HM_ToolBox.bSellGray end
		}, { szOption = _L["Sell blue books"], bCheck = true, bChecked = HM_ToolBox.bSellBlueBook,
			fnAction = function(d, b) HM_ToolBox.bSellBlueBook = b end,
			fnDisable = function() return not HM_ToolBox.bSellGray end
		}, {
			bDevide = true,
		},
	}
	local m1 = { szOption = _L["Sell specified items"], fnDisable = function() return not HM_ToolBox.bSellGray end,
		{ szOption = _L["* New *"],
			fnAction = function()
				GetUserInput(_L["Name of item"], function(szText)
					local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
					if szText ~= "" then
						HM_ToolBox.tSellItem[szText] = true
					end
				end)
			end
		}, {
			bDevide = true,
		},
	}
	for k, v in pairs(HM_ToolBox.tSellItem) do
		table.insert(m1, {
			szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) HM_ToolBox.tSellItem[k] = b end,
			{ szOption = _L["Remove"], fnAction = function() HM_ToolBox.tSellItem[k] = nil end }
		})
	end
	table.insert(m0, m1)
	return m0
end

-- 自动卖灰色等物品
_HM_ToolBox.SellGrayItem = function(nNpcID, nShopID)
	local me = GetClientPlayer()
	for dwBox = 1, BigBagPanel_nCount do
		local dwSize = me.GetBoxSize(dwBox) - 1
		for dwX = 0, dwSize do
			local item = me.GetItem(dwBox, dwX)
			if item and item.bCanTrade then
				local bSell = item.nQuality == 0
				local szName = GetItemNameByItem(item)
				if not bSell and item.nGenre == ITEM_GENRE.BOOK
					and me.IsBookMemorized(GlobelRecipeID2BookID(item.nBookID))
				then
					if (HM_ToolBox.bSellWhiteBook and item.nQuality == 1)
						or (HM_ToolBox.bSellGreenBook and item.nQuality == 2)
						or (HM_ToolBox.bSellBlueBook and item.nQuality == 3)
					then
						bSell = true
					end
				end
				if bSell or HM_ToolBox.tSellItem[szName] then
					local nCount = 1
					if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.ARROW then --远程武器
						nCount = item.nCurrentDurability
					elseif item.bCanStack then
						nCount = item.nStackNum
					end
					SellItem(nNpcID, nShopID, dwBox, dwX, nCount)
				end
			end
		end
	end
end

-- 检查有没有权限
_HM_ToolBox.HasBroadPerm = function()
	local tong, me = GetTongClient(), GetClientPlayer()
	if me and me.dwTongID ~= 0 and tong then
		local info = tong.GetMemberInfo(me.dwID)
		return tong.CheckBaseOperationGroup(info.nGroupID, 1)
	end
	return false
end

-- 群发团队密聊
_HM_ToolBox.SendBroadRaid = function()
	local team, me = GetClientTeam(), GetClientPlayer()
	if not team or not me or not me.IsInParty() then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		if dwID ~= me.dwID then
			local info = team.GetMemberInfo(dwID)
			if info and info.bIsOnLine and dwID ~= me.dwID then
				HM.Talk(info.szName, _L["[Party BC] "] .. HM_ToolBox.szBroadText)
			end
		end
	end
end

-- 群发广播
_HM_ToolBox.SendBroadCast = function()
	if HM_ToolBox.nBroadType == 3 then
		return _HM_ToolBox.SendBroadRaid()
	end
	local tong, me = GetTongClient(), GetClientPlayer()
	if not tong or not me or me.dwTongID == 0 then
		return
	end
	local dwMapID, szText, nType = me.GetScene().dwMapID, HM_ToolBox.szBroadText, HM_ToolBox.nBroadType
	local aPlayer = tong.GetMemberList(false, "name", false, -1, -1)
	for _, v in pairs(aPlayer) do
		local info = tong.GetMemberInfo(v)
		if nType == 0 or (nType == 1 and dwMapID ~= info.dwMapID) or (nType == 2 and dwMapID == info.dwMapID) then
			HM.Talk(info.szName, _L["[Guild BC] "] .. szText)
		end
	end
end

-- 一键上架交易行
_HM_ToolBox.GetAuctionPrice = function(h, g, s, c)
	local t = {}
    t.nGold = tonumber(h:Lookup(g):GetText()) or 0
    t.nSliver = tonumber(h:Lookup(s):GetText()) or 0
    t.nCopper = tonumber(h:Lookup(c):GetText()) or 0
	return t
end

-- 转换为单价
_HM_ToolBox.GetSinglePrice = function(t, nNum)
	local t2 = {}
	local nCopper = math.floor((t.nGold * 10000 + t.nSliver * 100 + t.nCopper)/nNum)
	t2.nGold = math.floor(nCopper / 10000)
	t2.nSliver = math.floor((nCopper % 10000) / 100)
	t2.nCopper = nCopper % 100
	return t2
end

_HM_ToolBox.IsSameItem = function(item, item2)
    if not item2 or not item2.bCanTrade then
        return false
    end
	if GetItemNameByItem(item) == GetItemNameByItem(item2) and item.nGenre == item2.nGenre then
		return true
	end
    if item.nGenre == ITEM_GENRE.BOOK and item2.nGenre == ITEM_GENRE.BOOK and item.nQuality == item2.nQuality then
        return true
    end
    return false
end

_HM_ToolBox.AuctionSell = function(frame)
	local wnd = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
    local box = wnd:Lookup("", "Box_Item")
    local szTime = wnd:Lookup("", "Text_Time"):GetText()
    local nTime = tonumber(string.sub(szTime, 1, 2))
	-- check item
    local me = GetClientPlayer()
    local item = me.GetItem(box.dwBox, box.dwX)
    if not item or item.szName ~= box.szName then
        AuctionPanel.ClearBox(box)
        AuctionPanel.UpdateSaleInfo(frame, true)
        return RemoveUILockItem("Auction")
    end
	-- count price
    box.tBidPrice = _HM_ToolBox.GetAuctionPrice(wnd, "Edit_OPGold", "Edit_OPSilver", "Edit_OPCopper")
    box.tBuyPrice = _HM_ToolBox.GetAuctionPrice(wnd, "Edit_PGold", "Edit_PSilver", "Edit_PCopper")
    box.szTime = szTime
	local nStackNum = item.nStackNum
    if not item.bCanStack then
        nStackNum = 1
    end
    local tSBidPrice = _HM_ToolBox.GetSinglePrice(box.tBidPrice, nStackNum)
    local tSBuyPrice = _HM_ToolBox.GetSinglePrice(box.tBuyPrice, nStackNum)
    local AtClient = GetAuctionClient()
    FireEvent("SELL_AUCTION_ITEM")
    for i = 1, BigBagPanel_nCount do
        if me.GetBoxSize(i) > 0 then
            for j = 0, me.GetBoxSize(i) - 1 do
                local item2 = me.GetItem(i, j)
                if _HM_ToolBox.IsSameItem(item, item2) then
                    local nNum = item2.nStackNum
                    if not item2.bCanStack then
                        nNum = 1
                    end
                    AtClient.Sell(AuctionPanel.dwTargetID, i, j,
						math.floor(tSBidPrice.nGold * nNum), math.floor(tSBidPrice.nSliver * nNum),
						math.floor(tSBidPrice.nCopper * nNum), math.floor(tSBuyPrice.nGold * nNum),
						math.floor(tSBuyPrice.nSliver * nNum), math.floor(tSBuyPrice.nCopper * nNum), nTime)
                end
            end
        end
    end
    PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

-- 替换上架函数
_HM_ToolBox.AuctionPanel_AuctionSell = AuctionPanel.AuctionSell
AuctionPanel.AuctionSell = function(...)
	if IsShiftKeyDown() and HM_ToolBox.bShiftAuction then
		_HM_ToolBox.AuctionSell(...)
	else
		_HM_ToolBox.AuctionPanel_AuctionSell(...)
	end
end

-- 获取五行石数据
_HM_ToolBox.GetDiamondData = function(box)
	local d, item = {}, GetClientPlayer().GetItem(box.dwBox, box.dwX)
	d.dwBox, d.dwX = box.dwBox, box.dwX
	if item then
		d.type, d.level = string.match(item.szName, _L["DiamondRegex"])
		d.id, d.bind, d.num, d.detail = item.nUiId, item.bBind, item.nStackNum, item.nDetail
	end
	return d
end

-- 保存五行石精炼方案
_HM_ToolBox.SaveDiamondFormula = function()
	local t = {}
	local handle = Station.Lookup("Normal/FEProducePanel", "")
	local box, hL = handle:Lookup("Box_FE"), handle:Lookup("Handle_Item")
	table.insert(t, _HM_ToolBox.GetDiamondData(box))
	for i = 1, 16 do
		local box = hL:Lookup("Box_Item" .. i)
		if box.state == "main" then
			table.insert(t, _HM_ToolBox.GetDiamondData(box))
		end
	end
	_HM_ToolBox.dFormula = t
end

-- 扫描背包石头及空位信息（存在 buggy cache）
_HM_ToolBox.LoadBagDiamond = function()
	local me, t = GetClientPlayer(), {}
	for dwBox = 1, BigBagPanel_nCount do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local d = _HM_ToolBox.GetDiamondData({ dwBox = dwBox, dwX = dwX })
			if not d.id or d.type then
				for _, v in ipairs(_HM_ToolBox.dFormula) do
					if v.dwBox == dwBox and v.dwX == dwX then
						d = nil
					end
				end
				if d then
					table.insert(t, d)
				end
			end
		end
	end
	_HM_ToolBox.tBagCache = t
end

-- 还原背包格子里的石头，失败返回 false，成功返回 true
_HM_ToolBox.RestoreBagDiamond = function(d)
	local me = GetClientPlayer()
	local tBag = _HM_ToolBox.tBagCache
	-- move box item
	local item = me.GetItem(d.dwBox, d.dwX)
	-- to stack
	if item then
		for k, v in ipairs(tBag) do
			if v.id == item.nUiId and v.bind == item.bBind and (v.num + item.nStackNum) <= item.nMaxStackNum then
				v.num = v.num + item.nStackNum
				me.ExchangeItem(d.dwBox, d.dwX, v.dwBox, v.dwX)
				item = nil
				break
			end
		end
	end
	-- to empty
	if item then
		for k, v in ipairs(tBag) do
			if not v.id then
				local v2 = _HM_ToolBox.GetDiamondData(d)
				v2.dwBox, v2.dwX = v.dwBox, v.dwX
				tBag[k] = v2
				me.ExchangeItem(d.dwBox, d.dwX, v.dwBox, v.dwX)
				item = nil
				break
			end
		end
	end
	-- no freebox
	if item then
		return false
	end
	-- group bag by type/bind: same type, same bind, ... others
	local tBag2, nLeft = {}, d.num
	for _, v in ipairs(tBag) do
		if v.level == d.level
			and (HM_ToolBox.bAnyDiamond or (v.type == d.type and (v.bind == d.bind or v.bind == false)))
		then
			local vt = nil
			for _, vv in ipairs(tBag2) do
				if vv.type == v.type and vv.bind == v.bind then
					vt = vv
					break
				end
			end
			if not vt then
				vt = { num = 0, type = v.type, bind = v.bind }
				local vk = #tBag2 + 1
				if vk > 1 and v.type == d.type then
					if v.bind ~= d.bind and tBag2[1].type == d.type then
						vk = 2
					else
						vk = 1
					end
				end
				table.insert(tBag2, vk, vt)
			end
			vt.num = vt.num + v.num
			table.insert(vt, v)
		end
	end
	-- select diamond1 (same type)
	for _, v in ipairs(tBag2) do
		if v.num >= nLeft then
			for _, vv in ipairs(v) do
				if vv.num >= nLeft then
					me.ExchangeItem(vv.dwBox, vv.dwX, d.dwBox, d.dwX, nLeft)
					vv.num = vv.num - nLeft
					break
				elseif vv.num > 0 then
					me.ExchangeItem(vv.dwBox, vv.dwX, d.dwBox, d.dwX, vv.num)
					nLeft = nLeft - vv.num
					vv.num = 0
				end
			end
			return true
		end
	end
	return false
end

-- 堆叠一个 box
_HM_ToolBox.DoBoxStack = function(i, tList)
	local me = GetClientPlayer()
	for j = 0, me.GetBoxSize(i) - 1 do
		local item = me.GetItem(i, j)
		if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
			local szKey = tostring(item.nUiId) .. tostring(item.bBind)
			local t = tList[szKey]
			if not t then
				tList[szKey] = { nLeft = item.nMaxStackNum - item.nStackNum, dwBox = i, dwX = j }
			elseif item.nStackNum <= t.nLeft then
				me.ExchangeItem(i, j, t.dwBox, t.dwX, item.nStackNum)
				if t.nLeft == item.nStackNum then
					tList[szKey] = nil
				else
					t.nLeft = t.nLeft - item.nStackNum
				end
			else
				local nLeft = item.nStackNum - t.nLeft
				me.ExchangeItem(i, j, t.dwBox, t.dwX, t.nLeft)
				t.nLeft, t.dwBox, t.dwX = nLeft, i, j
			end
		end
	end
end

-- 背包堆叠
_HM_ToolBox.DoBagStack = function()
	if IsBagInSort() then
		return
	end
	local tList = {}
	for i = 1, BigBagPanel_nCount do
		_HM_ToolBox.DoBoxStack(INVENTORY_INDEX.PACKAGE + i - 1, tList)
	end
end

-- 仓库堆叠
_HM_ToolBox.DoBankStack = function()
	if IsBankInSort() then
		return
	end
	local tList = {}
	for i = 1, 6 do
		_HM_ToolBox.DoBoxStack(INVENTORY_INDEX.BANK + i - 1, tList)
	end
end

-- 检测增加堆叠按纽
_HM_ToolBox.BindStackButton = function()
	-- bag
	local btn1 = Station.Lookup("Normal/BigBagPanel/Btn_Split")
	local btn2 = Station.Lookup("Normal/BigBagPanel/Btn_Stack")
	if not HM_ToolBox.bAutoStack then
		if btn2 then
			btn2:Destroy()
			btn1.nX, btn1.nY = nil, nil
		end
	elseif btn1 then
		local nX, nY = btn1:GetRelPos()
		if nX ~= btn1.nX or nY ~= btn1.nY then
			btn1.nX, btn1.nY = nX, nY
			if not btn2 then
				local w, h = btn1:GetSize()
				btn2 = HM.UI("Normal/BigBagPanel"):Append("WndButton", "Btn_Stack", { txt = _L["Stack"], w = w, h = h }):Raw()
				btn2.OnLButtonClick = _HM_ToolBox.DoBagStack
			end
			btn2:SetRelPos(nX + btn1:GetSize(), nY)
		end
	end
	-- bank
	local btn1 = Station.Lookup("Normal/BigBankPanel/Btn_CU")
	local btn2 = Station.Lookup("Normal/BigBankPanel/Btn_Stack")
	if not HM_ToolBox.bAutoStack then
		if btn2 then
			btn2:Destroy()
			btn1.nX, btn1.nY = nil, nil
		end
	elseif btn1 then
		local nX, nY = btn1:GetRelPos()
		if nX ~= btn1.nX or nY ~= btn1.nY then
			btn1.nX, btn1.nY = nX, nY
			if not btn2 then
				local w, h = btn1:GetSize()
				btn2 = HM.UI("Normal/BigBankPanel"):Append("WndButton", "Btn_Stack", { txt = _L["Stack"], w = w, h = h }):Raw()
				btn2.OnLButtonClick = _HM_ToolBox.DoBankStack
			end
			btn2:SetRelPos(nX + btn1:GetSize(), nY)
		end
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
_HM_ToolBox.OnOpenShop = function()
	local nNpcID, nShopID = arg4, arg0
	if arg3 and HM_ToolBox.bAutoRepair then
		if GetRepairAllItemsPrice(nNpcID, nShopID) > 0 then
			RepairAllItems(nNpcID, nShopID)
		end
	end
	if HM_ToolBox.bSellGray then
		_HM_ToolBox.SellGrayItem(nNpcID, nShopID)
	end
	_HM_ToolBox.nShopNpcID = nNpcID
end

_HM_ToolBox.OnShopUpdateItem = function()
	if not HM_ToolBox.bBuyMore then
		return
	end
	-- 由于 ShopPanel 的事件后注册，因此需要延迟一帧调用
	local nShopID, dwPage, dwPos = arg0, arg1, arg2
	HM.DelayCall(50, function()
		local box = Station.Lookup("Normal/ShopPanel/PageSet_Main/Page_Sale", "Handle_Sale"):Lookup(dwPos):Lookup("Box_Item")
		box.OnItemRButtonClick = function()
			if not this:IsObjectEnable() then
				return
			end
			local item = GetItem(GetShopItemID(nShopID, dwPage, dwPos))
			if IsShiftKeyDown() and item.nMaxDurability > 1
				and (item.nGenre ~= ITEM_GENRE.EQUIPMENT or item.nSub == EQUIPMENT_SUB.ARROW)
			then
				local nMax = item.nMaxDurability
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				local fnSure = function(nNum)
					while nNum > 0 do
						if nNum < nMax then
							nMax = nNum
						end
						BuyItem(_HM_ToolBox.nShopNpcID, nShopID, dwPage, dwPos, nMax)
						nNum = nNum - nMax
					end
				end
				GetUserInputNumber(nMax, 10000, { x, y, x + w, y + h }, fnSure)
			else
				local nCount = 1
				if this.bGroup then
					nCount = item.nCurrentDurability
				end
				BuyItem(_HM_ToolBox.nShopNpcID, nShopID, dwPage, dwPos, nCount)
			end
		end
	end)
end

_HM_ToolBox.OnAutoConfirm = function()
	if HM_ToolBox.bIgnoreSell then
		HM.DoMessageBox("SellItemSure")
	end
	if HM_ToolBox.bIgnoreRaid then
		HM.DoMessageBox("ReadyConfirm" .. _HM_ToolBox.nRaidID)
	end
	if HM_ToolBox.bIgnoreTrade then
		HM.DoMessageBox("TradingInvite")
	end
	if HM_ToolBox.bIgnoreHorse then
		HM.DoMessageBox("OnInviteFollow")
	end
	if HM_ToolBox.bAutoDiamond then
		local szName = "ProduceDiamondSure"
		local frame = Station.Lookup("Topmost2/MB_" .. szName) or Station.Lookup("Topmost/MB_" .. szName)
		if frame then
			_HM_ToolBox.ProduceDiamond = frame:Lookup("Wnd_All/Btn_Option1").fnAction
			_HM_ToolBox.SaveDiamondFormula()
		end
		HM.DoMessageBox(szName)
	end
	_HM_ToolBox.BindStackButton()
end

_HM_ToolBox.ReloadDoodad = function()
	local t = {}
	for k, _ in pairs(HM.GetAllDoodadID()) do
		t[k] = 0
	end
	_HM_ToolBox.tDoodad = t
end

_HM_ToolBox.OnAutoDoodad = function()
	local me = GetClientPlayer()
	if not me or me.bFightState or me.GetOTActionState() ~= 0 or me.bOnHorse
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
	then
		return
	end
	for k, v in pairs(_HM_ToolBox.tDoodad) do
		local d, bKeep, bInteract = GetDoodad(k), false, false
		--if d and d.nKind ~= DOODAD_KIND.CORPSE and d.nKind ~= DOODAD_KIND.NPCDROP then
		if d and d.nKind ~= DOODAD_KIND.NPCDROP then
			if (HM_ToolBox.bQuestItem and d.HaveQuest(me.dwID))
				or (HM_ToolBox.bCustomDoodad and StringFindW("|" .. HM_ToolBox.szCustomDoodad .. "|", "|" .. d.szName .. "|"))
			then
				bKeep = v < 4
				if d.CanDialog(me) then
					_HM_ToolBox.tDoodad[k] = v + 1
					bInteract = true
				end
			end
		end
		if not bKeep then
			_HM_ToolBox.tDoodad[k] = nil
		end
		if bInteract then
			return InteractDoodad(k)
		end
	end
end

-- 自动摆五行石材料
_HM_ToolBox.OnDiamondUpdate = function()
	if not HM_ToolBox.bAutoDiamond or not _HM_ToolBox.dFormula or arg0 ~= 1 then
		return
	end
	local box = Station.Lookup("Normal/FEProducePanel", "Box_FE")
	if not box then
		_HM_ToolBox.dFormula = nil
		return
	end
	-- 移除加锁（延迟一帧）
	HM.DelayCall(50, function()
		RemoveUILockItem("FEProduce")
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
		box:SetObjectIcon(3386)
	end)
	-- 重新放入配方（延迟8帧执行，确保 unlock）
	HM.DelayCall(500, function()
		_HM_ToolBox.LoadBagDiamond()
		for _, v in ipairs(_HM_ToolBox.dFormula) do
			if not _HM_ToolBox.RestoreBagDiamond(v) then
				box:ClearObject()
				_HM_ToolBox.dFormula = nil
				_HM_ToolBox.tBagCache = nil
				return
			end
		end
		box.nDetail = _HM_ToolBox.dFormula[1].detail
		_HM_ToolBox.ProduceDiamond()
	end)
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_ToolBox.PS = {}

-- init
_HM_ToolBox.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { txt = _L["Shop NPC"], x = 0, y = 0, font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["When shop open repair equipments"], x = 10, y = 28, checked = HM_ToolBox.bAutoRepair })
	:Click(function(bChecked)
		HM_ToolBox.bAutoRepair = bChecked
	end):Pos_()
	ui:Append("WndComboBox", { txt = _L["Sell some items"], x = nX + 10, y = 28 }):Menu(_HM_ToolBox.GetSellMenu)
	ui:Append("WndCheckBox", { txt = _L["Enable to buy more numbers of item at a time"], x = 10, y = 56, checked = HM_ToolBox.bBuyMore })
	:Click(function(bChecked)
		HM_ToolBox.bBuyMore = bChecked
	end)
	-- auto confirm
	ui:Append("Text", { txt = _L["Auto feature"], x = 0, y = 92, font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["Auto confirm for selling blue level item"], x = 10, y = 120, checked = HM_ToolBox.bIgnoreSell })
	:Click(function(bChecked)
		HM_ToolBox.bIgnoreSell = bChecked
	end):Pos_()
	--ui:Append("WndCheckBox", { txt = _L["Auto confirm for team ready"], x = nX + 10, y = 120, checked = HM_ToolBox.bIgnoreRaid })
	--:Enable(false):Click(function(bChecked)
	--	HM_ToolBox.bIgnoreRaid = bChecked
	--end)
	ui:Append("WndCheckBox", { txt = _L["Enable stack items by button"], x = nX + 10, y = 120, checked = HM_ToolBox.bAutoStack })
	:Click(function(bChecked)
		HM_ToolBox.bAutoStack = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Auto confirm for trade request"], x = 10, y = 148, checked = HM_ToolBox.bIgnoreTrade })
	:Click(function(bChecked)
		HM_ToolBox.bIgnoreTrade = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Auto confirm for ridding horse"], x = nX + 10, y = 148, checked = HM_ToolBox.bIgnoreHorse })
	:Click(function(bChecked)
		HM_ToolBox.bIgnoreHorse = bChecked
	end)
	-- auto doodad
	ui:Append("WndCheckBox", { txt = _L["Auto interact quest doodad"], x = 10, y = 176, checked = HM_ToolBox.bQuestItem })
	:Click(function(bChecked)
		HM_ToolBox.bQuestItem = bChecked
		if bChecked then
			_HM_ToolBox.ReloadDoodad()
		end
	end)
	-- shift-auction
	ui:Append("WndCheckBox", { txt = _L["Press SHIFT fast auction sell"], x = nX + 10, y = 176, checked = HM_ToolBox.bShiftAuction })
	:Click(function(bChecked)
		HM_ToolBox.bShiftAuction = bChecked
	end)
	-- put diamond
	ui:Append("WndCheckBox", { txt = _L["Produce diamond as last formula"], x = 10, y = 204, checked = HM_ToolBox.bAutoDiamond, font = 57 })
	:Click(function(bChecked)
		HM_ToolBox.bAutoDiamond = bChecked
		_HM_ToolBox.dFormula = nil
		ui:Fetch("Check_Any"):Enable(bChecked)
	end)
	ui:Append("WndCheckBox", "Check_Any", { txt = _L["Only consider diamond level"], x = nX + 10, y = 204, checked = HM_ToolBox.bAnyDiamond, enable = HM_ToolBox.bAutoDiamond })
	:Click(function(bChecked)
		HM_ToolBox.bAnyDiamond = bChecked
	end)
	-- specified doodad
	nX = ui:Append("WndCheckBox", { txt = _L["Auto interact specified doodad"], x = 10, y = 232, checked = HM_ToolBox.bCustomDoodad })
	:Click(function(bChecked)
		HM_ToolBox.bCustomDoodad = bChecked
		ui:Fetch("Edit_Doodad"):Enable(bChecked)
		if bChecked then
			_HM_ToolBox.ReloadDoodad()
		end
	end):Pos_()
	ui:Append("WndEdit", "Edit_Doodad", { x = nX + 10, y = 232, limit = 1024, h = 27, w = 260 })
	:Text(HM_ToolBox.szCustomDoodad):Enable(HM_ToolBox.bCustomDoodad)
	:Change(function(szText)
		HM_ToolBox.szCustomDoodad = szText
		_HM_ToolBox.ReloadDoodad()
	end)
	-- tong broadcast
	ui:Append("Text", { txt = _L["Group whisper oline (Guild perm required)"], x = 0, y = 268, font = 27 })
	ui:Append("WndEdit", "Edit_Msg", { x = 10, y = 296, limit = 1024, multi = true, h = 50, w = 480, txt = HM_ToolBox.szBroadText })
	:Change(function(szText) HM_ToolBox.szBroadText = szText end)
	local nX = ui:Append("WndRadioBox", { txt = _L["Online"], checked = HM_ToolBox.nBroadType == 0, group = "Broad" })
	:Pos(10, 352):Click(function(b) if b then HM_ToolBox.nBroadType = 0  end end):Pos_()
	nX = ui:Append("WndRadioBox", { txt = _L["Other map"], checked = HM_ToolBox.nBroadType == 1, group = "Broad" })
	:Pos(10 + nX, 352):Click(function(b) if b then HM_ToolBox.nBroadType = 1  end end):Pos_()
	nX = ui:Append("WndRadioBox", { txt = _L["Current map"], checked = HM_ToolBox.nBroadType == 2, group = "Broad" })
	:Pos(10 + nX, 352):Click(function(b) if b then HM_ToolBox.nBroadType = 2 end end):Pos_()
	nX = ui:Append("WndRadioBox", { txt = _L["Team"], checked = HM_ToolBox.nBroadType == 3, group = "Broad" })
	:Pos(10 + nX, 352):Click(function(b) if b then HM_ToolBox.nBroadType = 3 end end):Pos_()
	ui:Append("WndButton", { txt = _L["Submit"], x = nX + 10, y = 353 })
	:Enable(_HM_ToolBox.HasBroadPerm()):Click(_HM_ToolBox.SendBroadCast)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("RIAD_READY_CONFIRM_RECEIVE_QUESTION", function()
	_HM_ToolBox.nRaidID = arg0
end)
HM.RegisterEvent("DIAMON_UPDATE", _HM_ToolBox.OnDiamondUpdate)
HM.RegisterEvent("SHOP_OPENSHOP", _HM_ToolBox.OnOpenShop)
HM.RegisterEvent("SHOP_UPDATEITEM", _HM_ToolBox.OnShopUpdateItem)
HM.RegisterEvent("DOODAD_ENTER_SCENE", function() _HM_ToolBox.tDoodad[arg0] = 0 end)
HM.RegisterEvent("DOODAD_LEAVE_SCENE", function() _HM_ToolBox.tDoodad[arg0] = nil end)
HM.RegisterEvent("QUEST_ACCEPTED", function()
	if HM_ToolBox.bQuestItem then
		_HM_ToolBox.ReloadDoodad()
	end
end)
HM.BreatheCall("AutoConfirm", _HM_ToolBox.OnAutoConfirm, 130)
HM.BreatheCall("AutoDoodad", _HM_ToolBox.OnAutoDoodad)

-- add to HM collector
HM.RegisterPanel(_L["Misc toolbox"], 352, _L["Others"], _HM_ToolBox.PS)
