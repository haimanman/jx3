--
-- 海鳗插件：新环境下的部分功能移植代码
-- 2012/06/10
--

-- constant
if not BATTLE_FIELD_NOTIFY_TYPE then
	BATTLE_FIELD_NOTIFY_TYPE = {
		LEAVE_BLACK_LIST = 5,
		IN_BLACK_LIST = 4,
		LEAVE_BATTLE_FIELD = 3,
		JOIN_BATTLE_FIELD = 2,
		QUEUE_INFO = 1,
		INVALID = 0
	}
end

if not ARENA_NOTIFY_TYPE then
	ARENA_NOTIFY_TYPE = {
		IN_BLACK_LIST = 5,
		LEAVE_BLACK_LIST = 4,
		LOG_OUT_ARENA_MAP = 3,
		LOG_IN_ARENA_MAP = 2,
		ARENA_QUEUE_INFO = 1,
	}
end

if not POSE_TYPE then
	POSE_TYPE = {
		SWORD = 1,
		SHIELD = 2,
	}
end

GLOBAL_HEAD_CLIENTPLAYER = GLOBAL_HEAD_CLIENTPLAYER or 0
GLOBAL_HEAD_OTHERPLAYER = GLOBAL_HEAD_OTHERPLAYER or 1
GLOBAL_HEAD_NPC = GLOBAL_HEAD_NPC or 2

GLOBAL_HEAD_LEFE = GLOBAL_HEAD_LEFE or 0
GLOBAL_HEAD_GUILD = GLOBAL_HEAD_GUILD or 1
GLOBAL_HEAD_TITLE = GLOBAL_HEAD_TITLE or 2
GLOBAL_HEAD_NAME = GLOBAL_HEAD_NAME or 3
BigBagPanel_nCount = 6

--帮会仓库界面虚拟一个背包位置
INVENTORY_GUILD_BANK = INVENTORY_GUILD_BANK or INVENTORY_INDEX.TOTAL + 1
INVENTORY_GUILD_PAGE_SIZE = INVENTORY_GUILD_PAGE_SIZE or 100

-- middle map
if not CloseWorldMap then
function CloseWorldMap(bDisableSound)
	local frame = Station.Lookup("Topmost1/WorldMap")
	if frame then
		frame:Hide()
	end
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
	end
	-- FIXME：FireDataAnalysisEvent
end
end
if not IsMiddleMapOpened then
function IsMiddleMapOpened()
	local frame = Station.Lookup("Topmost1/MiddleMap")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end
end
if not OpenMiddleMap then
function OpenMiddleMap(dwMapID, nIndex, bTraffic, bDisableSound)
	CloseWorldMap(true)
	local frame = Station.Lookup("Topmost1/MiddleMap")
	if frame then
		frame:Show()
	else
		frame = Wnd.OpenWindow("MiddleMap")
	end
	MiddleMap.bTraffic = bTraffic
	MiddleMap.ShowMap(frame, dwMapID, nIndex)
	MiddleMap.UpdateTraffic(frame, bTraffic)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	-- FIXME：OnClientAddAchievement
	MiddleMap.nLastAlpha = MiddleMap.nAlpha
end
end

-- target level
if not GetTargetLevelFont then
function GetTargetLevelFont(nLevelDiff)
	local nFont = 16
	if nLevelDiff > 4 then	-- 红
		nFont = 159
	elseif nLevelDiff > 2 then	-- 桔
		nFont = 168
	elseif nLevelDiff > -3 then	-- 黄
		nFont = 16
	elseif nLevelDiff > -6 then	-- 绿
		nFont = 167
	else	-- 灰
		nFont = 169
	end
	return nFont
end
end

-- arena mapt
if not IsInArena then
function IsInArena()
	local me = GetClientPlayer()
	return me ~= nil and me.GetScene().bIsArenaMap
end
end

-- battle map
if not IsInBattleField then
function IsInBattleField()
	local me = GetClientPlayer()
	return me ~= nil and g_tTable.BattleField:Search(me.GetScene().dwMapID) ~= nil
end
end

-- internet exploere
if not OpenInternetExplorer then
function IsInternetExplorerOpened(nIndex)
	local frame = Station.Lookup("Topmost/IE"..nIndex)
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function IE_GetNewIEFramePos()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup("Topmost/IE"..i)
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup("Topmost/IE"..nLastIndex)
		x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

function OpenInternetExplorer(szAddr, bDisableSound)
	local nIndex, nLast = nil, nil
	for i = 1, 10, 1 do
		if not IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
	frame.bIE = true
	frame.nIndex = nIndex

	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup("WebPage_Page")
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end
end

-- dialogue panel
if not IsDialoguePanelOpened then
function IsDialoguePanelOpened()
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end
end

-- doodad loot
if not IsCorpseAndCanLoot then
function IsCorpseAndCanLoot(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return false
	end
	return (doodad.nKind == DOODAD_KIND.CORPSE and doodad.CanLoot(GetClientPlayer().dwID))
end
end

-- get segment name
if not Table_GetSegmentName then
function Table_GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end
end

-- get item name by item
if not GetItemNameByItem then
function GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end
end

-- hotkey panel
function HotkeyPanel_Open(szGroup)
	local frame = Station.Lookup("Topmost/HotkeyPanel")
	if not frame then
		frame = Wnd.OpenWindow("HotkeyPanel")
	elseif not frame:IsVisible() then
		frame:Show()
	end
	if not szGroup then return end
	-- load aKey
	local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
	for k, v in pairs(bindings) do
		if v.szHeader ~= "" then
			if aKey then
				break
			elseif v.szHeader == szGroup then
				aKey = {}
			else
				nI = nI + 1
			end
		end
		if aKey then
			if not v.Hotkey1 then
				v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
			end
			if not v.Hotkey2 then
				v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
			end
			table.insert(aKey, v)
		end
	end
	if not aKey then return end
	local hP = frame:Lookup("", "Handle_List")
	local hI = hP:Lookup(nI)
	if hI.bSel then return end
	-- update list effect
	for i = 0, hP:GetItemCount() - 1 do
		local hB = hP:Lookup(i)
		if hB.bSel then
			hB.bSel = false
			if hB.IsOver then
				hB:Lookup("Image_Sel"):SetAlpha(128)
				hB:Lookup("Image_Sel"):Show()
			else
				hB:Lookup("Image_Sel"):Hide()
			end
		end
	end
	hI.bSel = true
	hI:Lookup("Image_Sel"):SetAlpha(255)
	hI:Lookup("Image_Sel"):Show()
	-- update content keys [hI.nGroupIndex]
	local hK = frame:Lookup("", "Handle_Hotkey")
	local szIniFile = "UI/Config/default/HotkeyPanel.ini"
	Hotkey.SetCapture(false)
	hK:Clear()
	hK.nGroupIndex = hI.nGroupIndex
	hK:AppendItemFromIni(szIniFile, "Text_GroupName")
	hK:Lookup(0):SetText(szGroup)
	hK:Lookup(0).bGroup = true
	for k, v in ipairs(aKey) do
		hK:AppendItemFromIni(szIniFile, "Handle_Binding")
		local hI = hK:Lookup(k)
		hI.bBinding = true
		hI.nIndex = k
		hI.szTip = v.szTip
		hI:Lookup("Text_Name"):SetText(v.szDesc)
		for i = 1, 2, 1 do
			local hK = hI:Lookup("Handle_Key"..i)
			hK.bKey = true
			hK.nIndex = i
			local hotkey = v["Hotkey"..i]
			hotkey.bUnchangeable = v.bUnchangeable
			hK.bUnchangeable = v.bUnchangeable
			local text = hK:Lookup("Text_Key"..i)
			text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
			-- update btn
			if hK.bUnchangeable then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
			elseif hK.bDown then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bRDown then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bSel then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bOver then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
			elseif hotkey.bChange then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
			elseif hotkey.bConflict then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
			else
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(53)
			end
		end
	end
	-- update content scroll
	hK:FormatAllItemPos()
	local wAll, hAll = hK:GetAllItemSize()
	local w, h = hK:GetSize()
	local scroll = frame:Lookup("Scroll_Key")
	local nCountStep = math.ceil((hAll - h) / 10)
	scroll:SetStepCount(nCountStep)
	scroll:SetScrollPos(0)
	if nCountStep > 0 then
		scroll:Show()
		scroll:GetParent():Lookup("Btn_Up"):Show()
		scroll:GetParent():Lookup("Btn_Down"):Show()
	else
		scroll:Hide()
		scroll:GetParent():Lookup("Btn_Up"):Hide()
		scroll:GetParent():Lookup("Btn_Down"):Hide()
	end
	-- update list scroll
	local scroll = frame:Lookup("Scroll_List")
	if scroll:GetStepCount() > 0 then
		local _, nH = hI:GetSize()
		local nStep = math.ceil((nI * nH) / 10)
		if nStep > scroll:GetStepCount() then
			nStep = scroll:GetStepCount()
		end
		scroll:SetScrollPos(nStep)
	end
end

---------------------------------------------------------------------
-- Combat text wnd
---------------------------------------------------------------------
local _HM_CombatText = {
	tTextQueue = {},
	g_MaxTraceNumber = 32,
	g_BowledTip = { X = {}, Y = {} },
	g_BowledScale = {},
	g_ExpLog = { X = {}, Y = {} },
	g_ExpLogScale = {},
	g_ExpAlpha = {},
}

-- 获取空闲文字
_HM_CombatText.GetFreeText = function(handle)
	local nItemCount = handle:GetItemCount()
	local nIndex
	local nTick = GetTickCount()
	if handle.nUseCount < nItemCount then
		local nEnd = nItemCount - 1
		for i = 0, nEnd, 1 do
			local hItem = handle:Lookup(i)
			if hItem.bFree or (hItem.stime and hItem.stime < BigIntSub(nTick, 60000)) then
				hItem.bFree = false
				hItem.stime = nTick
				handle.nUseCount = handle.nUseCount + 1
				return hItem
			end
		end
	else
		handle:AppendItemFromString("<text> w=550 h=100 halign=1 valign=1 multiline=1 </text>")
		local hItem = handle:Lookup(handle.nUseCount)
		hItem.bFree = false
		hItem.stime = nTick
		handle.nUseCount = handle.nUseCount + 1
		return hItem
	end
end

-- 获取 handle
_HM_CombatText.GetHandle = function()
	local handle = Station.Lookup("Lowest/CombatText", "Handle_Level1")
	return handle
end

-- 创建浮动文字
_HM_CombatText.NewText = function(dwCharacterID, szText, fScale, szName)
	local handle = _HM_CombatText.GetHandle()
	if not handle then
		return
	end
	local text = _HM_CombatText.GetFreeText(handle)
	table.insert(_HM_CombatText.tTextQueue, text)
	text:SetText(szText)
	text:SetName(szName)
	text:SetFontScheme(19)
	text:SetFontScale(1.0)
	text:SetAlpha(0)
	text:SetFontScale(fScale)
	text:AutoSize()
	text.aScale = nil
	text.Track = nil
	text.Alpha = nil
	text.dwOwner = dwCharacterID
	text.nFrameCount = 1
	text.fScale = fScale
	text:Hide()
	HM.ApplyTopPoint(function(nX, nY)
		if not nX then return end
		local nW, nH = text:GetSize()
		text:SetAbsPos(nX - nW / 2, nX - nH / 2)
		text:Show()
		text.xScreen = nX
		text.yScreen = nY
	end, dwCharacterID)
	return text
end

-- 初始化动画信息
_HM_CombatText.OnInit = function()
	for i = 1, 64, 1 do
		if i <= _HM_CombatText.g_MaxTraceNumber * 0.6 then
			_HM_CombatText.g_BowledTip["X"][i] = 0
			_HM_CombatText.g_BowledTip["Y"][i] = -70
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 0.75  then
			_HM_CombatText.g_BowledTip["X"][i] = 0
			_HM_CombatText.g_BowledTip["Y"][i] = -70
		else
			_HM_CombatText.g_BowledTip["X"][i] = 0
			_HM_CombatText.g_BowledTip["Y"][i] = -70
		end
	end
	for i = 1, 64, 1 do
		if i <= _HM_CombatText.g_MaxTraceNumber * 3/_HM_CombatText.g_MaxTraceNumber then
			_HM_CombatText.g_BowledScale[i] = i
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 8/_HM_CombatText.g_MaxTraceNumber  then
			_HM_CombatText.g_BowledScale[i] = 2.8
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 9/_HM_CombatText.g_MaxTraceNumber then
			_HM_CombatText.g_BowledScale[i] = 2.6
		else
			_HM_CombatText.g_BowledScale[i] = 1.5
		end
	end
	for i = 1, 64, 1 do
		if i <= _HM_CombatText.g_MaxTraceNumber * 0.6 then
			_HM_CombatText.g_ExpLog["X"][i] = 0
			_HM_CombatText.g_ExpLog["Y"][i] = 0
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 0.75  then
			_HM_CombatText.g_ExpLog["X"][i] = 0
			_HM_CombatText.g_ExpLog["Y"][i] = 0
		else
			_HM_CombatText.g_ExpLog["X"][i] = 0
			_HM_CombatText.g_ExpLog["Y"][i] = 0
		end
	end
	for i = 1, 64, 1 do
		if i <= _HM_CombatText.g_MaxTraceNumber * 3/_HM_CombatText.g_MaxTraceNumber then
			_HM_CombatText.g_ExpLogScale[i] = i
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 5/_HM_CombatText.g_MaxTraceNumber  then
			_HM_CombatText.g_ExpLogScale[i] = 4.5
		elseif i <= _HM_CombatText.g_MaxTraceNumber * 6/_HM_CombatText.g_MaxTraceNumber  then
			_HM_CombatText.g_ExpLogScale[i] = 2.8
		else
			_HM_CombatText.g_ExpLogScale[i] = 1.5
		end
	end
	for i = 1, 48, 1 do
		if i <= 8 then
			_HM_CombatText.g_ExpAlpha[i] = i / 8 * 255
		elseif i <= 40 then
			_HM_CombatText.g_ExpAlpha[i] = 255
		else
			_HM_CombatText.g_ExpAlpha[i] = ( 1- ( i - 40) / 8 ) * 255
		end
	end
end

-- 生成浮动文字效果（呼吸）
_HM_CombatText.OnBreathe = function()
	local handle = _HM_CombatText.GetHandle()
	if not handle or #_HM_CombatText.tTextQueue == 0 then
		return
	end
	if not _HM_CombatText.bInit then
		_HM_CombatText.OnInit()
		_HM_CombatText.bInit = true
	end
	for nIndex = #_HM_CombatText.tTextQueue, 1, -1 do
		local bRemove = false
		local text = _HM_CombatText.tTextQueue[nIndex]
		if text:IsValid() then
			local nFrameCount = text.nFrameCount
			local nX = text.Track.X[nFrameCount % _HM_CombatText.g_MaxTraceNumber + 1]
			local nY = text.Track.Y[nFrameCount % _HM_CombatText.g_MaxTraceNumber + 1]
			if nX and nY then
				local nDeltaPosX = nX * 3	--局部坐标系X的比例系数
				local nDeltaPosY = nY * 3	--局部坐标系Y的比例系数
				local fScale = text.fScale
				local dwOwner = text.dwOwner
				if text.aScale and text.aScale[nFrameCount] then
					fScale = text.aScale[nFrameCount]
				end
				text.nFrameCount = nFrameCount + 2 --跳真的速度
				nFrameCount = nFrameCount + 2 --跳真的速度
				local nFadeInFrame = 4		-- COMBAT_TEXT_FADE_IN_FRAME
				local nHoldFrame =20			-- COMBAT_TEXT_HOLD_FRAME
				local nFadeOutFrame = 8	-- COMBAT_TEXT_FADE_OUT_FRAME
				if fScale ~= text.fScale then
					text.fScale = fScale
					text:SetFontScale(fScale)
					text:AutoSize()
				end
				if text.Alpha then
					local alpha = text.Alpha[nFrameCount]
					if alpha then
						text:SetAlpha(alpha)
					else
						bRemove = true
					end
				else
					if nFrameCount < nFadeInFrame then
						text:SetAlpha(255 * nFrameCount / nFadeInFrame)
					elseif nFrameCount < nFadeInFrame + nHoldFrame then
						text:SetAlpha(255)
					elseif nFrameCount < nFadeInFrame + nHoldFrame + nFadeOutFrame then
						text:SetAlpha(255 * (1 - (nFrameCount - nFadeInFrame - nHoldFrame) / nFadeOutFrame))
					else
						bRemove = true
					end
				end
				-- adjust pos/size
				if not bRemove then
					local fnAction = function(nOrgX, nOrgY)
						if not nOrgX then return end
						--字体每桢变换
						local cxText, cyText = text:GetSize()
						nOrgX = nOrgX - cxText / 2
						nOrgY = nOrgY - cyText / 2
						-- 设置文字淡出,上移
						local nNextPosX =  nOrgX + nDeltaPosX
						local nNextPosY =  nOrgY + nDeltaPosY
						text:SetAbsPos(nNextPosX, nNextPosY)
					end
					if dwOwner == GetClientPlayer().dwID then
						fnAction(text.xScreen, text.yScreen)
					else
						HM.ApplyTopPoint(fnAction, dwOwner)
					end
				end
			else
				bRemove = true
			end
		end
		if bRemove then
			text.bFree = true
			text:Hide()
			handle.nUseCount = handle.nUseCount - 1
			table.remove(_HM_CombatText.tTextQueue, nIndex)
		end
	end
end

-- functions
if not OnCharacterHeadLog then
function OnCharacterHeadLog(dwCharacterID, szTip, nFont, tColor, bMultiLine)
	local text = _HM_CombatText.NewText(dwCharacterID, szTip, 1, "Scores")
	if text then
		if nFont then
			text:SetFontScheme(nFont)
		end
		if tColor then
			text:SetFontColor(unpack(tColor))
		else
			text:SetFontColor(0, 128, 199)
		end
		text:SetMultiLine(bMultiLine or false)
		text.Track = _HM_CombatText.g_ExpLog
		text.aScale = _HM_CombatText.g_ExpLogScale
		text.Alpha = _HM_CombatText.g_ExpAlpha
	end
end
HM.BreatheCall("CombatText", _HM_CombatText.OnBreathe)
end

if not OnBowledCharacterHeadLog then
function OnBowledCharacterHeadLog(dwCharacterID, szTip, nFont, tColor, bMultiLine)
	local text = _HM_CombatText.NewText(dwCharacterID, szTip, 1, "Bowled")
	if text then
		text:SetFontScheme(nFont or 199)
		if tColor then
			text:SetFontColor(unpack(tColor))
		end
		text:SetMultiLine(bMultiLine or false)
		text.Track = _HM_CombatText.g_BowledTip
		text.aScale = _HM_CombatText.g_BowledScale
		text.Alpha = _HM_CombatText.g_ExpAlpha
	end
end
HM.BreatheCall("CombatText", _HM_CombatText.OnBreathe)
end

if not DoAcceptJoinBattleField then
function DoAcceptJoinBattleField(nCenterIndex, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
	HM.DoMessageBox("BattleField_Enter_" .. dwMapID, 1)
end
end

if not DoAcceptJoinArena then
function DoAcceptJoinArena(nArenaType, nCenterID, dwMapID, nCopyIndex, nGroupID, dwJoinValue, dwCorpsID)
	HM.DoMessageBox("Arena_Enter_" .. nArenaType, 1)
end
end

if not MakeNameLink then
function MakeNameLink(szName, szFont)
	local szLink = "<text>text=" .. EncodeComponentsString(szName) ..
	szFont .. " name=\"namelink\" eventid=515</text>"
	return szLink
end
end

if not OutputNpcTip then
function OutputNpcTip(dwNpcID, Rect)
	local npc = GetNpc(dwNpcID)
	if not npc then
		return
	end

	if not npc.IsSelectable() then
		return
	end

	local clientPlayer = GetClientPlayer()
	local r, g, b=GetForceFontColor(dwNpcID, clientPlayer.dwID)

	local szTip = ""

	--------------名字-------------------------

	szTip = szTip.."<Text>text="..EncodeComponentsString(HM.GetTargetName(npc).."\n").." font=80".." r="..r.." g="..g.." b="..b.." </text>"

	-------------称号----------------------------
	if npc.szTitle ~= "" then
		szTip = szTip.."<Text>text="..EncodeComponentsString("<"..npc.szTitle..">\n").." font=0 </text>"
	end

	-------------等级----------------------------
	if npc.nLevel - clientPlayer.nLevel > 10 then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL).." font=82 </text>"
	else
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel)).." font=0 </text>"
	end

	------------模版ID-----------------------
	if IsCtrlKeyDown() then
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.TIP_NPC_ID, npc.dwID)).."font=102 </text>"
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, GetNpcIntensity(npc))).." font=102 </text>"
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.TIP_REPRESENTID_ID, npc.dwModelID)).." font=102 </text>"
		if IsShiftKeyDown() then
			local tState = GetNpcQuestState(npc) or {}
			for szKey, tQuestList in pairs(tState) do
				tState[szKey] = table.concat(tQuestList, ",")
			end
			szTip = szTip .. GetFormatText(var2str(tState), 102)
		end
	end

	OutputTip(szTip, 345, Rect)
end
end

if not OutputPlayerTip then
function OutputPlayerTip(dwPlayerID, Rect)
	--如果是自己，则不显示tip
	local player = GetPlayer(dwPlayerID)
	if not player then
		return
	end

	local clientPlayer = GetClientPlayer()

	if not IsCursorInExclusiveMode() then
		if clientPlayer.dwID == dwPlayerID then
			return
		end
	end

	local r, g, b = GetForceFontColor(dwPlayerID, clientPlayer.dwID)
	local szTip = ""

	--------------名字-------------------------
	szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_NAME_PLAYER, player.szName)).." font=80".." r="..r.." g="..g.." b="..b.." </text>"

	-------------称号----------------------------
	if player.szTitle ~= "" then
		szTip = szTip.."<Text>text="..EncodeComponentsString("<"..player.szTitle..">\n").." font=0 </text>"
	end

	if player.dwTongID ~= 0 then
		local szName = GetTongClient().ApplyGetTongName(player.dwTongID)
		if szName and szName ~= "" then
			szTip = szTip.."<Text>text="..EncodeComponentsString("["..szName.."]\n").." font=0 </text>"
		end
	end

	-------------等级----------------------------
	if player.nLevel - clientPlayer.nLevel > 10 and not clientPlayer.IsPlayerInMyParty(dwPlayerID) then
		szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL).." font=82 </text>"
	else
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, player.nLevel)).." font=82 </text>"
	end

	if IsParty(dwPlayerID, clientPlayer.dwID) then
		local hTeam = GetClientTeam()
		local tMemberInfo = hTeam.GetMemberInfo(dwPlayerID)
		if tMemberInfo then
			local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
			if szMapName then
				szTip = szTip.."<Text>text="..EncodeComponentsString(szMapName.."\n").." font=82 </text>"
			end
		end
	end

	if player.bCampFlag then
		szTip = szTip .. GetFormatText(g_tStrings.STR_TIP_CAMP_FLAG, 163)
	end

	local nCamp = player.nCamp
	szTip = szTip .. GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[nCamp], 82)

	if IsCtrlKeyDown() then
		szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.TIP_PLAYER_ID, player.dwID)).." font=102 </text>"
		-- szTip = szTip.."<Text>text="
		-- szTip = szTip..EncodeComponentsString(FormatString(g_tStrings.TIP_REPRESENTID_ID, player.dwModelID.." "..var2str(player.GetRepresentID()))).." font=102 </text>"
	end

	OutputTip(szTip, 345, Rect)
end
end
