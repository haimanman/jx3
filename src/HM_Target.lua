--
-- 海鳗插件：目标显示增强、连接线、方向指示，显引导
--

HM_Target = {
	bEnable = true,				-- 是否增强显示目标
	bEnableTTarget = false,	-- 是否增强显示目标的目标
	bEnableLM = true,			-- 是否增强血蓝精简
	bConnect = true,				-- 启用目标追踪线
	bTTConnect = false,		-- 显示目标与目标的目标连接线
	bConnFoot = false,			-- 显示在脚上（默认头上）
	nConnWidth = 1,				-- 连接线宽度
	nConnAlpha = 100,			-- 连接线不透明度
	tConnColor = { 255, 0, 0 },	-- 颜色
	bEnableChannel = true,		-- 显示引导技能
	bEnableBreak = true,			-- 突出可打断读条（仅针对 NPC）
	bAdjustBar = true,				-- 上移读条位置
	bDirection = true,				-- 开启目标方向指示
	bDirDist = true,					-- 显示目标距离
	bDirText = true,					-- 显示目标状态文字
	bDirBuff = true,					-- 显示目标的特殊BUFF
	bDirLarge = true,					-- 增大显示指向图标
	tDirAnchor = {},					-- 目标指标的位置
	bAdjustBuff = true,				-- 启用目标 BUFF 放大
	nSizeBuff = 35,					-- 目标 BUFF 新尺寸
	nSizeTTBuff = 30,				-- 目标的目标 BUFF 大小
	bNoSpark = true,				-- 取消 BUFF 闪烁
	bSubDebuff = false,			-- 屏蔽相同的 DEBUFF
}
HM.RegisterCustomData("HM_Target")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Target = {
	bChange = false,
	bChangeTTarget = false,
	szIniFile = "interface\\HM\\ui\\HM_Target.ini",
	tChannel = {},	-- 引导技能记录
}

-- channel skill
_HM_Target.tChannelSkill = {
	[570] = 32,	[3985] = 114,	[7319] = 96,	[2724] = 40,	[3100] = 48,
	[1645] = 84,	[7320] = 128,	[2674] = 8,	[2707] = 48,	[2589] = 96,
	[7317] = 48,	[7318] = 64,	[7314] = 32,	[3093] = 40,	[3964] = 70,
	[3961] = 60,	[565] = 48,	[2233] = 80,	[2235] = 128,	[567] = 160,
	[300] = 80,	[368] = 80,	[2636] = 80,
}

-- not broken skill
_HM_Target.tNoBrokenSkill = {
	3022, 1514, 2514, 2026, 2029, 3033, 2031, 3549, 1778, 2531, 2532, 2533, 2534, 2535, 7623,
	2038, 7629, 3564, 3566, 2041, 2548, 3571, 3577, 3578, 7661, 3580, 2048, 2050, 2051, 2054,
	7679, 7681, 3590, 1542, 3592, 3593, 3595, 3597, 1546, 1036, 3602, 3603, 1804, 7202, 1294,
	1039, 7719, 7210, 1041, 7216, 4152, 7220, 3616, 7228, 1045, 4170, 3623, 7751, 7242, 2094,
	3628, 1562, 4200, 2105, 3128, 3129, 1056, 4210, 7789, 7280, 3134, 3135, 3137, 2118, 3143,
	4240, 3149, 4248, 4250, 1067, 3664, 3666, 3669, 3671, 2141, 3164, 3166, 1330, 3682, 3173,
	7364, 4813, 3179, 3180, 4310, 3182, 1340, 7392, 1342, 3703, 3705, 1344, 3197, 1347, 3713,
	1348, 1349, 3717, 3718, 3719, 1351, 4372, 2193, 3731, 2199, 2203, 4400, 4402, 2208, 1362,
	7492, 1624, 3246, 4953, 3760, 3250, 1629, 3256, 1375, 1631, 1632, 173, 1634, 1635, 1381,
	1639, 1640, 2255, 1641, 3792, 1133, 1134, 2777, 1136, 2782, 1138, 1139, 1140, 1652, 2279,
	1142, 2282, 1144, 2798, 1146, 2289, 2290, 1148, 2296, 2809, 2812, 961, 2311, 2312, 2824,
	2829, 7790, 7787, 4127, 7784, 7782, 7632, 7747, 7203, 7205, 7744, 7720, 7722, 7736, 1680,
	7217, 7219, 7732, 7731, 7225, 7730, 3874, 7721, 3365, 4169, 4171, 2346, 2347, 4177, 2349,
	7758, 7625, 7562, 7535, 7485, 3377, 4193, 7469, 847, 4360, 2360, 2361, 2362, 2874, 1184,
	7398, 2366, 3900, 2879, 2880, 2881, 2882, 2883, 4364, 2885, 2886, 2887, 7396, 2889, 2890,
	3912, 2892, 4379, 1960, 3917, 7381, 854, 4455, 4865, 1963, 2901, 7281, 7331, 3926, 7259,
	4782, 7230, 7229, 7218, 7215, 7206, 7204, 7200, 1970, 7196, 7194, 7190, 7361, 4861, 4801,
	4757, 62, 4751, 4496, 1147, 4456, 7379, 1977, 1560, 1630, 3714, 1979, 3613, 7393, 7395,
	7397, 7399, 4208, 4312, 4252, 4231, 4343, 4206, 4204, 4202, 2080, 1547, 3970, 3547, 1357,
	3254, 2198, 841, 832, 4128, 2259, 3392, 3914, 4377, 1482, 4381, 3533, 4385, 3025, 1047,
	1996, 1953, 3708, 1742, 4399, 1049, 4403, 1051, 974, 2370, 4179, 3641, 1767, 1182, 1492,
	1055, 72, 1821, 2005, 3660, 3536, 1452, 855, 1443, 2008, 2371, 986, 3504, 2010, 3535,
	1448, 1245, 1501, 4457, 2013, 4023, 1770, 1248, 2015, 1249, 1135, 3318, 3257, 1328, 2522,
	3011, 2271, 1332, 1019, 1143, 2036, 1081, 2157, 3530, 3531, 2510, 1413,
}

-- reset broken table
_HM_Target.InitNoBroken = function()
	local t = {}
	for _, v in ipairs(_HM_Target.tNoBrokenSkill) do
		t[v] = true
	end
	_HM_Target.tNoBrokenSkill = t
end

-- equal
_HM_Target.AboutEqual = function(dw1, dw2)
	local dw0 = dw1 - dw2
	return dw0 > -2 and dw0 < 2
end

-- get channel data
_HM_Target.GetSkillChannelState = function(dwID)
	local rec = _HM_Target.tChannel[dwID]
	if rec then
		local nFrame = GetLogicFrameCount() - rec[2]
		if nFrame < rec[3] then
			local fP = 1 - nFrame / rec[3]
			return rec[1], fP, rec[4]
		end
	end
end

-- connect line settting menu
_HM_Target.GetConnMenu = function()
	local m0 = {
		{
			szOption = _L["Set connected line color"],
			bColorTable = true, bNotChangeSelfColor = false, rgb = HM_Target.tConnColor,
			fnChangeColor = function(data, r, g, b) HM_Target.tConnColor = { r, g, b } end
		},
	}
	local m1 = { szOption = _L["Set connected line width"], }
	for i = 1, 5 do
		local m2 = { szOption = tostring(i), bCheck = true, bMCheck = true }
		m2.bChecked = HM_Target.nConnWidth == i
		m2.fnAction = function() HM_Target.nConnWidth = i end
		table.insert(m1, m2)
	end
	table.insert(m0, m1)
	m1 = { szOption = _L["Connected line opacity"], }
	for i = 60, 200, 20 do
		local m2 = { szOption = tostring(i), bCheck = true, bMCheck = true }
		m2.bChecked = HM_Target.nConnAlpha == i
		m2.fnAction = function() HM_Target.nConnAlpha = i end
		table.insert(m1, m2)
	end
	table.insert(m0, m1)
	return m0
end

-- enhance target panel
_HM_Target.UpdateName = function(frame, bRestore)
	local tar = GetTargetHandle(frame.dwType, frame.dwID)
	if not tar then
		return
	end
	local text = frame:Lookup("", "Text_Target")
	local szName = HM.GetTargetName(tar)
	if HM_About.CheckNameEx(szName)
		and not HM.IsParty(frame.dwID)
		and not HM_About.CheckNameEx(GetClientPlayer().szName)
	then
		local n = math.ceil(GetLogicFrameCount() / 480) % 4
		if n == 1 then
			szName = _L["Who am I ^o^"]
		elseif n == 2 then
			szName = _L["Not tell you @_@"]
		elseif n == 3 then
			szName = _L["FAKE - "] .. GetClientPlayer().szName
		else
			szName = _L["OUTER GUEST ~_~"]
		end
	elseif not bRestore then
		szName = string.format("%.1f", HM.GetDistance(tar)) .. _L["-"] .. szName
		if frame.dwType == TARGET.PLAYER then
			local mnt = tar.GetKungfuMount()
			if mnt then
				szName = szName .. _L["-"] .. string.sub(HM.GetSkillName(mnt.dwSkillID, mnt.dwLevel), 1, 4)
			end
		elseif frame.dwType == TARGET.NPC and tar.dwDropTargetPlayerID then
			if tar.dwDropTargetPlayerID == 0 then
				szName = szName .. _L["-"] .. "NEW"
			else
				local drp = GetPlayer(tar.dwDropTargetPlayerID)
				if drp then
					szName = szName .. _L["-"] .. drp.szName
				end
			end
		end
	end
	text:SetFontColor(GetForceFontColor(frame.dwID, GetClientPlayer().dwID))
	text:SetText(szName)
end

-- update action
_HM_Target.UpdateAction = function(frame)
	local tar = GetTargetHandle(frame.dwType, frame.dwID)
	local handle = frame:Lookup("", "Handle_Bar")
	local text = handle:Lookup("Text_Name")
	-- FIXME: Target.bShowActionBar
	if not tar then
		return handle:Hide()
	end
	-- check broken
	local bPrePare, dwID, dwLevel, _ = tar.GetSkillPrepareState()
	if bPrePare then
		text:SetFontColor(255, 255, 255)
		if HM_Target.bEnableBreak and _HM_Target.tNoBrokenSkill[dwID] then
			text:SetFontColor(180, 180, 180)
		end
	end
	-- check channel
	if HM_Target.bEnableChannel and frame.dwType == TARGET.PLAYER and tar.GetOTActionState() == 2 then
		local szSkill, fP, dwID = _HM_Target.GetSkillChannelState(tar.dwID)
		if szSkill then
			handle:SetAlpha(255)
			handle:Show()
			handle:Lookup("Image_Progress"):Show()
			handle:Lookup("Image_FlashS"):Hide()
			handle:Lookup("Image_FlashF"):Hide()
			text:SetText(szSkill)
			text:SetFontColor(255, 255, 255)
			if HM_Target.bEnableBreak and _HM_Target.tNoBrokenSkill[dwID] then
				text:SetFontColor(180, 180, 180)
			end
			handle:Lookup("Image_Progress"):SetPercentage(fP)
			-- FIXME：ACTION_STATE.FADE  = 5
			handle.nActionState = 5
		end
	end
	-- adjust pos
	if HM_Target.bAdjustBar then
		local nX, nY = handle:GetRelPos()
		local _, nH = handle:GetSize()
		local bShowBar = handle:IsVisible()
		local tName = { "Buff", "TextBuff", "Debuff", "TextDebuff" }
		if not frame.tOrigPos then
			frame.tOrigPos = {}
			frame.tOrigPos["Bar"] = { nX, nY }
		end
		for k, v in ipairs(tName) do
			local h = frame:Lookup("", "Handle_" .. v)
			if h then
				local oX, oY = h:GetRelPos()
				if not frame.tOrigPos[v] then
					frame.tOrigPos[v] = { oX, oY }
				end
				if bShowBar then
					if _HM_Target.AboutEqual(oY, frame.tOrigPos[v][2]) then
						h:SetRelPos(oX, oY + nH)
						if v == "Buff" or v == "Debuff" then
							local h2 = frame:Lookup("", "Image_" .. v .. "BG")
							if h2 then h2:SetRelPos(oX, oY + nH) end
						end
					else
						break
					end
				else
					if not _HM_Target.AboutEqual(oY, frame.tOrigPos[v][2]) then
						h:SetRelPos(oX, oY - nH)
						if v == "Buff" or v == "Debuff" then
							local h2 = frame:Lookup("", "Image_" .. v .. "BG")
							if h2 then h2:SetRelPos(oX, oY - nH) end
						end
					else
						break
					end
				end
			end
		end
		handle:SetRelPos(nX, frame.tOrigPos["Buff"][2])
		frame:Lookup("", ""):FormatAllItemPos()
	elseif frame.tOrigPos then
		-- restore pos
		for k, v in pairs(frame.tOrigPos) do
			local h =frame:Lookup("", "Handle_" .. k)
			h:SetRelPos(v[1], v[2])
		end
		frame:Lookup("", ""):FormatAllItemPos()
		frame.tOrigPos = nil
	end
end

-- refresh buff size
_HM_Target.RefreshBuff = function()
	Wnd.CloseWindow("Target")
	Wnd.CloseWindow("TargetTarget")
	local dwType, dwID = GetClientPlayer().GetTarget()
	if dwID ~= 0 then
		HM.SetTarget(TARGET.NO_TARGET, 0)
		HM.SetTarget(dwType, dwID)
	end
end

-- adjust buff position
_HM_Target.InitBuffPos = function(frame, nSize)
    local nY, tName = nil, { "Buff", "TextBuff", "Debuff", "TextDebuff" }
    for _, v in ipairs(tName) do
        local h = frame:Lookup("", "Handle_" .. v)
        if h then
			local nW, nH = h:GetSize()
            if not nY then
                _, nY = h:GetRelPos()
            else
                local nX, _ = h:GetRelPos()
                h:SetRelPos(nX, nY)
				if v == "Debuff" then
					if h:GetPosType() == 7 then
						nX, _ = frame:Lookup("", "Handle_Buff"):GetRelPos()
						h:SetPosType(0)
						h:SetRelPos(nX, nY)
					end
					local h2 = frame:Lookup("", "Image_DebuffBG")
					if h2 then h2:SetRelPos(nX, nY) end
				end
            end
            if v == "Buff" or v == "Debuff" then
                nY = nY + nSize + 5
                if v == "Debuff" then
                    local h2 = frame:Lookup("", "Handle_Bar")
                    local nX, _ = h2:GetRelPos()
                    h2:SetRelPos(nX, nY)
                end
				h:SetSize(nW, nSize + 5)
            else
				h:SetSize(nW, 20)
                nY = nY + 20
            end
        end
    end
    frame:Lookup("", ""):FormatAllItemPos()
	frame.bAdjustInit = true
	frame.bIsEnemy = IsEnemy(GetClientPlayer().dwID, frame.dwID)
end

-- get buff left time
_HM_Target.GetBuffTime = function(nEnd)
	local nLeft = nEnd - GetLogicFrameCount()
    local szTime, nFont = "", 162
    local nH, nM, nS = GetTimeToHourMinuteSecond(nLeft, true)
    if nH >= 1 then
		if nH <= 99 then
			if nM >= 1 or nS >= 1 then
				nH = nH + 1
			end
			szTime = nH .. " "
		end
    elseif nM >= 1 then
        if nS >= 1 then
            nM = nM + 1
        end
        szTime = nM .. "'"
    elseif nS >= 0 then
		szTime = nS .. "''"
		nFont = 163
    end
    return szTime, nFont, nLeft
end

-- update buff time
_HM_Target.UpdateBuffTime = function(hBuffList, hTextList)
	local nCount = hBuffList:GetItemCount() - 1
	if HM_Target.bSubDebuff and hBuffList:GetName() == "Handle_Debuff" then
		local tBuffID, tRemove = {}, {}
		for i = 0, nCount do
			local hBox = hBuffList:Lookup(i)
			if tBuffID[hBox.dwBuffID] or i >= 10 then
				table.insert(tRemove, i)
			else
				tBuffID[hBox.dwBuffID] = true
			end
		end
		local nRemove = table.getn(tRemove)
		for i = nRemove, 1, -1 do
			hBuffList:RemoveItem(tRemove[i])
			if hTextList then
				hTextList:RemoveItem(tRemove[i])
			end
		end
		if nRemove > 0 then
			hBuffList:FormatAllItemPos()
			if hTextList then
				hTextList:FormatAllItemPos()
			end
			nCount = nCount - nRemove
		end
	end
	if not HM_Target.bNoSpark and hTextList then
		return
	end
	for i = 0, nCount do
        local hBox = hBuffList:Lookup(i)
		local szTime, nFont, nLeft = _HM_Target.GetBuffTime(hBox.nEndFrame)
		if not hBox.bShowTime2 and not hBox.bShowTime then
			szTime = ""
		end
		if nLeft > 0 and szTime ~= hBox.szTime then
			hBox.szTime = szTime
			if not hTextList then
				hBox:SetOverTextFontScheme(1, 16)
				hBox:SetOverTextPosition(1, 3)
				hBox:SetOverText(1, szTime)
			else
				local hText = hTextList:Lookup(i)
				hText:SetText(szTime)
				hText:SetFontScheme(nFont)
			end
		end
	end
end

-- update target buff bg
_HM_Target.UpdateBuffBg = function(frame, nDispel)
	local img1, img2 = nil, nil
	if frame.bIsEnemy then
		img1 = frame:Lookup("", "Image_BuffBG")
		img2 = frame:Lookup("", "Image_DebuffBG")
	else
		img1 = frame:Lookup("", "Image_DebuffBG")
		img2 = frame:Lookup("", "Image_BuffBG")
	end
	if img1 and img2 then
		local nH = HM_Target.nSizeBuff + 5
		local nW = nH * nDispel
		img1:SetSize(nW, nH)
		img2:SetSize(0, nH)
	end
end

-- update buff size
_HM_Target.UpdateBuffSize = function(frame, bTTarget)
	if frame.bAdjustInit and not frame.bBuffUpdate and frame.dwID2 == frame.dwID then
		return
	end
	local nSize = (bTTarget and HM_Target.nSizeTTBuff) or HM_Target.nSizeBuff
	local nDispel = 0
	if not frame.bAdjustInit then
		_HM_Target.InitBuffPos(frame, nSize)
	end
	for _, v in ipairs({ "Buff", "Debuff" }) do
		local hBuff, hText = frame:Lookup("", "Handle_" .. v), frame:Lookup("", "Handle_Text" .. v)
		for i = 0, hBuff:GetItemCount() - 1 do
			local box = hBuff:Lookup(i)
			if box.nW ~= nSize then
				local nW, nH = box:GetSize()
				nW = nSize + nW - box.nW
				nH = nSize + nH - box.nH
				box:SetSize(nW, nH)
				if box.nCount > 1 then
					box:SetOverTextPosition(0, box:GetOverTextPosition(0))
				end
				box.nW, box.nH = nSize, nSize
			end
			if hText then
				local txt = hText:Lookup(i)
				local nTW, _ = box:GetSize()
				local _, nTH = txt:GetSize()
				txt:SetSize(nTW, nTH)
			end
			if HM_Target.bNoSpark then
				box.bSparking = false
				box.bShowTime2 = Table_BuffNeedShowTime(box.dwBuffID, box.nLevel)
				box.bShowTime = false
			end
			box.szTime = nil
			if box.bDispel then
				nDispel = nDispel + 1
			end
		end
		hBuff:FormatAllItemPos()
		if hText then
			hText:FormatAllItemPos()
		end
	end
	-- dispel bg
	if nDispel > 0 then
		_HM_Target.UpdateBuffBg(frame, nDispel)
	end
	frame.bBuffUpdate, frame.dwID2 = false, frame.dwID
end

-- get simple num
_HM_Target.GetSimpleNum = function(n)
	if n < 100000 then
		return tostring(n)
	elseif n < 1000000 then
		return _L("%.1fw", n / 10000)
	elseif n < 100000000 then
		return _L("%dw", n / 10000)
	else
		return _L("%db", n / 100000000)
	end
end

-- get state string
_HM_Target.GetStateString = function(nCur, nMax, bTTarget)
	local szText = _HM_Target.GetSimpleNum(nMax)
	if not bTTarget then
		szText = _HM_Target.GetSimpleNum(nCur) .. "/" .. szText
	end
	if nCur >= nMax or nMax <= 1 then
		return szText .. "(100%)"
	elseif nCur == 0 then
		return szText .. "(0%)"
	else
		return szText .. string.format("(%.1f%%)", nCur * 100 / nMax)
	end
end

-- update life/mana
_HM_Target.UpdateLM = function(frame, bTTarget)
	local tar = GetTargetHandle(frame.dwType, frame.dwID)
	if not tar or not frame:IsVisible() then
		return
	end
	-- health
	local hTextHealth = frame:Lookup("", "Text_Health")
	hTextHealth:SetText(_HM_Target.GetStateString(tar.nCurrentLife, tar.nMaxLife, bTTarget))
	hTextHealth:Show()
	-- check mana/rage/energy
	local hMana, hTextMana = frame:Lookup("", "Image_Mana"), frame:Lookup("", "Text_Mana")
	local fM, sM = nil, ""
	if frame.dwType == TARGET.PLAYER and frame.dwMountType then
		if frame.dwMountType == 10 and tar.nMaxEnergy > 0 then	-- TM
			fM = tar.nCurrentEnergy / tar.nMaxEnergy
			sM = _HM_Target.GetStateString(tar.nCurrentEnergy, tar.nMaxEnergy, bTTarget)
		elseif frame.dwMountType == 6 and tar.nMaxRage > 0 then	-- CJ
			fM = tar.nCurrentRage / tar.nMaxRage
			sM = _HM_Target.GetStateString(tar.nCurrentRage, tar.nMaxRage, bTTarget)
		end
	end
	-- update mana image
	if fM ~= nil then
		hMana:Show()
		hMana:SetFrame(87)
		hMana:SetPercentage(fM)
		for _, v in ipairs({ "FBgC", "FBgCR", "FBgCRR", "FBgR", "FBgL", "TarBgF" }) do
			local h = frame:Lookup("", "Image_" .. v)
			if h then h:Hide() end
		end
		for _, v in ipairs({ "TarBgC", "TarBgCR", "TarBgCRR", "TarBgR", "TarBgL", "TarBg" }) do
			local h = frame:Lookup("", "Image_" .. v)
			if h then h:Show() end
		end
	else
		hMana:SetFrame(37)
		if hMana:IsVisible() then
			sM = _HM_Target.GetStateString(tar.nCurrentMana, tar.nMaxMana, bTTarget)
		end
	end
	-- update mana text
	hTextMana:SetText(sM)
	hTextMana:Show()
end

-------------------------------------
-- 呼吸函数、事件处理
-------------------------------------
-- update target action
_HM_Target.AddBreathe = function(frame, bTTarget)
	-- check frame
	if not frame or not frame:IsVisible() then
		if frame then
			frame.dwID2 = nil
		end
		_HM_Target.nBuffBreathe = 0
		return
	end
	-- refresh event hook
	if not frame.bEventInit then
		local h = _HM_Target.frame
		for _, v in ipairs({ "BUFF_UPDATE", "NPC_STATE_UPDATE", "PLAYER_STATE_UPDATE" }) do
			h:UnRegisterEvent(v)
			h:RegisterEvent(v)
		end
		frame.bEventInit = true
	end
	local nFrame = GetLogicFrameCount()
	-- update name
	if (nFrame % 2) == 0 then
		if bTTarget then
			if HM_Target.bEnableTTarget then
				_HM_Target.UpdateName(frame)
			elseif _HM_Target.bChangeTTarget then
				_HM_Target.UpdateName(frame, true)
				_HM_Target.bChangeTTarget = nil
			end
		else
			if HM_Target.bEnable then
				_HM_Target.UpdateName(frame)
			elseif _HM_Target.bChange then
				_HM_Target.UpdateName(frame, true)
				_HM_Target.bChange = nil
			end
		end
	end
	-- adjust buff
	if HM_Target.bAdjustBuff then
		-- buffsize
		_HM_Target.UpdateBuffSize(frame, bTTarget)
		-- bufftime (ttarget/target)
		if not frame.nBuffBreathe or (nFrame - frame.nBuffBreathe) >= 3 then
			_HM_Target.UpdateBuffTime(frame:Lookup("", "Handle_Buff"), frame:Lookup("", "Handle_TextBuff"))
			_HM_Target.UpdateBuffTime(frame:Lookup("", "Handle_Debuff"), frame:Lookup("", "Handle_TextDebuff"))
			frame.nBuffBreathe = nFrame
		end
	end
	-- update action(channel)
	_HM_Target.UpdateAction(frame)
end

-- skill cast log (channel)
_HM_Target.OnSkillCast = function(dwCaster, dwID, dwLevel, szEvent)
	if HM_Target.bEnableChannel and _HM_Target.tChannelSkill[dwID] then
		local nFrame, nChannel = GetLogicFrameCount(), _HM_Target.tChannelSkill[dwID]
		local szSkill = HM.GetSkillName(dwID, dwLevel)
		if szSkill ~= "" then
			-- purge
			for k, v in pairs(_HM_Target.tChannel) do
				local bDel = (nFrame - v[2]) > v[3]
				if not bDel then
					local p = GetPlayer(k)
					bDel = p ~= nil and p.GetOTActionState() ~= 2
				end
				if bDel then
					_HM_Target.tChannel[k] = nil
				end
			end
			-- save & debug
			if szEvent == "DO_SKILL_CAST" or not _HM_Target.tChannel[dwCaster] then
				_HM_Target.tChannel[dwCaster] = { szSkill, nFrame, nChannel, dwID }
				HM.Debug2("[#" .. dwCaster .. "] cast channel skill [" .. szSkill .. "#" .. szEvent .. "]")
			end
		end
	end
end

-- buff update
-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
-- arg8：nLevel，arg9：dwSkillSrcID
_HM_Target.OnBuffUpdate = function()
	for _, v in ipairs({ "Target", "TargetTarget" }) do
		local frame = Station.Lookup("Normal/" .. v)
		if frame and frame:IsVisible() and arg0 == frame.dwID then
			frame.bBuffUpdate = true
			if v == "Target" and not arg1 and not arg7 then
				local szType = (arg3 and "Buff") or "Debuff"
				local hTextList = frame:Lookup("", "Handle_Text" .. szType)
				local hText = hTextList.tItem["b" .. arg2]
				if hText and hText:GetFontScheme() == 166 then
					hText:SetFontScheme(163)
				end
			end
		end
	end
end

-- state update/Life & mana
_HM_Target.OnUpdateLM = function()
	if not HM_Target.bEnableLM then
		return
	end
	if HM_Target.bEnable then
		local frame = Station.Lookup("Normal/Target")
		if frame and frame:IsVisible() and arg0 == frame.dwID then
			_HM_Target.UpdateLM(frame)
		end
	end
	if HM_Target.bEnableTTarget then
		local frame = Station.Lookup("Normal/TargetTarget")
		if frame and frame:IsVisible() and arg0 == frame.dwID then
			_HM_Target.UpdateLM(frame, true)
		end
	end
end

---------------------------------------------------------------------
-- 窗口函数
---------------------------------------------------------------------
_HM_Target.DrawConnect = function(conn, me, tar)
	if not tar or me.dwID == tar.dwID then
		return
	end
	conn:SetTriangleFan(true)
	conn:ClearTriangleFanPoint()
	local col, nAlpha = HM_Target.tConnColor, HM_Target.nConnAlpha
	local nAlpha1 = math.ceil(nAlpha * 0.3)
	local cX, cY  = HM_Target.nConnWidth, 0
	local _GetPoint = HM.GetTopPoint
	if HM_Target.bConnFoot then
		_GetPoint = HM.GetScreenPoint
	end
	local nX, nY = _GetPoint(me)
	local nX1, nY1 = _GetPoint(tar)
	if nX and nY and nX1 and nY1 then
		local dwAngle = math.abs(math.atan((nX - nX1)/(nY1 - nY)))
		if dwAngle > 1 and dwAngle < 1.57 then
			cX, cY = cY, cX
		end
		conn:AppendTriangleFanPoint(nX1 - cX, nY1 + cY, col[1], col[2], col[3], nAlpha1)
		conn:AppendTriangleFanPoint(nX1 + cX, nY1 - cY, col[1], col[2], col[3], nAlpha1)
		cX  = cX + cX
		cY = cY + cY
		conn:AppendTriangleFanPoint(nX + cX, nY - cY, col[1], col[2], col[3], nAlpha)
		conn:AppendTriangleFanPoint(nX - cX, nY + cY, col[1], col[2], col[3], nAlpha)
		conn:Show()
	end
end

_HM_Target.OnRender = function()
	local me = GetClientPlayer()
	if not me then return end
	local tar = GetTargetHandle(me.GetTarget())
	-- conn
	_HM_Target.hConnect:Hide()
	if HM_Target.bConnect and tar and tar.dwID ~= me.dwID then
		_HM_Target.DrawConnect(_HM_Target.hConnect, me, tar)
	end
	-- ttconn
	_HM_Target.hTTConnect:Hide()
	if HM_Target.bTTConnect and tar then
		local ttar = GetTargetHandle(tar.GetTarget())
		if ttar and ttar.dwID ~= tar.dwID and ttar.dwID ~= me.dwID then
			_HM_Target.DrawConnect(_HM_Target.hTTConnect, tar, ttar)
		end
	end
end

-- create
function HM_Target.OnFrameCreate()
	_HM_Target.hTotal = this:Lookup("", "")
	_HM_Target.hConnect = this:Lookup("", "Shadow_Connect")
	_HM_Target.hTTConnect = this:Lookup("", "Shadow_TTConnect")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("DO_SKILL_CAST")
end

-- event
function HM_Target.OnEvent(event)
	if event == "RENDER_FRAME_UPDATE" then
		_HM_Target.OnRender()
	elseif event == "SYS_MSG" then
		if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
			_HM_Target.OnSkillCast(arg1, arg4, arg5, arg0)
		elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
			_HM_Target.OnSkillCast(arg1, arg5, arg6, arg0)
		end
	elseif event == "DO_SKILL_CAST" then
		_HM_Target.OnSkillCast(arg0, arg1, arg2, event)
	elseif event == "BUFF_UPDATE" then
		_HM_Target.OnBuffUpdate()
	elseif event == "NPC_STATE_UPDATE" or event == "PLAYER_STATE_UPDATE" then
		_HM_Target.OnUpdateLM()
	end
end

-- update dir (open/close)
_HM_Target.UpdateDir = function()
	local frame = Station.Lookup("Normal/HM_TargetDir")
	if not HM_Target.bDirection then
		if frame then
			Wnd.CloseWindow(frame)
		end
	elseif not frame then
		frame = Wnd.OpenWindow("interface\\HM\\ui\\HM_TargetDir.ini", "HM_TargetDir")
		HM_TargetDir.AdjustSize()
	end
end

---------------------------------------------------------------------
-- 目标方向指示 (HM_TargetDir)
---------------------------------------------------------------------
HM_TargetDir = {}

-- adjust size
HM_TargetDir.AdjustSize = function()
	local handle = Station.Lookup("Normal/HM_TargetDir"):Lookup("", "")
	if HM_Target.bDirLarge then
		handle:Lookup("Image_Force"):SetSize(42, 42)
		handle:Lookup("Box_Buff"):SetSize(42, 42)
		handle:Lookup("Text_State"):SetRelPos(0, 34)
		handle:Lookup("Image_Force"):SetRelPos(59, 59)
		handle:Lookup("Box_Buff"):SetRelPos(59, 59)
		handle:Lookup("Text_Distance"):SetRelPos(0, 101)
		handle:Lookup("Text_State"):SetFontScheme(199)
		handle:Lookup("Text_Distance"):SetFontScheme(188)
	else
		handle:Lookup("Image_Force"):SetSize(30, 30)
		handle:Lookup("Box_Buff"):SetSize(30, 30)
		handle:Lookup("Text_State"):SetRelPos(0, 40)
		handle:Lookup("Image_Force"):SetRelPos(65, 65)
		handle:Lookup("Box_Buff"):SetRelPos(65, 65)
		handle:Lookup("Text_Distance"):SetRelPos(0, 95)
		handle:Lookup("Text_State"):SetFontScheme(159)
		handle:Lookup("Text_Distance"):SetFontScheme(16)
	end
	handle:FormatAllItemPos()
end

-- anchor
HM_TargetDir.UpdateAnchor = function(frame)
	local a = HM_Target.tDirAnchor
	if IsEmpty(a) then
		local nW, nH = Station.GetClientSize()
		frame:SetAbsPos(math.ceil(nW/2) + 40, math.ceil(nH/2) - 40)
	else
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	end
	frame:CorrectPos()
end

-- set to head
HM_TargetDir.SetHeadImage = function(hImg, tar)
	if hImg.dwID ~= tar.dwID then
		hImg.dwID = tar.dwID
		if IsPlayer(tar.dwID) then
			local mnt = tar.GetKungfuMount()
			if mnt and mnt.dwSkillID ~= 0 then
				hImg:FromIconID(Table_GetSkillIconID(mnt.dwSkillID, 0))
			else
				if not mnt then
					local dwType, dwID = GetClientPlayer().GetTarget()
					HM.SetTarget(TARGET.PLAYER, tar.dwID)
					HM.SetTarget(dwType, dwID)
				end
				hImg:FromUITex(GetForceImage(tar.dwForceID))
				hImg.dwID = nil
			end
		else
			local szPath = NPC_GetProtrait(tar.dwModelID)
			if not szPath or not IsFileExist(szPath) then
				szPath = NPC_GetHeadImageFile(tar.dwModelID)
			end
			if not szPath or not IsFileExist(szPath) then
				hImg:FromUITex(GetNpcHeadImage(tar.dwID))
			else
				hImg:FromTextureFile(szPath)
			end
		end
	end
end

-- get state/icon (return: icon, szState, bufID, buffLevel, buff.nEndFrame)
HM_TargetDir.GetState = function(tar, bBuff)
	if tar.nMoveState == MOVE_STATE.ON_SIT then
		return 533, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_DEATH then
		return 2215, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_KNOCKED_DOWN then
		return 2027, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_DASH then
		return 2030, g_tStrings.tPlayerMoveState[tar.nMoveState]
	else
		local szText, dwIcon, buff
		-- check buff
		if HM_TargetMon and bBuff then
			local nFrame = GetLogicFrameCount()
			local szType, nType
			local tAll = tar.GetBuffList() or {}
			for _, v in ipairs(tAll) do
				if v.nEndFrame > nFrame then
					local _szType, _nType = HM_TargetMon.GetBuffExType(v.dwID, v.nLevel)
					if _szType and (not nType or _nType < nType) then
						szType, nType = _szType, _nType
						buff = v
					end
				end
			end
			if buff then
				szText, dwIcon = HM.GetBuffName(buff.dwID, buff.nLevel)
				if szType ~= _L["Others"] then
					szText = string.gsub(szType, "%d+$", "")
				end
			end
		end
		-- check other movestate
		if tar.nMoveState == MOVE_STATE.ON_HALT and szText ~= _L["Halt"] then
			return 2019, g_tStrings.tPlayerMoveState[tar.nMoveState]
		elseif tar.nMoveState == MOVE_STATE.ON_FREEZE and szText ~= _L["Freeze"] then
			return 2038, g_tStrings.tPlayerMoveState[tar.nMoveState]
		elseif tar.nMoveState == MOVE_STATE.ON_ENTRAP and szText ~= _L["Entrap"] then
			return 2020, _L["Entrap"]
		end
		-- check speed
		if buff then
			return dwIcon, szText, buff
		elseif IsPlayer(tar.dwID) and tar.nRunSpeed < 20 then
			return 348, _L["Slower"]
		end
	end
end

-- get status icon & text
HM_TargetDir.UpdateState = function(frame, tar)
	local dwIcon, szText
	local hImage, hBox = frame:Lookup("", "Image_Force"), frame:Lookup("", "Box_Buff")
	-- get state
	local dwIcon, szText, buff = HM_TargetDir.GetState(tar, HM_Target.bDirBuff)
	if not buff then
		hBox.dwID = nil
		hBox:SetOverText(0, "")
		hBox:SetOverText(1, "")
	else
		hBox.dwID, hBox.nLevel = buff.dwID, buff.nLevel
		if buff.nStackNum > 1 then
			hBox:SetOverText(0, buff.nStackNum)
		else
			hBox:SetOverText(0, "")
		end
		local nSec = (buff.nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
		if nSec < 3 then
			hBox:SetOverText(1, string.format("%.1f\"", nSec))
		else
			hBox:SetOverText(1, string.format("%d\"", nSec))
		end
		hBox.dwOwner = tar.dwID
	end
	-- update image
	if not dwIcon then
		hBox:Hide()
		if tar.nMoveState == MOVE_STATE.ON_AUTO_FLY then
			hImage.dwID = nil
			hImage:FromUITex("ui\\Image\\UICommon\\CommonPanel4.UITex", 73)
		else
			HM_TargetDir.SetHeadImage(hImage, tar)
		end
		hImage:Show()
	else
		hImage:Hide()
		hBox:SetObjectIcon(dwIcon)
		hBox:Show()
		if HM_TargetMon then
			if HM_TargetMon.bBoxEvent2 then
				hBox:RegisterEvent(768)
			else
				hBox:ClearEvent()
			end
		end
	end
	-- update state
	if not szText or not HM_Target.bDirText then
		szText = ""
	end
	frame:Lookup("", "Text_State"):SetText(szText)
end

-- create
HM_TargetDir.OnFrameCreate = function()
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("UI_SCALED")
	HM_TargetDir.UpdateAnchor(this)
	UpdateCustomModeWindow(this, _L["HM target direction"])
	-- update box
	box = this:Lookup("", "Box_Buff")
	box:SetOverTextFontScheme(0, 15)
	box:SetOverTextFontScheme(1, 16)
	box:SetOverTextPosition(1, 3)
	box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
	box.OnItemMouseEnter = function()
		this:SetObjectMouseOver(1)
		if this.dwID then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputBuffTip(this.dwOwner, this.dwID, this.nLevel, 1, false, 0, { x, y, w, h })
		end
	end
	box.OnItemMouseLeave = function()
		this:SetObjectMouseOver(0)
		HideTip()
	end
end

-- breathe
HM_TargetDir.OnFrameBreathe = function()
	local me = GetClientPlayer()
	if not me then return end
	local tar = GetTargetHandle(me.GetTarget())
	if not tar or tar.dwID == me.dwID then
		HM_TargetDir.dwLastID = nil
		return this:Lookup("", ""):Hide()
	end
	-- update dir image
	local hImage = this:Lookup("", "Image_Dir")
	if tar.dwID == me.dwID then
		hImage:Hide()
	else
		hImage:Show()
		if HM_TargetDir.dwLastID ~= tar.dwID then
			local nFrame = 5
			if me.IsInParty() and HM.IsParty(tar.dwID) then
				nFrame = 6
			elseif IsEnemy(me.dwID, tar.dwID) then
				nFrame = 4
			elseif IsAlly(me.dwID, tar.dwID) then
				nFrame = 7
			end
			hImage:SetFrame(nFrame)
			HM_TargetDir.dwLastID = tar.dwID
		end
		if tar.nX == me.nX then
			hImage:SetRotate(0)
		else
			local dwRad1 = math.atan((tar.nY - me.nY) / (tar.nX - me.nX))
			if dwRad1 < 0 then
				dwRad1 = dwRad1 + math.pi
			end
			if tar.nY < me.nY then
				dwRad1 = math.pi + dwRad1
			end
			local dwRad2 = me.nFaceDirection / 128 * math.pi
			hImage:SetRotate(1.5 * math.pi + dwRad2 - dwRad1)
		end
	end
	-- update distance
	local hDist = this:Lookup("", "Text_Distance")
	if HM_Target.bDirDist then
		local dwDis = HM.GetDistance(tar)
		if dwDis > 100 then
			hDist:SetText(_L("%d feet", dwDis))
		else
			hDist:SetText(_L("%.1f feet", dwDis))
		end
		hDist:Show()
	else
		hDist:Hide()
	end
	-- update state
	HM_TargetDir.UpdateState(this, tar)
	-- show
	this:Lookup("", ""):Show()
end

-- drag
HM_TargetDir.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_Target.tDirAnchor = GetFrameAnchor(this)
end

-- event
HM_TargetDir.OnEvent = function(event)
	if event == "ON_ENTER_CUSTOM_UI_MODE" or event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this)
	elseif event == "UI_SCALED" then
		HM_TargetDir.UpdateAnchor(this)
	end
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
_HM_Target.PS = {}

-- init panel
_HM_Target.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- target
	ui:Append("Text", { txt = _L["Target enhancement"], font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = 28, checked = HM_Target.bEnable })
	:Text(_L["Enable enh (distance/kungfu)"]):Click(function(bChecked)
		HM_Target.bEnable = bChecked
		_HM_Target.bChange = true
	end):Pos_()
	nX = ui:Append("WndCheckBox", { x = nX + 5, y = 28, checked = HM_Target.bEnableTTarget })
	:Text(_L["Enable target target"]):Click(function(bChecked)
		HM_Target.bEnableTTarget = bChecked
		_HM_Target.bChangeTTarget = true
	end):Pos_()
	ui:Append("WndCheckBox", { x = nX + 5, y = 28, checked = HM_Target.bEnableLM })
	:Text(_L["HP/MP"]):Click(function(bChecked)
		HM_Target.bEnableLM= bChecked
	end)
	-- buff size
	local nX2 = nX
	nX = ui:Append("WndCheckBox", { x = 10, y = 56, checked = HM_Target.bAdjustBuff })
	:Text(_L["Adjust buff size"]):Click(function(bChecked)
		HM_Target.bAdjustBuff = bChecked
		ui:Fetch("Combo_Size1"):Enable(bChecked)
		ui:Fetch("Combo_Size2"):Enable(bChecked)
		ui:Fetch("Check_Spark"):Enable(bChecked)
		ui:Fetch("Check_SubDebuff"):Enable(bChecked)
		_HM_Target.RefreshBuff()
	end):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size1", { x = nX, y = 56, w = 60, h = 25 })
	:Enable(HM_Target.bAdjustBuff):Text(tostring(HM_Target.nSizeBuff)):Menu(function()
		local m0 = {}
		for i = 20, 60, 5 do
			table.insert(m0, { szOption = tostring(i), fnAction = function()
				HM_Target.nSizeBuff = i
				ui:Fetch("Combo_Size1"):Text(tostring(i))
				_HM_Target.RefreshBuff()
			end })
		end
		return m0
	end):Pos_()
	nX = ui:Append("Text", { x = nX + 10, y = 54, txt = _L["Target of target"] }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size2", { x = nX, y = 56, w = 60, h = 25 })
	:Enable(HM_Target.bAdjustBuff):Text(tostring(HM_Target.nSizeTTBuff)):Menu(function()
		local m0 = {}
		for i = 20, 60, 5 do
			table.insert(m0, { szOption = tostring(i), fnAction = function()
				HM_Target.nSizeTTBuff = i
				ui:Fetch("Combo_Size2"):Text(tostring(i))
				_HM_Target.RefreshBuff()
			end })
		end
		return m0
	end):Pos_()
	ui:Append("WndCheckBox", "Check_Spark", { x = nX + 5, y = 56, checked = HM_Target.bNoSpark })
	:Text(_L["Disable sparking"]):Click(function(bChecked)
		HM_Target.bNoSpark= bChecked
	end)
	ui:Append("WndCheckBox", "Check_SubDebuff", { x = 10, y = 84, checked = HM_Target.bSubDebuff })
	:Text(_L["Simplify NPC debuff, hide redundant"]):Click(function(bChecked)
		HM_Target.bSubDebuff = bChecked
	end)
	-- line
	ui:Append("Text", { txt = _L["Target connect line"], x = 0, y = 120, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = 148, checked = HM_Target.bConnect })
	:Text(_L["Draw line from target to you"]):Click(function(bChecked)
		HM_Target.bConnect = bChecked
		ui:Fetch("Combo_Conn"):Enable(bChecked)
		ui:Fetch("Check_Foot"):Enable(bChecked)
	end):Pos_()
	ui:Append("WndCheckBox", { x = nX + 20, y = 148, checked = HM_Target.bTTConnect })
	:Text(_L["Draw line from target to target target"]):Click(function(bChecked)
		HM_Target.bTTConnect = bChecked
	end)
	ui:Append("WndComboBox", "Combo_Conn", { x = 14, y = 178, txt = _L["Line setting"] })
	:Menu(_HM_Target.GetConnMenu)
	ui:Append("WndCheckBox", "Check_Foot", { x = nX + 20, y = 178, checked = HM_Target.bConnFoot })
	:Text(_L["Show line on foot"]):Click(function(bChecked)
		HM_Target.bConnFoot = bChecked
	end)
	-- action bar
	ui:Append("Text", { txt = _L["Prepared skill enhancement"], x = 0, y = 214, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 242, checked = HM_Target.bEnableChannel })
	:Text(_L["Show channel skill of target/target target"]):Click(function(bChecked)
		HM_Target.bEnableChannel = bChecked
	end)
	ui:Append("WndCheckBox", { x = 10, y = 270, checked = HM_Target.bEnableBreak })
	:Text(_L["Show non-broken as gray text"]):Click(function(bChecked)
		HM_Target.bEnableBreak = bChecked
	end)
	ui:Append("WndCheckBox", { x = nX + 30, y = 270, checked = HM_Target.bAdjustBar })
	:Text(_L["Adjust preparing bar to above of buff"]):Click(function(bChecked)
		HM_Target.bAdjustBar = bChecked
	end)
	-- target dir
	ui:Append("Text", { txt = _L["Target direction (adjust position by SHIFT-U)"], x = 0, y = 306, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = 334, checked = HM_Target.bDirection })
	:Text(_L["Show direction"]):Click(function(bChecked)
		HM_Target.bDirection = bChecked
		ui:Fetch("Check_DirDist"):Enable(bChecked)
		ui:Fetch("Check_DirText"):Enable(bChecked)
		ui:Fetch("Check_DirBuff"):Enable(bChecked)
		ui:Fetch("Check_DirLarge"):Enable(bChecked)
		_HM_Target.UpdateDir()
	end):Pos_()
	nX = ui:Append("WndCheckBox", "Check_DirText", { x = nX + 10, y = 334, checked = HM_Target.bDirText })
	:Text(_L["Status"]):Enable(HM_Target.bDirection):Click(function(bChecked)
		HM_Target.bDirText = bChecked
	end):Pos_()
	nX = ui:Append("WndCheckBox", "Check_DirDist", { x = nX + 10, y = 334, checked = HM_Target.bDirDist })
	:Text(_L["Distance"]):Enable(HM_Target.bDirection):Click(function(bChecked)
		HM_Target.bDirDist = bChecked
	end):Pos_()
	nX = ui:Append("WndCheckBox", "Check_DirBuff", { x = nX + 10, y = 334, checked = HM_Target.bDirBuff })
	:Text("BUFF"):Enable(HM_Target.bDirection and HM_TargetMon ~= nil):Click(function(bChecked)
		HM_Target.bDirBuff = bChecked
	end):Pos_()
	ui:Append("WndCheckBox", "Check_DirLarge", { x = nX + 10, y = 334, checked = HM_Target.bDirLarge })
	:Text(_L["Larger icon"]):Enable(HM_Target.bDirection):Click(function(bChecked)
		HM_Target.bDirLarge = bChecked
		HM_TargetDir.AdjustSize()
	end)
end

-- check conflict
_HM_Target.PS.OnConflictCheck = function()
	-- copatiable with box
	if TargetLine and HM_Target.bConnect then
		TargetLine.btargetline = false
	end
	if TargetEx then
		if HM_Target.bAdjustBar then
			TargetEx.UpdateAction = function() end
		end
		if HM_Target.bAdjustBuff then
			TargetEx.bAdjustTargetBuff = false
			TargetEx.bAdjustTTargetBuff = false
		end
		if HM_Target.bEnable or HM_Target.bEnableTTarget then
			TargetEx.UpdateName = function() end
		end
		TargetEx.OnManaUpdate = function() end
		if HM_Target.bDirection and TargetMark then
			TargetMark.bOn = false
		end
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("CUSTOM_DATA_LOADED", function()
	if arg0 == "Role" then
		_HM_Target.InitNoBroken()
		_HM_Target.UpdateDir()
		-- show bufftime of 374
		local buff = Table_GetBuff(374, 1)
		if buff then
			buff.bShowTime = 1
		end
	end
end)
HM.BreatheCall("HM_Target", function()
	_HM_Target.AddBreathe(Station.Lookup("Normal/Target"))
	_HM_Target.AddBreathe(Station.Lookup("Normal/TargetTarget"), true)
end)

-- add to HM panel
HM.RegisterPanel(_L["Target enhancement"], 303, _L["Target"], _HM_Target.PS)

-- open target window
local frame = Station.Lookup("Lowest/HM_Target")
if frame then Wnd.CloseWindow(frame) end
_HM_Target.frame = Wnd.OpenWindow(_HM_Target.szIniFile, "HM_Target")

-- public api
HM_Target.GetSkillChannelState = _HM_Target.GetSkillChannelState
