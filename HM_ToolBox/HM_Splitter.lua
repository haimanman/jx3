--
-- 海鳗插件：实用小工具——背包物品分组拆分
--

HM_Splitter = {
	tAnchor = {},
}
HM.RegisterCustomData("HM_Splitter")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Splitter = {}

-- 执行分割
_HM_Splitter.DoSplit = function(frame)
	local nGroup = tonumber(frame:Lookup("Edit_Group"):GetText()) or 1
	local nNum = tonumber(frame:Lookup("Edit_Num"):GetText()) or 1
	local box = frame:Lookup("", "Box_Item")
	local me = GetClientPlayer()
	frame:Hide()
	if box.nStackNum <= nNum then
		return
	end
	for i = 1, BigBagPanel_nCount, 1 do
		if me.GetBoxFreeRoomSize(i) > 0 then
			for j = 0, me.GetBoxSize(i) - 1 do
				if not me.GetItem(i, j) then
					me.ExchangeItem(box.dwBox, box.dwX, i, j, nNum)
					box.nStackNum = box.nStackNum - nNum
					nGroup = nGroup - 1
					if box.nStackNum <= nNum or nGroup == 0 then
						return
					end
				end
			end
		end
	end
	OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_BAG_IS_FULL)
end

-- 显示分割界面
_HM_Splitter.ShowSplit = function(box)
	local frame = Station.Lookup("Normal/HM_Splitter")
	if not frame then
		return
	end
	local item = GetClientPlayer().GetItem(box.dwBox, box.dwX)
	if not item then
		return
	end
	local x, y = box:GetAbsPos()
	local w, h = box:GetSize()
	local box2 = frame:Lookup("", "Box_Item")
	box2:SetObject(box:GetObject())
	box2:SetObjectIcon(box:GetObjectIcon())
	box2:SetOverText(0, box:GetOverText(0))
	box2.dwBox, box2.dwX, box2.nStackNum = box.dwBox, box.dwX, item.nStackNum
	frame:CorrectPos(x, y, w, h, ALW.CENTER)
	frame:Show()
	frame:BringToTop()
	Station.SetFocusWindow(frame:Lookup("Edit_Num"))
end

-- 获得鼠标滑过的背包格子
_HM_Splitter.GetOverBagBox = function()
	local frame, me = Station.Lookup("Normal/BigBagPanel"), GetClientPlayer()
	if not frame or not frame:IsVisible() or not me then
		return nil
	end
	local tHandle = {}
	local hList = frame:Lookup("", "Handle_Bag_Compact")
	if not hList or not hList:IsVisible() then
		for i = 1, BigBagPanel_nCount do
			local hBag = frame:Lookup("", "Handle_Bag_Normal/Handle_Bag" .. i)
			if hBag and hBag:IsVisible() then
				table.insert(tHandle, hBag:Lookup("Handle_Bag_Content" .. i))
			end
		end
	else
		table.insert(tHandle, hList)
	end
	for _, h in ipairs(tHandle) do
		for i = 1, h:GetItemCount(), 1 do
			local box = h:Lookup(i - 1):Lookup(1)
			if box:IsObjectMouseOver() then
				if box:IsEmpty() then
					return nil
				end
				local item = me.GetItem(box.dwBox, box.dwX)
				if not item or not item.bCanStack or item.nStackNum < 2 then
					return nil
				end
				return box
			end
		end
	end
end

-- 背包格子鼠标点击
_HM_Splitter.OnBagBoxLButtonClick = function()
	Cursor.Switch(CURSOR.NORMAL)
	_HM_Splitter.ShowSplit(this)
end

-- 背包格子鼠标移出
_HM_Splitter.OnBagBoxMouseLeave = function(box)
	box  = box or this
	HideTip()
	box.bSplitHooked = nil
	box:SetObjectMouseOver(0)
	box.OnItemLButtonClick = box._OnItemLButtonClick
	box.OnItemMouseLeave = box._OnItemMouseLeave
	box.OnItemLButtonDrag = box._OnItemLButtonDrag
	if UserSelect.IsSelectItem() then
		UserSelect.SatisfySelectItem(-1, -1, true)
		return
	end
	if Cursor.GetCurrentIndex() == CURSOR.UNABLESPLIT then
		Cursor.Switch(CURSOR.SPLIT)
	elseif Cursor.GetCurrentIndex() == CURSOR.UNABLEREPAIRE then
		Cursor.Switch(CURSOR.REPAIRE)
	elseif not IsCursorInExclusiveMode() then
		Cursor.Switch(CURSOR.NORMAL)
	end
end

---------------------------------------------------------------------
-- 界面处理歪数
---------------------------------------------------------------------
HM_Splitter.OnFrameCreate = function()
	local an = HM_Splitter.tAnchor
	if an and not IsEmpty(an) then
		this:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
		this:CorrectPos()
	end
	this:Lookup("", "Text_Group"):SetText(_L["Group num: "])
	this:Lookup("", "Text_Num"):SetText(_L["Stack num: "])
	this:Lookup("", "Box_Item"):SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	this:Lookup("", "Box_Item"):SetOverTextFontScheme(0, 15)
	this:Lookup("Edit_Group"):SetText(1)
	this:Lookup("Edit_Num"):SetText(1)
end

HM_Splitter.OnFrameBreathe = function()
	if (IsShiftKeyDown() and not IsCursorInExclusiveMode()) or Cursor.GetCurrentIndex() == CURSOR.SPLIT then
		local box = _HM_Splitter.GetOverBagBox()
		if box and not box.bSplitHooked then
			box.bSplitHooked = true
			box._OnItemLButtonClick = box.OnItemLButtonClick
			box._OnItemMouseLeave = box.OnItemMouseLeave
			box._OnItemLButtonDrag = box.OnItemLButtonDrag
			box.OnItemLButtonClick = _HM_Splitter.OnBagBoxLButtonClick
			box.OnItemMouseLeave = _HM_Splitter.OnBagBoxMouseLeave
			box.OnItemLButtonDrag = _HM_Splitter.OnBagBoxLButtonClick
			this.box = box
		end
	elseif this.box and this.box.bSplitHooked then
		_HM_Splitter.OnBagBoxMouseLeave(this.box)
		this.box = nil
	end
end

HM_Splitter.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_Splitter.tAnchor = GetFrameAnchor(this)
end

HM_Splitter.OnLButtonClick = function()
	local szName = this:GetName()
	if szName == "Btn_Close" or szName == "Btn_Close2" then
		this:GetRoot():Hide()
	elseif szName == "Btn_Split" then
		_HM_Splitter.DoSplit(this:GetRoot())
	end
end

HM_Splitter.OnEditChanged = function()
	local szName = this:GetName()
	local box = this:GetRoot():Lookup("", "Box_Item")
	if not box.nStackNum then
		return
	elseif szName == "Edit_Num" then
		local nNum = tonumber(this:GetText())
		local nNum2 = nNum
		if nNum < 1 then
			nNum = 1
		elseif nNum > box.nStackNum then
			nNum = box.nStackNum
		end
		if nNum ~= nNum2 then
			this:SetText(tostring(nNum))
		end
		local nGroup = tonumber(this:GetRoot():Lookup("Edit_Group"):GetText())
		if nNum * nGroup > box.nStackNum then
			nGroup = math.floor(box.nStackNum / nNum)
			this:GetRoot():Lookup("Edit_Group"):SetText(tostring(nGroup))
		end
	elseif szName == "Edit_Group" then
		local nNum = tonumber(this:GetRoot():Lookup("Edit_Num"):GetText())
		local nGroup = tonumber(this:GetText())
		if nNum * nGroup > box.nStackNum then
			nGroup = math.floor(box.nStackNum / nNum)
			this:SetText(tostring(nGroup))
		end
	end
end

HM_Splitter.OnItemMouseEnter = function()
	if this:GetName() == "Box_Item" and this.dwBox then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM, this.dwBox, this.dwX, nil, { x, y, w, h })
		this:SetObjectMouseOver(1)
	end
end

HM_Splitter.OnItemMouseLeave = function()
	if this:GetName() == "Box_Item" then
		this:SetObjectMouseOver(0)
		HideTip()
	end
end

---------------------------------------------------------------------
-- 外部可调用函数
---------------------------------------------------------------------
HM_Splitter.Switch = function(bEnable)
	local frame = Station.Lookup("Normal/HM_Splitter")
	if bEnable and not frame then
		Wnd.OpenWindow("interface\\HM\\HM_ToolBox\\HM_Splitter.ini", "HM_Splitter"):Hide()
	elseif not bEnable and frame then
		Wnd.CloseWindow(frame)
	end
end
