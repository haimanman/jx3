--
-- 海鳗插件：职业能量条显示
--

HM_EngBar = {
	tAnchor = {},
}
HM.RegisterCustomData("HM_EngBar")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_EngBar = {
	bEnable = true,
	nBombCount = 0,
	aAccumulateShow =
	{
		{},
		{"10"},
		{"11"},
		{"11", "20"},
		{"11", "21"},
		{"11", "21", "30"},
		{"11", "21", "31"},
		{"11", "21", "31", "40"},
		{"11", "21", "31", "41"},
		{"11", "21", "31", "41", "50"},
		{"11", "21", "31", "41", "51"},
	},
	aAccumulateHide =
	{
		{"10", "11", "20", "21", "30", "31", "40", "41", "50", "51"},
		{"11", "20", "21", "30", "31", "40", "41", "50", "51"},
		{"10", "20", "21", "30", "31", "40", "41", "50", "51"},
		{"10", "21", "30", "31", "40", "41", "50", "51"},
		{"10", "20", "30", "31", "40", "41", "50", "51"},
		{"10", "20", "31", "40", "41", "50", "51"},
		{"10", "20", "30", "40", "41", "50", "51"},
		{"10", "20", "30", "41", "50", "51"},
		{"10", "20", "30", "40", "50", "51"},
		{"10", "20", "30", "40", "51"},
		{"10", "20", "30", "40", "50"},
	},
}

_HM_EngBar.UpdateAnchor = function(frame)
	local an = HM_EngBar.tAnchor
	if an and not IsEmpty(an) then
		frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
		frame:CorrectPos()
	end
end

_HM_EngBar.UpdateAccumulateValue = function(frame)
	if not _HM_EngBar.szShow or _HM_EngBar.szShow == "" then
		return
	end
	local handle = frame:Lookup("", _HM_EngBar.szShow)
	if handle then
		local nValue = GetClientPlayer().nAccumulateValue
		if nValue < 0 then
			nValue = 0
		end
		if _HM_EngBar.szShowSub == "SL" then
			if nValue > 3 then
				nValue = 3
			end
			local szSub = _HM_EngBar.szShowSub .. "_"
			for i = 1, nValue, 1 do
				handle:Lookup(szSub .. i):Show()
			end
			for i = nValue + 1, 3, 1 do
				handle:Lookup(szSub .. i):Hide()
			end
		elseif _HM_EngBar.szShowSub == "QX" then
			local hText = handle:Lookup("Text_Layer")
			local hImage = handle:Lookup("Image_QX_Btn")
			if nValue > 10 then
				nValue = 10
			end
			if nValue > 0 then 
				hText:SetText(nValue)
				hText:Show()
				hImage.bChecked = true
			else
				hText:Hide()
				hImage.bChecked = false
			end
			if hImage.bClickDown then
				hImage:SetFrame(89)
			elseif hImage.bInside then
				hImage:SetFrame(86)
			elseif hImage.bChecked then
				hImage:SetFrame(88)
			else
				hImage:SetFrame(85)
			end
			local szSub =_HM_EngBar.szShowSub .. "_"
			for i = 1, nValue, 1 do
				handle:Lookup(szSub .. i):Show()
			end
			for i = nValue + 1, 10, 1 do
				handle:Lookup(szSub .. i):Hide()
			end
		else
			if nValue > 10 then
				nValue = 10
			end
			nValue = nValue + 1
			local szSub =_HM_EngBar.szShowSub .. "_"
			local aShow = _HM_EngBar.aAccumulateShow[nValue]
			local aHide = _HM_EngBar.aAccumulateHide[nValue]
			for k, v in pairs(aShow) do
				handle:Lookup(szSub .. v):Show()
			end
			for k, v in pairs(aHide) do
				handle:Lookup(szSub .. v):Hide()
			end
		end
	end
end

_HM_EngBar.UpdateCangJian = function(frame)
	local me, hCangjian = GetClientPlayer(), frame:Lookup("", _HM_EngBar.szShow)
	if not me or not hCangjian or not me.bCanUseBigSword then
		return
	end
	local hImageShort = hCangjian:Lookup("Image_Short")
	local hTextShort = hCangjian:Lookup("Text_Short")
	local hAniShort = hCangjian:Lookup("Animate_Short")
	local hImageLong = hCangjian:Lookup("Image_Long")
	local hTextLong = hCangjian:Lookup("Text_Long")
	local hAniLong = hCangjian:Lookup("Animate_Long")
	local szShow = nil
	if me.nMaxRage > 100 then
		hImageShort:Hide()
		hTextShort:Hide()
   		hAniShort:Hide()
		hImageLong:Show()
		hTextLong:Show()
   		hAniLong:Show()
   		szShow = "Long"
	else		
		hImageShort:Show()
		hTextShort:Show()
		hAniShort:Show()
		hImageLong:Hide()
		hTextLong:Hide()
   		hAniLong:Hide()
   		szShow = "Short"
	end
	if me.nMaxRage > 0 then
		hCangjian:Lookup("Image_" .. szShow):SetPercentage(me.nCurrentRage / me.nMaxRage)
		hCangjian:Lookup("Text_" .. szShow):SetText(me.nCurrentRage .. "/" .. me.nMaxRage)
	else
		hCangjian:Lookup("Image_" .. szShow):SetPercentage(0)
		hCangjian:Lookup("Text_" .. szShow):SetText("")
	end
end

_HM_EngBar.UpdateMingJiao = function(frame)
	local hMingJiao = frame:Lookup("", _HM_EngBar.szShow)
	if not hMingJiao then
		return
	end
	local me = GetClientPlayer()
	local imgS = hMingJiao:Lookup("Image_SunEnergy")
	local imgM = hMingJiao:Lookup("Image_MoonEnergy")
	imgS:SetPercentage(me.nCurrentSunEnergy / me.nMaxSunEnergy)
	imgM:SetPercentage(me.nCurrentMoonEnergy / me.nMaxMoonEnergy)
	imgS:Show(me.nSunPowerValue <= 0 and me.nMoonPowerValue <= 0)
	imgM:Show(me.nSunPowerValue <= 0 and me.nMoonPowerValue <= 0)
	hMingJiao:Lookup("Image_MingJiaoBG2"):Show(me.nMoonPowerValue <= 0 and me.nSunPowerValue <= 0 and me.nCurrentSunEnergy <= 0 and me.nCurrentMoonEnergy <= 0)
	hMingJiao:Lookup("Image_SunCao"):Show(me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
	hMingJiao:Lookup("Image_MoonCao"):Show(me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
	hMingJiao:Lookup("Image_SunBG"):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup("Image_MoonBG"):Show(me.nMoonPowerValue > 0)
	hMingJiao:Lookup("Image_SunValue"):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup("Image_MoonValue"):Show(me.nMoonPowerValue > 0)
	hMingJiao:Lookup("Animate_SunValue"):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup("Animate_MoonValue"):Show(me.nMoonPowerValue > 0)
	frame:Lookup("", "Text_Sun"):SetText(FormatString(g_tStrings.MINGJIAO_POWER_SUN, string.format("%d/%d", me.nCurrentSunEnergy / 100, me.nMaxSunEnergy / 100)))
	frame:Lookup("", "Text_Moon"):SetText(FormatString(g_tStrings.MINGJIAO_POWER_MOON, string.format("%d/%d", me.nCurrentMoonEnergy / 100, me.nMaxMoonEnergy / 100)))
end

-- cangyun pose type
_HM_EngBar.UpdateCangYun = function(frame)
	local me, hCangyun = GetClientPlayer(), frame:Lookup("", _HM_EngBar.szShow)
	if not me or not hCangyun then
		return
	end
	local hImageRang = hCangyun:Lookup("Image_Rang")
	local hTextRang = hCangyun:Lookup("Text_Rang")
	if me.nMaxRage > 0 then
		hImageRang:SetPercentage(me.nCurrentRage / me.nMaxRage)
		hTextRang:SetText(me.nCurrentRage .. "/" .. me.nMaxRage)
	else
		hImageRang:SetPercentage(0)
		hTextRang:SetText("")
	end
	hCangyun:Lookup("Image_Sword"):SetVisible(me.nPoseState == POSE_TYPE.SWORD)
	hCangyun:Lookup("Image_Shield"):SetVisible(me.nPoseState == POSE_TYPE.SHIELD)
	local hShield = hCangyun:Lookup("Handle_Sheild")
	if not hShield then
		return
	end
	if me.nLevel >= 50 then
		hShield:Show()
		hShield:Lookup("Image_Sheild"):SetVisible(me.nCurrentEnergy > 0)
		hShield:Lookup("Image_SheildRed"):SetVisible(me.nCurrentEnergy == 0)
		hShield:Lookup("Text_Num"):SetText(me.nCurrentEnergy)
		if me.nMaxEnergy > 0 then
			hShield:Lookup("Image_SheildProgress"):SetPercentage(0.1 + (me.nCurrentEnergy / me.nMaxEnergy * 0.8))
		else
			hShield:Lookup("Image_SheildProgress"):SetPercentage(0)
		end
	else
		hShield:Hide()
	end
end

_HM_EngBar.GetBombCount = function()
	if _HM_EngBar.nBombTime and (GetTime() - _HM_EngBar.nBombTime) < 1000 then
		return _HM_EngBar.nBombCount
	end
	local me, nCount = GetClientPlayer(), 0
	for _, v in ipairs(HM.GetAllNpc()) do
		if v.dwTemplateID == 16000 and v.dwEmployer == me.dwID then
			nCount = nCount + 1
		end
	end
	_HM_EngBar.nBombCount = nCount
	_HM_EngBar.nBombTime = GetTime()
	return nCount
end

_HM_EngBar.UpdateBomb = function(frame)
	local h = frame:Lookup("", _HM_EngBar.szShow)
	if not h then
		return
	end
	local nCount = _HM_EngBar.GetBombCount()
	for i = 0, 2, 1 do
		local img = frame:Lookup("", "Image_Bomb" .. i)
		if i < nCount then
			img:Show()
		else
			img:Hide()
		end
	end
end

_HM_EngBar.UpdateTangMen = function(frame)
	local me, h = GetClientPlayer(), frame:Lookup("", _HM_EngBar.szShow)
	if _HM_EngBar.szShowSub ~= "TM" or not me or not h then
		return
	end
	if me.nMaxEnergy > 0 then
		h:Lookup("Image_Strip"):SetPercentage(me.nCurrentEnergy / me.nMaxEnergy)
		h:Lookup("Text_Energy"):SetText(me.nCurrentEnergy .. "/" .. me.nMaxEnergy)
	else
		h:Lookup("Image_Strip"):SetPercentage(0)
		h:Lookup("Text_Energy"):SetText("")
	end
end

_HM_EngBar.Update = function(frame)
	if _HM_EngBar.szShowSub == "CY" or _HM_EngBar.szShowSub == "SL" or _HM_EngBar.szShowSub == "QX" then
		_HM_EngBar.UpdateAccumulateValue(frame)
	elseif _HM_EngBar.szShowSub == "TM" then
		_HM_EngBar.UpdateTangMen(frame)
		_HM_EngBar.UpdateBomb(frame)
	elseif _HM_EngBar.szShowSub == "CJ" then
		_HM_EngBar.UpdateCangJian(frame)
	elseif _HM_EngBar.szShowSub == "MJ" then
		_HM_EngBar.UpdateMingJiao(frame)
	elseif _HM_EngBar.szShow == "Handle_CangYun" then
		_HM_EngBar.UpdateCangYun(frame)
	end
end

_HM_EngBar.UpdateHandleName = function()
	local mnt = GetClientPlayer().GetKungfuMount()
	local szShow, szShowSub = "", ""
	if mnt then
		if mnt.dwMountType == 3 then
			szShow, szShowSub = "Handle_ChunYang", "CY"
		elseif mnt.dwMountType == 5 then
			szShow, szShowSub = "Handle_ShaoLin", "SL"
		elseif mnt.dwMountType == 10 then
			szShow, szShowSub = "Handle_TangMen", "TM"
		elseif mnt.dwMountType == 4 then
			szShow, szShowSub = "Handle_QiXiu", "QX"
		elseif mnt.dwMountType == 8 then
			szShow, szShowSub = "Handle_MingJiao", "MJ"
		elseif mnt.dwMountType == 18 then
			szShow, szShowSub = "Handle_CangYun", "CYUN"
		end
	end
	_HM_EngBar.szShow = szShow
	_HM_EngBar.szShowSub = szShowSub
end

_HM_EngBar.CopyHandle = function(frame)
	local hTotal = frame:Lookup("", "")
	local me = GetClientPlayer()
	_HM_EngBar.UpdateHandleName()
	if me and me.bCanUseBigSword then
		_HM_EngBar.szShow = "Handle_CangJian"
		_HM_EngBar.szShowSub = "CJ"
	end
	hTotal:Clear()
	if _HM_EngBar.szShow ~= "" then
		if not Station.Lookup("Normal/Player", _HM_EngBar.szShow) then
			_HM_EngBar.szShow = "Handle_" .. _HM_EngBar.szShowSub
		end
		hTotal:AppendItemFromIni("ui\\config\\default\\Player.ini", _HM_EngBar.szShow)
		if _HM_EngBar.szShowSub == "TM" then
			local x = 125
			for i = 0, 2, 1 do
				hTotal:AppendItemFromString("<image>path=\"interface/HM/HM_Force/Ball.UiTex\" frame=0 name=\"Image_Bomb" .. i .. "\" x=" .. x .. " y=0 w=25 h=25 lockshowhide=1 </image>")
				x = x + 25
			end
		elseif _HM_EngBar.szShowSub == "MJ" then
			hTotal:AppendItemFromString("<text>text=\"\" name=\"Text_Sun\" x=87 y=10 w=144 h=20 font=163 </text>")
			hTotal:AppendItemFromString("<text>text=\"\" name=\"Text_Moon\" x=87 y=52 w=144 h=20 font=202 </text>")
		end
		local h = hTotal:Lookup(_HM_EngBar.szShow)
		h:SetRelPos(75, 25)
		h:Show()
	end
	hTotal:FormatAllItemPos()
end

---------------------------------------------------------------------
-- 能量条相关事件函数
---------------------------------------------------------------------
HM_EngBar.OnFrameCreate = function()
	this:RegisterEvent("DO_SKILL_CAST")
	this:RegisterEvent("UI_UPDATE_ACCUMULATE")
	this:RegisterEvent("UI_UPDATE_SUN_MOON_POWER_VALUE")
	this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	this:RegisterEvent("SKILL_UNMOUNT_KUNG_FU")
	this:RegisterEvent("PLAYER_STATE_UPDATE")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("LOADING_END")
	UpdateCustomModeWindow(this, _L["HM, energy bar"])
	_HM_EngBar.UpdateAnchor(this)
	_HM_EngBar.CopyHandle(this)
	_HM_EngBar.Update(this)
end

HM_EngBar.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_EngBar.tAnchor = GetFrameAnchor(this)
end

HM_EngBar.OnEvent = function(event)
	if event == "SKILL_MOUNT_KUNG_FU" or event == "SKILL_UNMOUNT_KUNG_FU" then
		_HM_EngBar.CopyHandle(this)
		_HM_EngBar.Update(this)
	elseif event == "DO_SKILL_CAST" then
		local me = GetClientPlayer()
		if me.dwID == arg0 then
			local nBomb = _HM_EngBar.nBombCount
			if arg1 == 3357 then
				_HM_EngBar.nBombCount = 0
			elseif arg1 == 3111 then
				_HM_EngBar.nBombCount = _HM_EngBar.nBombCount + 1
			end
			if nBomb ~= _HM_EngBar.nBombCount then
				_HM_EngBar.nBombTime = GetTime()
				_HM_EngBar.UpdateBomb(this)
			end
		end
	elseif event == "UI_UPDATE_ACCUMULATE" then
		_HM_EngBar.UpdateAccumulateValue(this)
	elseif event == "UI_UPDATE_SUN_MOON_POWER_VALUE" then
		_HM_EngBar.UpdateMingJiao(this)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" or event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this)
	elseif event == "UI_SCALED" then
		_HM_EngBar.UpdateAnchor(this)
	elseif event == "PLAYER_STATE_UPDATE" and arg0 == GetClientPlayer().dwID then
		if _HM_EngBar.szShowSub == "CJ" then
			_HM_EngBar.UpdateCangJian(this)
		elseif _HM_EngBar.szShowSub == "TM" then
			_HM_EngBar.UpdateTangMen(this)
		elseif _HM_EngBar.szShowSub == "MJ" then
			_HM_EngBar.UpdateMingJiao(this)
		elseif _HM_EngBar.szShow == "Handle_CangYun" then
			_HM_EngBar.UpdateCangYun(this)
		end
	elseif event == "LOADING_END" then
		_HM_EngBar.Update(this)
	end
end

HM_EngBar.OnFrameBreathe = function()
	if _HM_EngBar.szShowSub == "TM" and _HM_EngBar.nBombTime and _HM_EngBar.nBombTime < (GetTime() - 1000) then
		_HM_EngBar.UpdateBomb(this)
	end
end

-- macro command
HM_EngBar.Switch = function(bEnable)
	if bEnable == nil then
		bEnable = not _HM_EngBar.bEnable
	end
	_HM_EngBar.bEnable = bEnable
	local frame = Station.Lookup("Normal/HM_EngBar")
	if not bEnable then
		if frame then
			Wnd.CloseWindow(frame)
		end
	elseif not frame then
		Wnd.OpenWindow("interface\\HM\\HM_Force\\HM_EngBar.ini", "HM_EngBar")
	end
end
