--
-- 海鳗插件：纯阳气场、唐门机关范围及归属显示
--

HM_Area = {
	bQichang = true,			-- 显示纯阳气场
	bJiguan = true,			-- 显示唐门机关
	bShowName = true,	-- 显示头顶名称
	bBigTaiji = true,			-- 11 尺生太极
	nAlpha = 40,				-- 显示效果的不透明度（越大越浓）
	nMaxNum = 10,			-- 最多画出范围的个数
	tColor = {},
	tHide = {
		[2] = {
			[15959] = true,	-- 默认不显示别人的飞星
		},
		[3] = {
			[15959] = true,	-- 默认不显示别人的飞星
		},
		[4] = {
			[0] = true,			-- 默认不显示任何其它人的气场、机关
		},
	},
}
HM.RegisterCustomData("HM_Area")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Area = {
	nMinDelay = 500,	-- 气场释放和出现的最小时差，单位毫秒
	nMaxDelay = 1400,	-- 气场释放和出现的最大时差，单位毫秒
	szIniFile = "interface\\HM\\ui\\HM_Area.ini",
	tList = {},					-- 显示记录
	tCast = {},				-- 释放记录
}

-- default color
_HM_Area.tDefaultColor = {
	{ 0, 255, 0 },		-- 1 绿：团队，自己
	{ 255, 0, 0 },		-- 2 红：敌人
	{ 255, 255, 0 },	-- 3 黄：其它
	{ 0, 255, 255 },	-- 4 青：突出友方
	{ 255, 0, 255 },	-- 5 粉：突出敌方
}

-- relations
_HM_Area.tRelation = { _L["Own"], _L["Team"], _L["Enemy"], _L["Others"] }

-- skill list
_HM_Area.tSkill = {
	{
		dwID = 371,					-- 技能 ID
		dwTemplateID = 4982,	-- 模板 ID
		nLeft = 8,						-- 存在总时间，单位：秒
	}, {
		dwID = 358,
		dwTemplateID = 4976,
		nLeft = 24,
	}, {
		dwID = 357,
		dwTemplateID = 3080,
		nLeft = 24,
	}, {
		dwID = 359,
		dwTemplateID = 4977,
		nLeft = 24,
	}, {
		dwID = 360,
		dwTemplateID = 4978,
		nLeft = 8,
	}, {
		dwID = 361,
		dwTemplateID = 4979,
		nLeft = 24,
	}, {
		dwID = 362,
		dwTemplateID = 4980,
		nLeft = 24,
	}, {
		dwID = 363,
		dwTemplateID = 4981,
		nLeft = 24,
	}, {
	}, {
		dwID = 3103,
		dwTemplateID = 15959,
		nLeft = 30,
	}, {
		dwID = 3108,
		dwTemplateID = 15994,
		nLeft = 16,
	}, {
		dwID = 3107,
		dwTemplateID = 15999,
		nLeft = 30,
	}, {
		dwID = 3111,
		dwTemplateID = 16000,
		nLeft = 60,
	}, {
		dwID = 3370,
		dwTemplateID = 16177,
		tOther = { [3368] = 16175, [3369] = 16176 },
		nLeft = 10,
	}
}

-- sysmsg
_HM_Area.Sysmsg = function(szMsg) HM.Sysmsg(szMsg, _L["HM_Area"]) end

-- debug
_HM_Area.Debug = function(szMsg) HM.Debug2(szMsg, _L["HM_Area"]) end

-- get relation by caster
_HM_Area.GetRelation = function(dwCaster)
	if dwCaster ~= 0 then
		local myID = GetClientPlayer().dwID
		if myID == dwCaster then
			return 1
		elseif HM.IsParty(dwCaster) then
			return 2
		elseif IsEnemy(myID, dwCaster) then
			return 3
		end
	end
	return 4
end

-- get template id by skill
_HM_Area.GetTemplateID = function(dwID)
	for _, v in ipairs(_HM_Area.tSkill) do
		if v.dwID == dwID then
			return v.dwTemplateID
		elseif v.tOther then
			for kk, vv in pairs(v.tOther) do
				if kk == dwID then
					return vv
				end
			end
		end
	end
end

-- get template name
_HM_Area.GetTemplateName = function(dwTemplateID)
	for _, v in ipairs(_HM_Area.tSkill) do
		if v.dwTemplateID == dwTemplateID then
			return HM.GetSkillName(v.dwID)
		end
	end
end

-- check hide for template
_HM_Area.CheckTemplateID = function(dwTemplateID)
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		dwTemplateID = 16177
	end
	if dwTemplateID == 16177 or dwTemplateID == 15959
		or dwTemplateID == 15994 or dwTemplateID == 15999 or dwTemplateID == 16000
	then
		return HM_Area.bJiguan
	else
		for _, v in ipairs(_HM_Area.tSkill) do
			if v.dwTemplateID == dwTemplateID then
				return HM_Area.bQichang
			end
		end
		return false
	end
end

-- get total left time by template
_HM_Area.GetTotalLeft = function(dwTemplateID)
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		return 120
	end
	for _, v in ipairs(_HM_Area.tSkill) do
		if v.dwTemplateID == dwTemplateID then
			return v.nLeft
		end
	end
	return 0
end

-- get radius by template
_HM_Area.GetAreaRadius = function(dwTemplateID)
	if dwTemplateID == 4982 then			-- 镇山河
		return 256
	elseif dwTemplateID == 15959 then	-- 飞星
		return 2240
	elseif dwTemplateID == 15994 then	-- 天绝地灭
		return 384
	elseif dwTemplateID == 16174 then	-- 机关底坐
		return 0
	elseif dwTemplateID == 16000 then	-- 暗藏杀机
		return 384
	elseif dwTemplateID == 16177 then	-- 毒刹
		return 640
	elseif dwTemplateID == 16176 then	-- 重弩
		return 1600
	elseif dwTemplateID == 16175 then	-- 连弩
		return 1600
	end
	return 640
end

-- check hide by relation, template ...
_HM_Area.GetHide = function(nRelation, dwTemplateID, bSelf)
	dwTemplateID = dwTemplateID or 0
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		dwTemplateID = 16177
	end
	local hide = HM_Area.tHide[nRelation]
	if hide and ((not bSelf and hide[0]) or hide[dwTemplateID]) then
		return true
	end
	return false
end

-- set to hide
_HM_Area.SetHide = function(nRelation, dwTemplateID, bHide)
	dwTemplateID = dwTemplateID or 0
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		dwTemplateID = 16177
	end
	if not HM_Area.tHide[nRelation] then
		HM_Area.tHide[nRelation] = {}
	end
	HM_Area.tHide[nRelation][dwTemplateID] = bHide
end

-- get color, return (r, g, b)
_HM_Area.GetColor = function(nRelation, dwTemplateID)
	local color, default = HM_Area.tColor[nRelation], _HM_Area.tDefaultColor
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		dwTemplateID = 16177
	end
	if not color or not color[dwTemplateID] then
		if nRelation == 1 or nRelation == 2 then
			if dwTemplateID == 4976  or dwTemplateID == 16177
				or dwTemplateID == 15959 or dwTemplateID == 15994
				or dwTemplateID == 15999 or dwTemplateID == 16000
			then
				return default[4]
			else
				return default[1]
			end
		elseif nRelation == 3 then
			if dwTemplateID == 4976  or dwTemplateID == 16177
				or dwTemplateID == 15959 or dwTemplateID == 15994
				or dwTemplateID == 15999 or dwTemplateID == 16000
			then
				return default[5]
			else
				return default[2]
			end
		else
			return default[3]
		end
	else
		return color[dwTemplateID]
	end
end

-- set color
_HM_Area.SetColor = function(nRelation, dwTemplateID, r, g, b)
	if dwTemplateID == 16175 or dwTemplateID == 16176 then
		dwTemplateID = 16177
	end
	if not HM_Area.tColor[nRelation] then
		HM_Area.tColor[nRelation] = {}
	end
	HM_Area.tColor[nRelation][dwTemplateID] = { r, g, b }
end

-------------------------------------
-- 画范围外观
-------------------------------------

-- show name
_HM_Area.ShowName = function(tar)
	local data = _HM_Area.tList[tar.dwID]
	if not HM_Area.bShowName then
		if data.label then
			data.label:Hide()
		end
		return
	end
	if not data.label then
		data.label = _HM_Area.pLabel:New()
		data.label:SetText(tar.szName)
	end
	-- adjust text & color
	data.label:SetFontColor(unpack(_HM_Area.GetColor(_HM_Area.GetRelation(data.dwCaster), tar.dwTemplateID)))
	if data.dwCaster ~= 0 then
		local szText = tar.szName
		local player = GetPlayer(data.dwCaster)
		if player then
			data.szName = data.szName or _HM_Area.GetTemplateName(tar.dwTemplateID) or szText
			szText = player.szName .. _L["-"] .. data.szName
		end
		if data.nLeft > 0 and data.dwTime ~= 0 then
			szText = szText .. _L["-"] .. math.ceil((data.nLeft + data.dwTime - GetTime())/1000)
		end
		data.label:SetText(szText)
	end
	-- adjust pos
	HM.ApplyTopPoint(function(nX, nY)
		if not nX then
			data.label:Hide()
		else
			local nW, nH = data.label:GetSize()
			data.label:SetAbsPos(nX - math.ceil(nW/2), nY - math.ceil(nH/2))
			data.label:Show()
		end
	end, tar)
end

-- draw circle (N * shadow)
_HM_Area.DrawCircle = function(shape, tar, col, nRadius, nAlpha, nThick)
	if not shape.tCircle then
		-- count circle shadows
		shape.tCircle = {}
		nRadius = nRadius or 640
		nThick = nThick or math.ceil(6 * nRadius / 640)
		local dwMaxRad = math.pi + math.pi
		local dwCurRad, dwStepRad = 0, dwMaxRad / (nRadius / 16)
		repeat
			local sha = _HM_Area.pDraw:New()
			local tRad = {}
			tRad[1] = { nRadius, dwCurRad }
			tRad[2] = { nRadius - nThick, dwCurRad }
			tRad[3] = { nRadius - nThick, dwCurRad + dwStepRad }
			tRad[4] = { nRadius, dwCurRad + dwStepRad }
			sha.tPoint = {}
			for _, v in ipairs(tRad) do
				nX = tar.nX + math.ceil(math.cos(v[2]) * v[1])
				nY = tar.nY + math.ceil(math.sin(v[2]) * v[1])
				table.insert(sha.tPoint, { nX, nY, tar.nZ })
			end
			sha:SetTriangleFan(true)
			table.insert(shape.tCircle, sha)
			dwCurRad = dwCurRad + dwStepRad
		until dwMaxRad <= dwCurRad
	end
	-- draw shadows
	for _, v in ipairs(shape.tCircle) do
		v:ClearTriangleFanPoint()
		for _, vv in ipairs(v.tPoint) do
			HM.ApplyScreenPoint(function(nX, nY)
				if nX then
					v:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], nAlpha)
				end
			end, vv[1], vv[2], tar.nZ)
		end
		v:Show()
	end
end

-- draw shape (1 shadow)
_HM_Area.DrawCake = function(shape, tar, col, nRadius, nAlpha, bCircle)
	if not shape.tPoint then
		shape:SetTriangleFan(true)
		shape.tPoint = {}
		nRadius = nRadius or 640
		local dwMaxRad = math.pi + math.pi
		local dwStepRad = dwMaxRad / (nRadius / 16)
		local dwCurRad = 0 - dwStepRad
		repeat
			dwCurRad = dwCurRad + dwStepRad
			if dwCurRad > dwMaxRad then
				dwCurRad = dwMaxRad
			end
			nX = tar.nX + math.ceil(math.cos(dwCurRad) * nRadius)
			nY = tar.nY + math.ceil(math.sin(dwCurRad) * nRadius)
			table.insert(shape.tPoint, { nX, nY })
		until dwMaxRad <= dwCurRad
	end
	-- center point
	HM.ApplyScreenPoint(function(nX, nY)
		if not nX then
			bCircle = false
		end
		-- update circle
		if bCircle then
			nAlpha = math.ceil(nAlpha / 3)
		elseif shape.tCircle then
			for _, v in ipairs(shape.tCircle) do
				v:Hide()
			end
		end
		if not nX then
			return shape:Hide()
		end
		-- update points
		shape:ClearTriangleFanPoint()
		shape:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], 0)
		for k, v in ipairs(shape.tPoint) do
			HM.ApplyScreenPoint(function(nX, nY)
				if nX then
					shape:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], nAlpha)
				end
			end, v[1], v[2], tar.nZ)
		end
		shape:Show()
	end, tar.nX, tar.nY,tar.nZ)
end

-- draw area (draw shape only for far objects)
_HM_Area.DrawArea = function(tar)
	local data = _HM_Area.tList[tar.dwID]
	local color =  _HM_Area.GetColor(_HM_Area.GetRelation(data.dwCaster), tar.dwTemplateID)
	local nAlpha, nRadius = HM_Area.nAlpha, _HM_Area.GetAreaRadius(tar.dwTemplateID)
	local nDistance = HM.GetDistance(tar)
	if tar.dwTemplateID == 4982 then
		nAlpha = math.ceil(nAlpha * 1.5)
	elseif tar.dwTemplateID == 4976 and HM_Area.bBigTaiji then
		nRadius = nRadius + 64
	end
	-- draw cake & circle
	if not data.shape then
		data.shape = _HM_Area.pDraw:New()
	end
	if nRadius >= 256 and nDistance < 35 then
		_HM_Area.DrawCake(data.shape, tar, color, nRadius, nAlpha, true)
		_HM_Area.DrawCircle(data.shape, tar, color, nRadius, nAlpha * 1.3)
	else
		_HM_Area.DrawCake(data.shape, tar, color, nRadius, nAlpha, false)
	end
end

-- skill select
_HM_Area.GetSkillMenu = function()
	local m0 = {}
	for nRel, szRel in ipairs(_HM_Area.tRelation) do
		local m1 = { szOption = szRel, bCheck = true, }
		m1.bChecked = not _HM_Area.GetHide(nRel)
		m1.fnAction = function(data, bCheck) _HM_Area.SetHide(nRel, nil, not bCheck) end
		for _, v in ipairs(_HM_Area.tSkill) do
			local m2 = nil
			if not v.dwID then
				m2 = { bDevide = true, }
			else
				m2 = { szOption = HM.GetSkillName(v.dwID), bCheck = true, bColorTable = true, bNotChangeSelfColor = false, }
				m2.bChecked = not _HM_Area.GetHide(nRel, v.dwTemplateID, true)
				m2.rgb = _HM_Area.GetColor(nRel, v.dwTemplateID)
				m2.fnAction = function(data, bCheck) _HM_Area.SetHide(nRel, v.dwTemplateID, not bCheck) end
				m2.fnChangeColor = function(data, r, g, b) _HM_Area.SetColor(nRel, v.dwTemplateID, r, g, b) end
			end
			table.insert(m1, m2)
		end
		table.insert(m0, m1)
	end
	return m0
end

-- add to list
_HM_Area.AddToList = function(tar, dwCaster, dwTime, szEvent)
	local nLeft = _HM_Area.GetTotalLeft(tar.dwTemplateID) * 1000
	_HM_Area.tList[tar.dwID] = { dwCaster = dwCaster, dwTime = dwTime,  nLeft = nLeft, szEvent = szEvent }
end

-- remove record
_HM_Area.RemoveFromList = function(dwID)
	local data = _HM_Area.tList[dwID]
	local nTime = GetTime() - data.dwTime
	if nTime >= data.nLeft then
		if data.label then
			_HM_Area.pLabel:Free(data.label)
		end
		if data.shape then
			if data.shape.tCircle then
				for _, v in ipairs(data.shape.tCircle) do
					v.tPoint = nil
					_HM_Area.pDraw:Free(v)
					--_HM_Area.pDraw:Remove(v)
				end
			end
			data.shape.tCircle = nil
			data.shape.tPoint = nil
			_HM_Area.pDraw:Free(data.shape)
			--_HM_Area.pDraw:Remove(data.shape)
		end
		_HM_Area.tList[dwID] = nil
	else
		if data.label then
			data.label:Hide()
		end
		if data.shape then
			data.shape:Hide()
			if data.shape.tCircle then
				for _, v in ipairs(data.shape.tCircle) do v:Hide() end
			end
		end
	end
end

-------------------------------------
-- 事件处理函数
-------------------------------------
-- skill cast log
_HM_Area.OnSkillCast = function(dwCaster, dwSkillID, dwLevel, szEvent)
	local player = GetPlayer(dwCaster)
	local dwTemplateID = _HM_Area.GetTemplateID(dwSkillID)
	if player and dwTemplateID and _HM_Area.CheckTemplateID(dwTemplateID) then
		table.insert(_HM_Area.tCast, { dwTemplateID = dwTemplateID, dwCaster = dwCaster, dwTime = GetTime(), szEvent = szEvent })
		_HM_Area.Debug("[" .. player.szName .. "] cast [" .. HM.GetSkillName(dwSkillID, dwLevel) .. "#" .. szEvent .. "]")
	end
end

-- npc enter
_HM_Area.OnNpcEnter = function()
	local tar = GetNpc(arg0)
	if not tar or _HM_Area.tList[arg0] or not _HM_Area.CheckTemplateID(tar.dwTemplateID) then
		return
	end
	_HM_Area.Debug("[" .. tar.szName .. "] enter scene")
	-- caster
	local f, dwCaster, dwTime, szEvent = nil, 0, 0, ""
	for k, v in ipairs(_HM_Area.tCast) do
		if v.dwTemplateID == tar.dwTemplateID then
			local nTime = GetTime() - v.dwTime
			_HM_Area.Debug("checking [" .. tar.szName .. "], delay [" .. nTime .. "]")
			if nTime < 3000 and tar.dwEmployer == v.dwCaster then
				f = k
				break
			elseif not f and nTime > _HM_Area.nMinDelay and nTime < _HM_Area.nMaxDelay then
				f = k
			end
		end
	end
	if f ~= nil then
		local v = _HM_Area.tCast[f]
		dwCaster, dwTime, szEvent = v.dwCaster, v.dwTime, v.szEvent
		table.remove(_HM_Area.tCast, f)
		_HM_Area.Debug("matched [" .. tar.szName .. "] casted by [#" .. dwCaster .. "]")
	end
	-- purge
	if dwCaster == 0 then
		local nTime = GetTime()
		for k, v in ipairs(_HM_Area.tCast) do
			if (nTime - v.dwTime) > 3000 then
				table.remove(_HM_Area.tCast, k)
			end
		end
		-- new version
		if tar.dwEmployer and tar.dwEmployer ~= 0 then
			dwCaster = tar.dwEmployer
		end
	end
	-- check hide (force to record my target)
	local _, tarID = GetClientPlayer().GetTarget()
	if (tarID == 0 or tarID ~= dwCaster)
		and _HM_Area.GetHide(_HM_Area.GetRelation(dwCaster), tar.dwTemplateID)
	then
		return _HM_Area.Debug("ignore hidden [" .. tar.szName .. "]")
	end
	_HM_Area.AddToList(tar, dwCaster, dwTime, szEvent)
end

-- draw content
_HM_Area.OnRender = function()
	local nCount, nTime = 0, GetTime()
	for k, v in pairs(_HM_Area.tList) do
		local tar = GetNpc(k)
		if not tar or nCount >= HM_Area.nMaxNum
			or not _HM_Area.CheckTemplateID(tar.dwTemplateID)
			or _HM_Area.GetHide(_HM_Area.GetRelation(v.dwCaster), tar.dwTemplateID)
		then
			if not v.bHide or (nTime - v.dwTime) >= v.nLeft then
				v.bHide = true
				_HM_Area.RemoveFromList(k)
			end
		else
			v.bHide = false
			nCount = nCount + 1
			_HM_Area.DrawArea(tar)
			_HM_Area.ShowName(tar)
		end
	end
end

-------------------------------------
-- 窗口函数
-------------------------------------
-- create
function HM_Area.OnFrameCreate()
	-- label pool
	local hnd = this:Lookup("", "Handle_Label")
	local xml = "<text>w=10 h=36 halign=1 valign=1 alpha=185 font=40 lockshowhide=1</text>"
	_HM_Area.pLabel = HM.HandlePool(hnd, xml)
	-- draw pool
	local hnd = this:Lookup("", "Handle_Draw")
	local xml = "<shadow>w=1 h=1 lockshowhide=1</shadow>"
	_HM_Area.pDraw = HM.HandlePool(hnd, xml)
	-- events
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
end

-- event
function HM_Area.OnEvent(event)
	if event == "SYS_MSG" then
		if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
			_HM_Area.OnSkillCast(arg1, arg4, arg5, arg0)
		elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
			_HM_Area.OnSkillCast(arg1, arg5, arg6, arg0)
		end
	elseif event == "NPC_ENTER_SCENE" then
		_HM_Area.OnNpcEnter()
	elseif event == "RENDER_FRAME_UPDATE" then
		_HM_Area.OnRender()
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Area.PS = {}

-- init
_HM_Area.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	-- feature
	ui:Append("Text", { txt = _L["Options"], font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Display gas field range of CY"], x = 10, y = 28, checked = HM_Area.bQichang })
	:Click(function(bChecked)
		HM_Area.bQichang = bChecked
		ui:Fetch("Check_Big"):Enable(bChecked)
	end)
	local nX = ui:Append("WndCheckBox", { txt = _L["Display organ/trap range of TM"], x = 10, y = 56, checked = HM_Area.bJiguan })
	:Click(function(bChecked)
		HM_Area.bJiguan = bChecked
	end):Pos_()
	ui:Append("WndCheckBox", { txt = _L["Show the head name"], x = nX + 10, y = 56, checked = HM_Area.bShowName })
	:Click(function(bChecked)
		HM_Area.bShowName = bChecked
	end)
	ui:Append("WndCheckBox", "Check_Big", { txt = _L["Always display 11 feet range of SHENGTAIJI"], x = 10, y = 84, checked = HM_Area.bBigTaiji })
	:Enable(HM_Area.bQichang):Click(function(bChecked)
		HM_Area.bBigTaiji = bChecked
	end)
	ui:Append("WndComboBox", { txt = _L["Select range type"], x = 12, y = 114 }):Menu(_HM_Area.GetSkillMenu)
	-- others
	ui:Append("Text", { txt = _L["Others"], font = 27, x = 0, y = 150 })
	nX = ui:Append("Text", { txt = _L["Maximum display number of ranges"], x = 10, y = 178 }):Pos_()
	ui:Append("WndTrackBar", { x = nX + 5, y = 180, txt = "" })
	:Range(0, 20, 20):Value(HM_Area.nMaxNum):Change(function(nVal) HM_Area.nMaxNum = nVal end)
	nX = ui:Append("Text", { txt = _L["Display transparency of ranges "], x = 10, y = 206 }):Pos_()
	ui:Append("WndTrackBar", { x = nX + 5, y = 208 })
	:Range(0, 100, 50):Value(100 - math.floor(HM_Area.nAlpha/2)):Change(function(nVal)
		HM_Area.nAlpha = 200 - nVal - nVal
	end)
	-- tips
	ui:Append("Text", { txt = _L["Tips"], x = 0, y = 242, font = 27 })
	ui:Append("Text", { txt = _L["Vesting is based on skill cast time, may incorrect when lots of players"], x = 10, y = 270 })
end

-- conflict
_HM_Area.PS.OnConflictCheck = function()
	if QiChang and HM.bQichang then
		QiChang.bEnable = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM panel
HM.RegisterPanel(_L["Gas/Organ range"], 613, nil, _HM_Area.PS)

-- open hidden window
local frame = Station.Lookup("Lowest/HM_Area")
if frame then Wnd.CloseWindow(frame) end
Wnd.OpenWindow(_HM_Area.szIniFile, "HM_Area")
