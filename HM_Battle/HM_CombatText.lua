-- 海鳗插件：战斗浮动信息显示释放者名字
--

HM_CombatText = {
	bShowName = true,
}
HM.RegisterCustomData("HM_CombatText")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_CombatText = {
	tList = {},	-- 待处理文本列表
}

-- set text replace
_HM_CombatText.SetText = function(txt, szText)
	txt:__SetText(szText)
	if txt:GetName() == "SkillBuff" then
		local tar = GetPlayer(arg0)
		txt.arg0, txt.arg1 = 0, arg0
		if tar then
			for i = 1, tar.GetBuffCount() do
				local dwID, nLevel, _, _, _, _, dwSkillSrcID = tar.GetBuff(i - 1)
				if dwID == arg2 and nLevel == arg3 then
					txt.arg0 = dwSkillSrcID or 0
					break
				end
			end
		end
	else
		txt.arg0, txt.arg1 = arg0, arg1
	end
	if txt.arg0 ~= UI_GetClientPlayerID() then
		table.insert(_HM_CombatText.tList, txt)
	end
end

-- hook
_HM_CombatText.Hook = function()
	local handle = Station.Lookup("Lowest/CombatTextWnd", "")
	if handle and not handle.bHookByHM then
		handle.bHookByHM = true
		for i = 0, handle:GetItemCount() - 1 do
			local txt = handle:Lookup(i)
			txt.__SetText = txt.SetText
			txt.SetText = _HM_CombatText.SetText
		end
		handle.__AppendItemFromString = handle.AppendItemFromString
		handle.AppendItemFromString = function(h, szMsg)
			h:__AppendItemFromString(szMsg)
			local txt = h:Lookup(h.nUseCount)
			txt.__SetText = txt.SetText
			txt.SetText = _HM_CombatText.SetText
		end
	end
end

-- unhook
_HM_CombatText.UnHook = function()
	local handle = Station.Lookup("Lowest/CombatTextWnd", "")
	if handle and handle.bHookByHM then
		handle.bHookByHM = nil
		handle.AppendItemFromString = handle.__AppendItemFromString
		handle.AppendItemFromString = nil
		for i = 0, handle:GetItemCount() - 1, 1 do
			local txt = handle:Lookup(i)
			txt.SetText = txt.__SetText
			txt.__SetText = nil
		end
	end
end

-- breathe
_HM_CombatText.OnBreathe = function()
	_HM_CombatText.Hook()
	if #_HM_CombatText.tList == 0 then
		return
	end
	for _, v in ipairs(_HM_CombatText.tList) do
		if not v.bFree and v.arg0 ~= 0 and v.arg1 == v.dwOwner and v:IsValid() then
			local tar = GetPlayer(v.arg0)
			if tar then
				v:__SetText(string.gsub(tar.szName, "@.*$", "") .. _L["-"] .. v:GetText())
			end
		end
	end
	_HM_CombatText.tList = {}
end

---------------------------------------------------------------------
-- 对外函数
---------------------------------------------------------------------
HM_CombatText.Switch = function(bEnable)
	if bEnable == nil then
		bEnable = not HM_CombatText.bShowName
	end
	HM_CombatText.bShowName = bEnable
	_HM_CombatText.UnHook()
	if bEnable then
		HM.BreatheCall("HM_CombatText", _HM_CombatText.OnBreathe)
	else
		HM.BreatheCall("HM_CombatText", nil)
	end
end

