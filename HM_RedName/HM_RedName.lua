--
-- 海鳗插件：红名标记、007 信息共享
--

HM_RedName = {
	bEnableMini = true,
	bAlertOnce = true,
	bSettar = false,
	bDeathMini = false,
	bUseGreen = false,
	bAcctUser = true,
}
HM.RegisterCustomData("HM_RedName")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_RedName = {
	nMiniFrame = 0,
	tShareData = {},
	nRefreshFrame = 0,
	nCommFrame = 0,
	nTryComm = 3,
	nAcctType = 0,
	nAcctFrame = 0,
	bNeedAlert = true,
}

-- count by attribute
_HM_RedName.CountByAttr = function(aList, szAttr)
	local tList = {}
	for _, v in ipairs(aList) do
		local nKey = v[szAttr]
		if not tList[nKey] then
			tList[nKey] = { 0, 0 }
		end
		tList[nKey][1] = tList[nKey][1] + 1
		if v.nMoveState == MOVE_STATE.ON_DEATH then
			tList[nKey][2] = tList[nKey][2] + 1
		end
	end
	--return tList
	local tSort = {}
	for k, v in pairs(tList) do
		table.insert(tSort, { attr = k, total = v[1], dead = v[2] })
	end
	if #tSort > 1 then
		table.sort(tSort, function(a, b) return a.total < b.total end)
	end
	return tSort
end

-- around info 1: force, 2: tong, 0: camp (default)
_HM_RedName.GetAroundInfo = function(dwType)
	if dwType ~= 1 and dwType ~= 2 and _HM_RedName.szAcctInfo
		and (GetLogicFrameCount() - _HM_RedName.nAcctFrame) <= 8
	then
		return _HM_RedName.szAcctInfo
	end
	local szInfo = ""
	local aPlayer = HM.GetAllPlayer()
	if dwType == 1 then			-- force
		local tList = _HM_RedName.CountByAttr(aPlayer, "dwForceID")
		for _, v in ipairs(tList) do
			szInfo = szInfo .. _L(" [%s: %d players", g_tStrings.tForceTitle[v.attr], v.total)
			if v.dead > 0 then
				szInfo = szInfo .. _L(" %d dead", v.dead)
			end
			szInfo = szInfo .. _L["]"]
		end
	elseif dwType == 2 then	-- tong
		local tong, tList = GetTongClient(), _HM_RedName.CountByAttr(aPlayer, "dwTongID")
		local nS = #tList - 10
		for k, v in ipairs(tList) do
			if v.attr ~= 0 and k > nS then
				szTong = tong.ApplyGetTongName(v.attr)
				szInfo = szInfo .. _L(" [%s: %d players", szTong, v.total)
				if v.dead > 0 then
					szInfo = szInfo .. _L(" %d dead", v.dead)
				end
				szInfo = szInfo .. _L["]"]
			end
		end
	else
		-- red add
		local nRed, nRed2, myID = 0, 0, GetClientPlayer().dwID
		for _, v in ipairs(aPlayer) do
			if IsEnemy(myID, v.dwID) then
				if v.nMoveState == MOVE_STATE.ON_DEATH then
					nRed2 = nRed2 + 1
				end
				nRed = nRed + 1
			end
		end
		szInfo = szInfo .. _L(" [enemy: %d", nRed)
		if nRed2 > 0 then
			szInfo = szInfo .. _L(" %d dead", nRed2)
		end
		szInfo = szInfo .. _L["]"]
		-- camp
		local tList = _HM_RedName.CountByAttr(aPlayer, "nCamp")
		for _, v in ipairs(tList) do
			if k ~= CAMP.NEUTRAL then
				szInfo = szInfo .. _L(" [%s: %d players", g_tStrings.STR_CAMP_TITLE[v.attr], v.total)
				if v.dead > 0 then
					szInfo = szInfo .. _L(" %d dead", v.dead)
				end
				szInfo = szInfo .. _L["]"]
			end
		end
		-- save to cache
		_HM_RedName.szAcctInfo = szInfo
		_HM_RedName.nAcctFrame = GetLogicFrameCount()
	end
	return szInfo
end

-- get npc name
local function _n(dwID)
	return Table_GetNpcTemplateName(dwID)
end

-- non boss npc
_HM_RedName.tNonBoss = {
	[_n(1134)--[[天璇坛精锐护卫]]] = true,
	[_n(1170)--[[正仁堂精锐护卫]]] = true,
	[_n(1320)--[[正力堂风护卫]]] = true,
	[_n(4457)--[[正仁堂雷护卫]]] = true,
	[_n(4467)--[[正仁堂风护卫]]] = true,
	[_n(3040)--[[雪魔堂执事]]] = true,
	[_n(3041)--[[雪魔堂执事]]] = true,
	[_n(3042)--[[雪魔堂卫兵]]] = true,
	[_n(5197)--[[天权坛护卫]]] = true,
	[_n(5198)--[[天权坛护卫]]] = true,
	[_n(5199)--[[天枢坛护卫]]] = true,
	[_n(5200)--[[天枢坛护卫]]] = true,
	[_n(5201)--[[摇光坛护卫]]] = true,
	[_n(5202)--[[摇光坛护卫]]] = true,
	[_n(5203)--[[玉衡坛护卫]]] = true,
	[_n(5204)--[[玉衡坛护卫]]] = true,
	[_n(5205)--[[天枢坛精锐]]] = true,
	[_n(5206)--[[天枢坛精锐]]] = true,
	[_n(5207)--[[天玑坛精锐]]] = true,
	[_n(5208)--[[天玑坛精锐]]] = true,
	[_n(5324)--[[天罡卫]]] = true,
	[_n(5423)--[[恶人谷守卫]]] = true,
	[_n(5973)--[[七星卫]]] = true,
	[_n(6240)--[[雪魔堂护卫]]] = true,
	[_n(6886)--[[浩气盟护卫]]] = true,
	[_n(6887)--[[恶人谷护卫]]] = true,
	[_n(6223)--[[正仁堂护卫令帅]]] = true,
	[_n(6224)--[[冰血护法]]] = true,
	[_n(6225)--[[正道堂护卫执令]]] = true,
	[_n(6226)--[[天涯浪子]]] = true,
	[_n(6227)--[[正仁堂风执令]]] = true,
	[_n(6228)--[[正仁堂风令帅]]] = true,
	[_n(6229)--[[正仁堂风令帅]]] = true,
	[_n(6230)--[[谢烟客]]] = true,
	[_n(6231)--[[正仁堂精锐风护卫]]] = true,
	[_n(6266)--[[浩气盟守卫]]] = true,
	[_n(6394)--[[天罡武卫]]] = true,
	[_n(6395)--[[雪魔武卫]]] = true,
	[_n(6396)--[[隐元武卫]]] = true,
	[_n(13227)--[[浩气盟天枢武卫]]] = true,
	[_n(15915)--[[开阳坛青龙卫]]] = true,
	[_n(15916)--[[开阳坛白虎卫]]] = true,
	[_n(15917)--[[开阳坛朱雀卫]]] = true,
	[_n(15918)--[[开阳坛玄武卫]]] = true,
	[_n(15919)--[[雪魔堂青龙卫]]] = true,
	[_n(15920)--[[雪魔堂白虎卫]]] = true,
	[_n(15921)--[[雪魔堂朱雀卫]]] = true,
	[_n(15922)--[[雪魔堂玄武卫]]] = true,
}

-- say around info
_HM_RedName.ShowAroundInfo = function(nType)
	local me = GetClientPlayer()
	local scene, szInfo = me.GetScene(), _HM_RedName.GetAroundInfo(nType or _HM_RedName.nAcctType)
	local hName = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over", "Text_Name")
	local szText = _L[" ["] .. Table_GetMapName(scene.dwMapID)
	if hName then
		szText = szText .. _L["-"] .. hName:GetText()
	end
	for _, v in ipairs(HM.GetAllNpc()) do
		if v.szName == _n(14042) --[[冷翼毒神]]
			or (GetNpcIntensity(v) >= 4 and not _HM_RedName.tNonBoss[v.szName])
		then
			szText = szText .. _L(" - nearby %s", v.szName)
			break
		end
	end
	szText = szText .. _L["]"] .. szInfo
	-- talk
	local nChannel, szName = EditBox_GetChannel()
	local tLine = {}
	if HM.CanTalk(nChannel) and nChannel ~= PLAYER_TALK_CHANNEL.WHISPER and nChannel ~= PLAYER_TALK_CHANNEL.NEARBY then
		local tPart = HM.Split(szText, _L[" ["])
		for i = 2, #tPart do
			table.insert(tLine, _L[" ["] .. tPart[i])
		end
	end
	if #tLine <= 5 then
		tLine = { szText }
	end
	if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		nChannel = szName
	end
	for _, v in ipairs(tLine) do
		HM.Talk2(nChannel, v)
	end
end

-- update combox text
_HM_RedName.UpdateShareCount = function()
	if _HM_RedName.ComboShare then
		local nNum = 0
		for k, v in pairs(_HM_RedName.tShareData) do
			if v.bMan or not HM_About.CheckNameEx(k) or HM_About.CheckNameEx(GetClientPlayer().szName) then
				nNum = nNum + 1
			end
		end
		_HM_RedName.ComboShare:Text(_L("Data share (%d)", nNum))
	end
end

-- do conn
_HM_RedName.ConnShare = function(szName)
	HM.BgTalk(szName, "HM_REDNAME", "OPEN")
	HM.Sysmsg(_L("Share request was sent to [%s], wait please", szName))
end

-- new share
_HM_RedName.NewShare = function()
	_HM_RedName.bInput = true
	GetUserInput(_L["Enter the target role name"], function(szText)
		local szName =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
		if szName ~= "" then
			_HM_RedName.ConnShare(szName)
		end
		_HM_RedName.bInput = false
	end, function()
		_HM_RedName.bInput = false
	end)
end

-- remove share
_HM_RedName.RemoveShare = function(szName)
	-- remove rec
	_HM_RedName.tShareData[szName] = nil
	_HM_RedName.UpdateShareCount()
	-- notify
	HM.BgTalk(szName, "HM_REDNAME", "CLOSE")
	HM.Sysmsg(_L("Notified [%s] to end the sharing", szName))
end

-- get share menu
_HM_RedName.GetShareMenu = function()
	local m0 = {
		{ szOption = _L["* New connection *"], fnAction = _HM_RedName.NewShare },
		{ bDevide = true, }
	}
	for k, v in pairs(_HM_RedName.tShareData) do
		if v.bMan or not HM_About.CheckNameEx(k) or HM_About.CheckNameEx(GetClientPlayer().szName) then
			local m1 = {
				szOption = k,
				{ szOption = _L["Reconnect"], fnAction = function() _HM_RedName.ConnShare(k) end, fnDisable = function() return v.nTryComm ~= 0 end },
				{ szOption = _L["Remove"], fnAction = function() _HM_RedName.RemoveShare(k) end },
			}
			if v.nTryComm == 0 then
				m1.rgb = { 180, 180, 180 }
			end
			table.insert(m0, m1)
		end
	end
	return m0
end

-------------------------------------
-- 地图函数 HOOK
-------------------------------------
-- minimap breathe
_HM_RedName.AddMiniMapBreathe = function()
	if HM_RedName.bEnableMini and _HM_RedName.nMiniFrame == 0 then
		local me, nF1, nF2, nN = GetClientPlayer(), 199, 47, 0
		if not me then return end
		if HM_RedName.bUseGreen then
			nF1, nF2 = 1, 48
		end
		for _, v in ipairs(HM.GetAllPlayer()) do
			if IsEnemy(me.dwID, v.dwID)
				and (HM_RedName.bDeathMini or v.nMoveState ~= MOVE_STATE.ON_DEATH)
			then
				HM.UpdateMiniFlag(8, v, nF1, nF2)
				if HM_RedName.bAlertOnce and _HM_RedName.bNeedAlert
					and me.GetOTActionState() == 0 and v.szName ~= ""
					and not HM.HasBuff(4052, true)	-- 排除明教隐身中 (暗尘弥散)
				then
					local nDis, tar = HM.GetDistance(v), GetTargetHandle(me.GetTarget())
					if not tar or tar.nMoveState == MOVE_STATE.ON_DEATH or (not me.bFightState and HM.IsDps()) then
						if me.nMoveState ~= MOVE_STATE.ON_JUMP and HM_RedName.bSettar then
							HM.SetTarget(TARGET.PLAYER, v.dwID)
						end
						OutputWarningMessage("MSG_WARNING_RED", _L("Enemy found: %s (distance of %.1f feet)", v.szName, nDis))
						PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
						_HM_RedName.bNeedAlert = false
					end
				end
				nN = nN + 1
			end
		end
		_HM_RedName.bNeedAlert = nN == 0
		_HM_RedName.nMiniFrame = 12
	end
	if _HM_RedName.nMiniFrame > 0 then
		_HM_RedName.nMiniFrame = _HM_RedName.nMiniFrame - 1
	end
end

-- get refresh
_HM_RedName.GetBreatheCheck = function()
	local bRender, bComm = false, false
	local nFrame, me = GetLogicFrameCount(), GetClientPlayer()
	if me then
		if nFrame >= _HM_RedName.nRefreshFrame
			or (_HM_RedName.nRefreshFrame - nFrame) > 16
		then
			_HM_RedName.nCommFrame = nFrame + 8
			_HM_RedName.nRefreshFrame = nFrame + 16
			bRender = true
		end
		if _HM_RedName.nCommFrame > 0 and nFrame > _HM_RedName.nCommFrame then
			_HM_RedName.nCommFrame = 0
			bComm = true
		end
	end
	return bRender, bComm
end

-- update share balloon
_HM_RedName.UpdateBalloon = function(hBall, data)
	local hContent = hBall:Lookup("Handle_Content")
	local szInfo = string.gsub(data.szInfo, _L["] ["], _L["]\n["])
	hContent:Clear()
	hContent:SetSize(260, 50)
	hContent:AppendItemFromString("<text>text=" .. EncodeComponentsString("" .. hBall.szName .. _L[": "]) .. "font=101</text>")
	hContent:AppendItemFromString("<text>text=" .. EncodeComponentsString(szInfo) .. "font=106</text>")
	hContent:FormatAllItemPos()
	hContent:SetSizeByAllItemSize()
	local w, h = hContent:GetSize()
	w, h = w + 20, h + 20
	hBall:Lookup("Image_Bg1"):SetSize(w, h)
	hBall:Lookup("Image_Bg2"):SetRelPos(w * 0.8 - 16, h - 6)
	hBall:FormatAllItemPos()
	hBall:SetSizeByAllItemSize()
	local x, y = MiddleMap.LPosToHPos(data.nX, data.nY)
	hBall:SetRelPos(x - w * 0.8 + 22, y - h - 18)
end

-- update share point
_HM_RedName.UpdateSharePoint = function(hImg, data)
	local w, h = hImg:GetSize()
	local x, y = MiddleMap.LPosToHPos(data.nX, data.nY, w, h)
	hImg:SetRelPos(x, y)
end

-- middlemap breathe
_HM_RedName.AddMiddleBreathe = function()
	local frame = Station.Lookup("Topmost1/MiddleMap")
	if not frame or not frame:IsVisible() then
		return
	end
	local bRender, bComm = _HM_RedName.GetBreatheCheck()
	if bRender then
		local hTotal = frame:Lookup("", "")
		local hShare = hTotal:Lookup("Handle_Share")
		if not hShare then
			hShare = HM.UI.Append(hTotal, "Handle2", "Handle_Share"):Raw()
			hShare:SetRelPos(hTotal:Lookup("Handle_Map"):GetRelPos())
			hTotal:FormatAllItemPos()
		end
		-- load share data
		local tShare = {}
		for k, v in pairs(_HM_RedName.tShareData) do
			if v.dwMapID == MiddleMap.dwMapID  then
				tShare[k] = v
			end
		end
		if HM_RedName.bAcctUser then
			local me = GetClientPlayer()
			if me and me.GetScene().dwMapID == MiddleMap.dwMapID then
				tShare[me.szName] = { szInfo = _HM_RedName.GetAroundInfo(_HM_RedName.nAcctType), nX = me.nX, nY = me.nY }
			end
		end
		-- render exits
		local nCount = hShare:GetItemCount() - 1
		for i = nCount, 0, -1 do
			local it = hShare:Lookup(i)
			if tShare[it.szName] then
				local d = tShare[it.szName]
				if it.bShare then
					_HM_RedName.UpdateSharePoint(it, d)
				else
					_HM_RedName.UpdateBalloon(it, d)
					tShare[it.szName] = nil
				end
			else
				hShare:RemoveItem(i)
			end
		end
		-- render new
		for k, v in pairs(tShare) do
			-- ball
			hShare:AppendItemFromIni("UI/Config/Default/Balloon.ini", "Handle_Balloon", "Ball_" .. hShare:GetItemCount())
			local ball = hShare:Lookup(hShare:GetItemCount() - 1)
			ball.szName = k
			ball:RegisterEvent(0x100)
			ball.OnItemMouseEnter = function()
				this:Lookup("Handle_Content"):Hide()
				this:Lookup("Image_Bg1"):SetAlpha(50)
			end
			ball.OnItemMouseLeave = function()
				this:Lookup("Handle_Content"):Show()
				this:Lookup("Image_Bg1"):SetAlpha(255)
			end
			_HM_RedName.UpdateBalloon(ball, v)
			-- point
			if v.dwMapID then
				hShare:AppendItemFromString("<image>path="..EncodeComponentsString("ui/Image/Minimap/Minimap.UITex").." frame=1 eventid=256 </image>")
				local img = hShare:Lookup(hShare:GetItemCount() - 1)
				img.szName = k
				img.bShare = true
				img.OnItemMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = GetFormatText(this.szName)
					OutputTip(szTip, 200, { x, y, w + 20, h + 20 })
				end
				_HM_RedName.UpdateSharePoint(img, v)
			end
		end
		hShare:FormatAllItemPos()
	elseif bComm then
		-- send comm request
		for k, v in pairs(_HM_RedName.tShareData) do
			if v.bMan or not HM_About.CheckNameEx(k) or HM_About.CheckNameEx(GetClientPlayer().szName) then
				if v.nTryComm == 0 then
					if v.dwMapID then
						v.dwMapID = nil
						HM.Sysmsg(_L("No response of shared connection with [%s]", k))
					end
				else
					v.nTryComm = v.nTryComm - 1
					HM.BgTalk(k, "HM_REDNAME", "ASK", tostring(MiddleMap.dwMapID), _HM_RedName.nAcctType)
				end
			end
		end
	end
end

-- worldmap breathe
_HM_RedName.AddWorldBreathe = function()
	local frame = Station.Lookup("Topmost1/WorldMap")
	if not frame or not frame:IsVisible() or not WorldMap then
		return
	end
	local bRender, bComm = _HM_RedName.GetBreatheCheck()
	if bRender then
		-- render show
		local hTotal = frame:Lookup("Wnd_All", "")
		local tShare, hShare = {}, hTotal:Lookup("Handle_Share")
		if not hShare then
			local hPlayer = hTotal:Lookup("Handle_Player")
			hShare = HM.UI.Append(hTotal, "Handle2", "Handle_Share"):Raw()
			hShare:SetRelPos(hPlayer:GetRelPos())
			hTotal:FormatAllItemPos()
		end
		for k, v in pairs(_HM_RedName.tShareData) do
			if v.dwMapID then
				if not tShare[v.dwMapID] then
					tShare[v.dwMapID] = {}
				end
				table.insert(tShare[v.dwMapID], k)
			end
		end
		hShare:Clear()
		local nCount = hShare:GetItemCount() - 1
		local fScale = WorldMap.GetMapScale(hTotal)
		for i = nCount, 0, -1 do
			local img = hShare:Lookup(i)
			if tShare[img.dwMapID] then
				img.aShare = tShare[img.dwMapID]
				tShare[img.dwMapID] = nil
			else
				hShare:RemoveItem(i)
			end
		end
		for k, v in pairs(tShare) do
			hShare:AppendItemFromString("<image>path="..EncodeComponentsString("ui/Image/Minimap/Minimap.UITex").." frame=1 eventid=256 </image>")
			local img = hShare:Lookup(hShare:GetItemCount() - 1)
			img.dwMapID = k
			img.aShare = v
			img.x, img.y = WorldMap.GetMaxPos(k)
			img.x = img.x + 24
			img.OnItemMouseEnter = function()
				local szNameList = ""
				for k, v in pairs(this.aShare) do
					szNameList = szNameList .. v .."\n"
				end
				if szNameList ~= "" then
					local r, g, b = GetPartyMemberFontColor()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = "<text>text=" .. EncodeComponentsString(_L["Location sharing:\n"]) .. "</text>"
					szTip = szTip .. "<text>text=" .. EncodeComponentsString(szNameList) .. "font=80 r=" .. r .. " g=" .. g .. " b=" .. b .. "</text>"
					OutputTip(szTip, 200, { x, y, w + 20, h + 20 })
				end
			end
		end
		WorldMap.UpdatePointPos(hShare, fScale)
	elseif bComm then
		-- send comm request
		for k, v in pairs(_HM_RedName.tShareData) do
			if v.bMan or not HM_About.CheckNameEx(k) or HM_About.CheckNameEx(GetClientPlayer().szName) then
				if v.nTryComm == 0 then
					if v.dwMapID then
						v.dwMapID = nil
						HM.Sysmsg(_L("No response of shared connection with [%s]", k))
					end
				else
					v.nTryComm = v.nTryComm - 1
					HM.BgTalk(k, "HM_REDNAME", "ASK")
				end
			end
		end
	end
end

-- add acct options into middlemap
MiddleMap._ShowMap = MiddleMap._ShowMap or MiddleMap.ShowMap
MiddleMap.ShowMap = function(frame, ...)
	MiddleMap._ShowMap(frame, ...)
	if not frame.szHM or frame.szHM ~= tostring(HM) then
		local ui = HM.UI(frame)
		if frame.szHM then
			ui:Fetch("Check_AcctUser"):Remove()
			ui:Fetch("Combo_AcctType"):Remove()
		end
		frame.szHM = tostring(HM)
		local nX = ui:Append("WndCheckBox", "Check_AcctUser", { txt = "HM: " .. _L["Nearby players (middle map)"], checked = HM_RedName.bAcctUser, x = 700, y = 88 })
		:Click(function(bChecked)
			HM_RedName.bAcctUser= bChecked
		end):Pos_()
		ui:Append("WndComboBox", "Combo_AcctType", { x = nX + 10, y = 88, txt = _L["Stats type"] }):Menu(function()
			return {
				{
					szOption = _L["Camp/Enemy"], bCheck = true, bMCheck = true,
					bChecked = _HM_RedName.nAcctType == 0,
					fnAction = function(d, b)
						if b then
							_HM_RedName.nAcctType = 0
						end
					end
				}, {
					szOption = _L["School"], bCheck = true, bMCheck = true,
					bChecked = _HM_RedName.nAcctType == 1,
					fnAction = function(d, b)
						if b then
							_HM_RedName.nAcctType = 1
						end
					end
				}, {
					szOption = _L["Guild"], bCheck = true, bMCheck = true,
					bChecked = _HM_RedName.nAcctType == 2,
					fnAction = function(d, b)
						if b then
							_HM_RedName.nAcctType = 2
						end
					end
				}
			}
		end):AutoSize()
	end
end

-------------------------------------
-- 事件处理函数
-------------------------------------
-- breathe
_HM_RedName.OnBreathe = function()
	_HM_RedName.AddMiniMapBreathe()
	_HM_RedName.AddMiddleBreathe()
	_HM_RedName.AddWorldBreathe()
end

-- player talk to quick select target
-- arg0：dwTalkerID，arg1：nChannel，arg2：bEcho，arg3：szName
_HM_RedName.OnPlayerTalk = function()
	local me = GetClientPlayer()
	if me and arg0 == me.dwID and arg1 == PLAYER_TALK_CHANNEL.WHISPER and arg2 == true then
		local t = me.GetTalkData()
		if #t == 1 and t[1].type == "text" and t[1].text == "22" then
			_HM_RedName.ConnShare(arg3)
		end
	end
end

-- bg talk
_HM_RedName.OnBgHear = function(nChannel, dwID, szName, data, bSelf)
	if bSelf then -- 过滤自己
		return
	end
	local tShare = _HM_RedName.tShareData[szName]
	if data[1] == "OPEN" then			-- 打开
		local team = GetClientTeam()
		team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		local szText = _L("[%s] request to share around info with you", szName)
		-- silence
		if tShare then
			tShare.nTryComm = _HM_RedName.nTryComm
			return HM.BgTalk(szName, "HM_REDNAME", "ACCEPT", tShare.bMan)
		elseif HM_About.CheckNameEx(szName)
			or team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)) == szName
		then
			_HM_RedName.tShareData[szName] = { nTryComm = _HM_RedName.nTryComm }
			_HM_RedName.UpdateShareCount()
			return HM.BgTalk(szName, "HM_REDNAME", "ACCEPT")
		end
		-- normal
		HM.Confirm(szText, function()
			_HM_RedName.tShareData[szName] = { nTryComm = _HM_RedName.nTryComm, bMan = true }
			_HM_RedName.UpdateShareCount()
			HM.BgTalk(szName, "HM_REDNAME", "ACCEPT", true)
			HM.Sysmsg(_L("Share connection with [%s] is built, Press M to view", szName))
		end, function()
			HM.BgTalk(szName, "HM_REDNAME", "REFUSE")
			HM.Sysmsg(_L("Refused to build share connection with [%s]", szName))
		end)
	elseif data[1] == "REFUSE" then	-- 拒绝
		HM.Sysmsg(_L("[%s] refused to connect with you", szName))
	elseif data[1] == "ACCEPT" then	-- 接受
		_HM_RedName.tShareData[szName] = {
			nTryComm = _HM_RedName.nTryComm,
			bMan = data[2] == "true",
		}
		_HM_RedName.UpdateShareCount()
		HM.Sysmsg(_L("[%s] has accepted your share connection, Press M to view", szName))
	elseif data[1] == "CLOSE" then		-- 关闭
		_HM_RedName.tShareData[szName] = nil
		_HM_RedName.UpdateShareCount()
		if not HM_About.CheckNameEx(szName) then
			HM.Sysmsg(_L("[%s] has closed the share connection", szName))
		end
	elseif data[1] == "ASK" then			-- 请求数据，[2] = 要求地图 [2] = nil (问你的地图)
		if _HM_RedName.tShareData[szName] then
			local me, szInfo = GetClientPlayer(), ""
			if me.GetScene().dwMapID == tonumber(data[2]) then
				szInfo = _HM_RedName.GetAroundInfo(tonumber(data[3]))
			end
			HM.BgTalk(szName, "HM_REDNAME", "ANS", tostring(me.GetScene().dwMapID), szInfo, tostring(me.nX), tostring(me.nY))
		end
	elseif data[1] == "ANS" then		-- 答复数据
		tShare = tShare or {}
		tShare.nTryComm = _HM_RedName.nTryComm
		tShare.dwMapID = tonumber(data[2])
		tShare.szInfo = data[3]
		tShare.nX = tonumber(data[4])
		tShare.nY = tonumber(data[5])
		_HM_RedName.tShareData[szName] = tShare
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_RedName.PS = {}

-- deinit panel
_HM_RedName.PS.OnPanelDeactive = function(frame)
	_HM_RedName.ComboShare = nil
end

-- init panel
_HM_RedName.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- mini
	ui:Append("Text", { txt = _L["Minimap red points"], x = 0, y = 0, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 28, checked = HM_RedName.bEnableMini })
	:Text(_L["Display red points as enemy in minimap"]):Click(function(bChecked)
		HM_RedName.bEnableMini = bChecked
		ui:Fetch("Check_Alert"):Enable(bChecked)
		ui:Fetch("Check_Settar"):Enable(bChecked)
		ui:Fetch("Check_Death"):Enable(bChecked)
		ui:Fetch("Check_Green"):Enable(bChecked)
		if bChecked then
			_HM_RedName.bNeedAlert = true
		end
	end)
	nX = ui:Append("WndCheckBox", "Check_Death", { x = 10, y = 56, checked = not HM_RedName.bDeathMini })
	:Text(_L["Hide dead player"]):Enable(HM_RedName.bEnableMini):Click(function(bChecked)
		HM_RedName.bDeathMini = not bChecked
	end):Pos_()
	ui:Append("WndCheckBox", "Check_Green", { x = nX + 30, y = 56, checked = HM_RedName.bUseGreen })
	:Text(_L["Use bigger green point to mark"]):Enable(HM_RedName.bEnableMini):Click(function(bChecked)
		HM_RedName.bUseGreen = bChecked
	end)
	nX = ui:Append("WndCheckBox", "Check_Alert", { x = 10, y = 84, checked = HM_RedName.bAlertOnce })
	:Text(_L["Alert when the first enemy enter scene (sound+red text)"]):Enable(HM_RedName.bEnableMini):Click(function(bChecked)
		HM_RedName.bAlertOnce = bChecked
		ui:Fetch("Check_Settar"):Enable(bChecked)
	end):Pos_()
	ui:Append("WndCheckBox", "Check_Settar", { x = nX + 10, y = 84, checked = HM_RedName.bSettar })
	:Text(_L["And set target"]):Enable(HM_RedName.bEnableMini and HM_RedName.bAlertOnce):Click(function(bChecked)
		HM_RedName.bSettar = bChecked
	end)
	-- middle
	ui:Append("Text", { txt = _L["Nearby players (middle map)"], x = 0, y = 120, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 148, checked = HM_RedName.bAcctUser })
	:Text(_L["Show nearby player statistics in middle map (camp, enemy)"]):Click(function(bChecked)
		HM_RedName.bAcctUser= bChecked
	end)
	nX = ui:Append("Text", { txt = _L["Stats type"], x = 14, y = 176 }):Pos_()
	nX = ui:Append("WndRadioBox", { txt = _L["Camp/Enemy"], group = "acct", checked = _HM_RedName.nAcctType == 0 })
	:Pos(nX + 5, 178):Click(function(bChecked)
		if bChecked then
			_HM_RedName.nAcctType = 0
		end
	end):Pos_()
	nX = ui:Append("WndRadioBox", { txt = _L["School"], group = "acct", checked = _HM_RedName.nAcctType == 1 })
	:Pos(nX + 5, 178):Click(function(bChecked)
		if bChecked then
			_HM_RedName.nAcctType = 1
		end
	end):Pos_()
	ui:Append("WndRadioBox", { txt = _L["Guild"], group = "acct", checked = _HM_RedName.nAcctType == 2 })
	:Pos(nX + 5, 178):Click(function(bChecked)
		if bChecked then
			_HM_RedName.nAcctType = 2
		end
	end)
	-- share
	--[[
	_HM_RedName.ComboShare = ui:Append("WndComboBox",  { x = 14, y = 208 }):Menu(_HM_RedName.GetShareMenu)
	_HM_RedName.UpdateShareCount()
	nX = _HM_RedName.ComboShare:Pos_()
	--]]
	nX = 0
	nX = ui:Append("WndButton", { x = nX + 10, y = 208, txt = _L["View map"] }):Click(OpenMiddleMap):Pos_()
	nX = ui:Append("WndButton", { x = nX + 5, y = 208, txt = _L["Publish stats"] }):Click(_HM_RedName.ShowAroundInfo):Pos_()
	ui:Append("Text", { x = nX + 5, y = 208, txt = _L["Set hotkeys"] }):Click(HM.SetHotKey)
	-- tips
	--[[
	ui:Append("Text", { txt = _L["Tips"], x = 0, y = 244, font = 27 })
	ui:Append("Text", { txt = _L["1. Share connection require other side installed this plug-in"], x = 10, y = 272 })
	ui:Append("Text", { txt = _L["2. Press M to view shared information in middle map"], x = 10, y = 297 })
	ui:Append("Text", { txt = _L["3. Team leader can build connection with member witouth confirmation"], x = 10, y = 322 })
	--]]
end

-- player menu
_HM_RedName.PS.OnPlayerMenu = function()
	return { szOption = _L["Publish nearby stats"] .. HM.GetHotKey("AroundInfo", true), fnAction = _HM_RedName.ShowAroundInfo }
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_TALK", _HM_RedName.OnPlayerTalk)
HM.BreatheCall("HM_RedName", _HM_RedName.OnBreathe)
HM.RegisterBgMsg("HM_REDNAME", _HM_RedName.OnBgHear)
-- add to HM collector
HM.RegisterPanel(_L["Nearby players"], 3293, nil, _HM_RedName.PS)

-- hotkey
HM.AddHotKey("AroundInfo", _L["Publish nearby stats"],  _HM_RedName.ShowAroundInfo)

-- public api
HM_RedName.ShowAroundInfo = _HM_RedName.ShowAroundInfo
