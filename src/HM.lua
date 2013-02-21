--
-- ������������ú����⡢UI �������
-- by������@����2��ݶ����
--

---------------------------------------------------------------------
-- �����Դ���
---------------------------------------------------------------------
local function _HM_GetLang()
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData("interface\\HM\\lang\\default.lua") or {}
	local t1 = LoadLUAData("interface\\HM\\lang\\" .. szLang .. ".lua") or {}
	for k, v in pairs(t0) do
		if not t1[k] then
			t1[k] = v
		end
	end
	setmetatable(t1, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t1
end
_L = _HM_GetLang()

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------
local _HM = {
	dwVersion = 0x2000703,
	szBuildDate = "20130208",
	szTitle = _L["HM, JX3 Plug-in Collection"],
	szShort = _L["HM Plug"],
	szIniFile = "interface\\HM\\ui\\HM.ini",
	tClass = { _L["General"], _L["Target"], _L["Battle"] },
	tItem = { {}, {}, {} },
	tMenu = {},
	tEvent = {},
	tHotkey = {},
	tDelayCall = {},
	tBreatheCall = {},
	tCustomUpdateCall = {},
	tTempTarget = {},
	tSelect = {},
	tRequest = {},
	tBuffCache = {},
	tSkillCache = {},
	aNpc = {},
	aPlayer = {},
	nDebug = 1,
}

-------------------------------------
-- ������忪�ء���ʼ��
-------------------------------------
-- open
_HM.OpenPanel = function(bDisableSound)
	local frame = Station.Lookup("Normal/HM") or Wnd.OpenWindow(_HM.szIniFile, "HM")
	frame:Show()
	frame:BringToTop()
	if not bDisableSound then
		if HM_About and HM_About.bPlayOpen
			and (not _HM.nPlayOpen or (GetLogicFrameCount() - _HM.nPlayOpen) > 57600)
		then
			PlaySound(SOUND.UI_SOUND, "interface\\HM\\ui\\opening.wav")
			_HM.nPlayOpen = GetLogicFrameCount()
		else
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end
	end
	return frame
end

-- close
_HM.ClosePanel = function(bRealClose)
	local frame = Station.Lookup("Normal/HM")
	if frame then
		if not bRealClose then
			frame:Hide()
		else
			local button = Player_GetFrame():Lookup("HM_Button")
			if button then
				button:Destroy()
			end
			Wnd.CloseWindow(frame)
			_HM.frame = nil
		end
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

-- toggle
_HM.TogglePanel = function()
	if _HM.frame and _HM.frame:IsVisible() then
		_HM.ClosePanel()
	else
		_HM.OpenPanel()
	end
end

-- initlization
_HM.Init = function()
	local pFrame = Player_GetFrame()
	local hFrame = _HM.OpenPanel(true)
	-- button
	local button = pFrame:Lookup("HM_Button")
	if not button then
		button = hFrame:Lookup("Btn_Menu")
		button:SetName("HM_Button")
		button:ChangeRelation(pFrame, true, true)
		button.OnMouseEnter = function()
			local nX, nY = this:GetAbsPos()
			local nW, nH = this:GetSize()
			local szTip = GetFormatText("<" .. _HM.szShort .. ">\n", 101) .. GetFormatText(_L["Click to open setting panel!"], 106)
			OutputTip(szTip, 400, {nX, nY, nW, nH})
		end
		button.OnLButtonClick = _HM.TogglePanel
		button.OnRButtonClick = _HM.TogglePanel
		button:Show()
	else
		return
	end
	--  hide
	hFrame:Hide()
	-- hotkey
	Hotkey.AddBinding("HM_Total", _L["Open/Close setting panel"], _HM.szTitle, _HM.TogglePanel, nil)
	for _, v in ipairs(_HM.tHotkey) do
		Hotkey.AddBinding(v.szName, v.szTitle, "", v.fnAction, nil)
	end
	-- hook system
	_HM.HookPlayerMenu()
end

-------------------------------------
-- ����غ���
-------------------------------------
-- handle event
_HM.EventHandler = function(szEvent)
	local tEvent = _HM.tEvent[szEvent]
	if tEvent then
		for k, v in pairs(tEvent) do
			local res, err = pcall(v)
			if not res then
				HM.Debug("EVENT#" .. szEvent .. "." .. k .." ERROR: " .. err)
			end
		end
	end
end

-- select player as target temporary
_HM.SetTempTarget = function()
	if _HM.nTempFrame and _HM.nTempFrame > GetLogicFrameCount() then
		return
	end
	-- check current target
	local me, bApply = GetClientPlayer(), false
	if not me then return end
	if not _HM.nOrigTarget then
		if table.getn(_HM.tTempTarget) > 0 then
			bApply = true
		end
	else
		local dwType, dwID = me.GetTarget()
		if dwType ~= TARGET.PLAYER then
			bApply = true
		else
			local tar = GetPlayer(dwID)
			if not tar or tar.GetKungfuMount() ~= nil then
				bApply = true
			end
		end
	end
	if bApply == true then
		while true do
			if table.getn(_HM.tTempTarget) == 0 or me.bFightState then
				if _HM.nOrigTarget and _HM.nOrigTarget ~= 0 then
					HM.SetTarget(_HM.nOrigTarget)
					HM.Sysmsg(_L("Restore target [#%d]",  _HM.nOrigTarget))
					_HM.nOrigTarget = nil
				end
				break
			end
			local tar = GetPlayer(table.remove(_HM.tTempTarget, 1))
			if tar and tar.GetKungfuMount() == nil then
				if not _HM.nOrigTarget then
					_, _HM.nOrigTarget = me.GetTarget()
				end
				HM.Sysmsg(_L("Temporarily switch target [#%d]", tar.szName))
				HM.SetTarget(TARGET.PLAYER, tar.dwID)
				break
			end
		end
	end
	_HM.nTempFrame = GetLogicFrameCount() + 8
end

-- parse faceicon in talking message
_HM.ParseFaceIcon = function(t)
	if not _HM.tFaceIcon then
		_HM.tFaceIcon = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			_HM.tFaceIcon[tLine.szCommand] = true
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "faceicon" then
				v.type = "text"
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szFace = nil
				local nPos = StringFindW(v.text, "#", nOff)
				if not nPos then
					nPos = nLen
				else
					for i = nPos + 6, nPos + 2, -2 do
						if i <= nLen then
							local szTest = string.sub(v.text, nPos, i)
							if _HM.tFaceIcon[szTest] then
								szFace = szTest
								nPos = nPos - 1
								break
							end
						end
					end
				end
				if nPos >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos) })
					nOff = nPos + 1
				end
				if szFace then
					table.insert(t2, { type = "text", text = szFace })
					nOff = nOff + string.len(szFace)
				end
			end
		end
	end
	return t2
end

-- register conflict checker
_HM.RegisterConflictCheck = function(fnAction)
	_HM.tConflict = _HM.tConflict or {}
	table.insert(_HM.tConflict, fnAction)
end

-- fetch menu item traverse
_HM.FetchMenuItem = function(tData, szOption)
	if tData.szOption == szOption then
		return tData
	end
	for _, v in ipairs(tData) do
		local t = _HM.FetchMenuItem(v, szOption)
		if t then
			return t
		end
	end
end

-------------------------------------
-- ��������������
-------------------------------------
-- update scrollbar
_HM.UpdateListScroll = function()
	local handle, scroll = _HM.hList, _HM.hScroll
	local w, h = handle:GetSize()
	local wA, hA = handle:GetAllItemSize()
	local nStep = math.ceil((hA - h) / 10)
	scroll:SetStepCount(nStep)
	if nStep > 0 then
		scroll:Show()
		scroll:GetParent():Lookup("Btn_Up"):Show()
		scroll:GetParent():Lookup("Btn_Down"):Show()
	else
		scroll:Hide()
		scroll:GetParent():Lookup("Btn_Up"):Hide()
		scroll:GetParent():Lookup("Btn_Down"):Hide()
	end
end

-- updae detail content
_HM.UpdateDetail = function(i, data)
	local win = HM.UI.Fetch(_HM.frame, "Wnd_Detail")
	if win then win:Remove() end
	if not data then
		data = {}
		if HM_About then
			if not i then	-- default
				data.fn = {
					OnPanelActive = HM_About.OnPanelActive,
					GetAuthorInfo = HM_About.GetAuthorInfo,
				}
			elseif HM_About.OnTaboxCheck then	-- switch
				data.fn = {
					OnPanelActive = function(frame) HM_About.OnTaboxCheck(frame, i, _HM.tClass[i]) end,
					GetAuthorInfo = HM_About.GetAuthorInfo
				}
			end
		end
	end
	win = HM.UI.Append(_HM.frame, "WndActionWindow", "Wnd_Detail")
	win:Size(_HM.hContent:GetSize()):Pos(_HM.hContent:GetRelPos())
	if type(data.fn) == "table" then
		local szInfo = ""
		if data.fn.GetAuthorInfo then
			szInfo = "-- by " .. data.fn.GetAuthorInfo() .. " --"
		end
		_HM.hTotal:Lookup("Text_Author"):SetText(szInfo)
		if data.fn.OnPanelActive then
			data.fn.OnPanelActive(win:Raw())
			win.handle:FormatAllItemPos()
		end
		win.fnDestroy = data.fn.OnPanelDeactive
	end
end

-- create menu item
_HM.NewListItem = function(i, data, dwClass)
	local handle = _HM.hList
	local item = HM.UI.Append(handle, "BoxButton", "Button_" .. i)
	item:Icon(data.dwIcon):Text(data.szTitle):Click(function()
		_HM.UpdateDetail(dwClass, data)
	end, true, true)
	return item
end

-- update menu list
_HM.UpdateListInfo = function(nIndex)
	local nX, nY = 0, 14
	_HM.hList:Clear()
	_HM.hScroll:ScrollHome()
	_HM.UpdateDetail(nIndex)
	for k, v in ipairs(_HM.tItem[nIndex]) do
		local item = _HM.NewListItem(k, v, nIndex)
		item:Pos(nX, nY)
		nY = nY + 50
	end
	_HM.UpdateListScroll()
end

-- update tab list
_HM.UpdateTabBox = function(frame)
	local nX, nY, first = 25, 52, nil
	for k, v in ipairs(_HM.tClass) do
		if table.getn(_HM.tItem[k]) > 0 then
			local tab = frame:Lookup("TabBox_" .. k)
			if not tab then
				tab = HM.UI.Append(frame, "WndTabBox", "TabBox_" .. k, { group = "Nav" })
			else
				tab = HM.UI.Fetch(tab)
			end
			tab:Text(v):Pos(nX, nY):Click(function(bChecked)
				if bChecked then
					_HM.UpdateListInfo(k)
				end
			end):Check(false)
			if not first then
				first = tab
			end
			local nW, _ = tab:Size()
			nX = nX + math.ceil(nW) + 10
		end
	end
	if first then
		first:Check(true)
	end
end

-------------------------------------
-- ϵͳ HOOK
-------------------------------------
-- get player menu
_HM.GetPlayerMenu = function()
	local m0, n = {  szOption = _HM.szTitle }, 0
	table.insert(m0, { szOption = _L("Current version: v%s", HM.GetVersion()), fnDisable = function() return true end })
	table.insert(m0, { bDevide = true })
	-- append
	for _, v in ipairs(_HM.tMenu) do
		if type(v) == "function" then
			table.insert(m0, v())
		else
			table.insert(m0, v)
		end
		n = n + 1
	end
	-- OnPlayerMenu
	for _, v in ipairs(_HM.tItem) do
		local n2 = 0
		for _, vv in ipairs(v) do
			if vv.fn and vv.fn.OnPlayerMenu then
				local m1 = vv.fn.OnPlayerMenu()
				if n2 == 0 and n > 0 then
					n = 0
					table.insert(m0, { bDevide = true })
				end
				if m1.szOption then
					table.insert(m0, m1)
					n2 = n2 + 1
				else
					for _, m2 in ipairs(m1) do
						table.insert(m0, m2)
						n2 = n2 + 1
					end
				end
			end
		end
		if n == 0 then n = n2 end
	end
	-- debug
	if HM_About and HM_About.bDebug then
		local m1 = { szOption = "HM Debug Level [" .. _HM.nDebug .. "]", }
		for i = 1, 3 do
			table.insert(m1, {
				szOption = "Lv." .. i,
				bCheck = true, bMCheck = true, bChecked = i == _HM.nDebug,
				fnAction = function() _HM.nDebug = i end
			})
		end
		if n > 0 then
			table.insert(m0, { bDevide = true })
		end
		table.insert(m0, m1)
	end
	return { m0 }
end

-- hook player menu
_HM.HookPlayerMenu = function()
	Player_AppendAddonMenu({ _HM.GetPlayerMenu })
end

---------------------------------------------------------------------
-- ȫ�ֺ����ͱ�����HM.xxx��
---------------------------------------------------------------------
HM = {
	szTitle = _HM.szTitle,						-- ���������
	szBuildDate = _HM.szBuildDate,		-- �����������
	nBuildDate = 0,	-- ���͵ĸ������ڣ����� CustomData��
}
RegisterCustomData("HM.nBuildDate")

-- (string, number) HM.GetVersion()		-- ȡ���ַ����汾�ź����Ͱ汾��
HM.GetVersion = function()
	local v = _HM.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end

-- (boolean) HM.IsPanelOpened()			-- �ж���������Ƿ��Ѵ�
HM.IsPanelOpened = function()
	return _HM.frame and _HM.frame:IsVisible()
end

-- (void) HM.OpenPanel()							-- ���������
-- (void) HM.OpenPanel(string szTitle)		-- ������Ϊ szTitle �Ĳ����������ý���
HM.OpenPanel = function(szTitle)
	_HM.OpenPanel(szTitle ~= nil)
	if szTitle then
		local nClass, nItem = 0, 0
		for k, v in ipairs(_HM.tItem) do
			if _HM.tClass[k] == szTitle then
				nClass = k
				break
			end
			for kk, vv in ipairs(v) do
				if vv.szTitle == szTitle then
					nClass, nItem = k, kk
				end
			end
		end
		if nClass ~= 0 then
			HM.UI.Fetch(_HM.frame, "TabBox_" .. nClass):Check(true)
			if nItem ~= 0 then
				HM.UI.Fetch(_HM.hList, "Button_" .. nItem):Click()
			end
		end
	end
end

-- (void) HM.ClosePanel()				--  �����������
-- (void) HM.ClosePanel(true)		-- ���׹ر�������崰��
HM.ClosePanel = _HM.ClosePanel

-- (void) HM.TogglePanel()			-- ��ʾ/�����������
HM.TogglePanel= _HM.TogglePanel

-- ����������һ��������ð�Ŧ������
-- (void) HM.RegisterPanel(string szTitle, number dwIcon, string szClass, table fn)
-- szTitle		-- �������
--	dwIcon		-- ͼ�� ID
--	szClass		-- �������ƣ���Ϊ nil ������
--	fn {			-- ������
--		OnPanelActive = (void) function(WndWindow frame),		-- ������弤��ʱ���ã�����Ϊ���û���Ĵ������
--		OnPanelDeactive = (void) function(WndWindow frame),	-- *��ѡ* ������屻�г�ʱ���ã�����ͬ��
--		OnConflictCheck = (void) function(),								-- *��ѡ* �����ͻ��⺯����ÿ�����ߺ����һ�Σ�
--		OnPlayerMenu = (table) function(),									-- *��ѡ* ���ظ��ӵ�ͷ��˵�
--		GetAuthorInfo = (string) function(),									-- *��ѡ* ���ظò�������ߡ���Ȩ��Ϣ
--	}
HM.RegisterPanel = function(szTitle, dwIcon, szClass, fn)
	-- find class
	local dwClass = nil
	if not szClass then
		dwClass = 1
	else
		for k, v in ipairs(_HM.tClass) do
			if v == szClass then
				dwClass = k
			end
		end
		if not dwClass then
			table.insert(_HM.tClass, szClass)
			dwClass = table.getn(_HM.tClass)
			_HM.tItem[dwClass] = {}
		end
	end
	-- check to update
	for _, v in ipairs(_HM.tItem[dwClass]) do
		if v.szTitle == szTitle then
			v.dwIcon, v.fn, dwClass = dwIcon, fn, nil
			break
		end
	end
	-- create new one
	if dwClass then
		table.insert(_HM.tItem[dwClass], { szTitle = szTitle, dwIcon = dwIcon, fn = fn })
	end
	if _HM.frame then
		_HM.UpdateTabBox(_HM.frame)
	end
	if fn and fn.OnConflictCheck then
		_HM.RegisterConflictCheck(fn.OnConflictCheck)
	end
end

-- (table) HM.GetPanelFunc(szTitle)		-- ��ȡ Hook ĳ������ĳ�ʼ������
HM.GetPanelFunc = function(szTitle)
	for k, v in ipairs(_HM.tItem) do
		for kk, vv in ipairs(v) do
			if vv.szTitle == szTitle then
				return vv.fn
			end
		end
	end
end

-- �Ǽ���Ҫ��ʱ��ΪĿ�����ң��ڷ�ս��״̬����ʱ�л�Ŀ�꣬�Ի�ȡĿ����ҵ��ڹ���
-- (void) HM.RegisterTempTarget(number dwID)
-- dwID		-- ��Ҫ��ע����� ID
HM.RegisterTempTarget = function(dwID)
	table.insert(_HM.tTempTarget, dwID)
end

-- �Ǽ���Ҫ��ӵ�ͷ��˵�����Ŀ
-- (void) HM.AppendPlayerMenu(table menu | func fnMenu)
-- menu 		-- Ҫ��ӵĵĲ˵���򷵻ز˵���ĺ���
HM.AppendPlayerMenu = function(menu)
	table.insert(_HM.tMenu, menu)
end

-- �����������һ�λ��֣�ֻ�е�ǰ�û��ɼ���
-- (void) HM.Sysmsg(string szMsg[, string szHead])
-- szMsg		-- Ҫ�������������
--	szHead		-- ���ǰ׺���Զ����������ţ�Ĭ��Ϊ���������
HM.Sysmsg = function(szMsg, szHead)
	szHead = szHead or _HM.szShort
	OutputMessage("MSG_SYS", "[" .. szHead .. "] " .. szMsg .. "\n")
end

-- �����������������Ϣ���� HM.Sysmsg ���ƣ�����2���������ֵķ��ű��
-- (void) HM.Debug(string szMsg[, string szHead])
-- (void) HM.Debug2(string szMsg[, string szHead])
-- (void) HM.Debug3(string szMsg[, string szHead])
HM.Debug = function(szMsg, szHead, nLevel)
	nLevel = nLevel or 1
	if HM_About and HM_About.bDebug and _HM.nDebug >= nLevel then
		if nLevel == 3 then szMsg = "### " .. szMsg
		elseif nLevel == 2 then szMsg = "=== " .. szMsg
		else szMsg = "-- " .. szMsg end
		HM.Sysmsg(szMsg, szHead)
	end
end
HM.Debug2 = function(szMsg, szHead) HM.Debug(szMsg, szHead, 2) end
HM.Debug3 = function(szMsg, szHead) HM.Debug(szMsg, szHead, 3) end

-- ����Ļ���м䵯����һ���ı���һ��ȷ����Ŧ�ľ�ʾ��
-- (void) HM.Alert(string szMsg, func fnAction, string szSure)
-- szMsg		-- ��ʾ��������
-- fnAction	-- ����ȷ�ϰ�Ŧ�󴥷��Ļص�����
-- szSure		-- ȷ�ϰ�Ŧ�����֣�Ĭ�ϣ�ȷ��
HM.Alert = function(szMsg, fnAction, szSure)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 2, szMessage = szMsg, szName = "HM_Alert",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		},
	}
	MessageBox(tMsg)
end

-- ����Ļ�м䵯����������Ŧ��ȷ�Ͽ򣬲�����һ���ı���ʾ
-- (void) HM.Confirm(string szMsg, func fnAction, func fnCancel[, string szSure[, string szCancel]])
-- szMsg		-- ��ʾ��������
-- fnAction	-- ����ȷ�ϰ�Ŧ�󴥷��Ļص�����
-- fnCancel	-- ����ȡ����Ŧ�󴥷��Ļص�����
-- szSure		-- ȷ�ϰ�Ŧ�����֣�Ĭ�ϣ�ȷ��
-- szCancel	-- ȡ����Ŧ�����֣�Ĭ�ϣ�ȡ��
HM.Confirm = function(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 2, szMessage = szMsg, szName = "HM_Confirm",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

-- (void) HM.AddHotKey(string szName, string szTitle, func fnAction)	-- ����ϵͳ��ݼ�
HM.AddHotKey = function(szName, szTitle, fnAction)
	if string.sub(1, 3) ~= "HM_" then
		szName = "HM_" .. szName
	end
	table.insert(_HM.tHotkey, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end

-- (string) HM.GetHotKey(string szName, boolean bBracket, boolean bShort)		-- ȡ�ÿ�ݼ�����
HM.GetHotKey = function(szName, bBracket, bShort)
	if string.sub(1, 3) ~= "HM_" then
		szName = "HM_" .. szName
	end
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szKey = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szKey ~= "" and bBracket then
		szKey = "(" .. szKey .. ")"
	end
	return szKey
end

-- (void) HM.SetHotKey()								-- �򿪿�ݼ��������
-- (void) HM.SetHotKey(string szGroup)		-- �򿪿�ݼ�������岢��λ�� szGroup ���飨�����ã�
HM.SetHotKey = function(szGroup)
	HotkeyPanel_Open(szGroup or HM.szTitle)
end

-- ע�����ѭ�����ú���
-- (void) HM.BreatheCall(string szKey, func fnAction[, number nTime])
-- szKey		-- ���ƣ�����Ψһ���ظ��򸲸�
-- fnAction	-- ѭ���������ú�������Ϊ nil ���ʾȡ����� key �µĺ���������
-- nTime		-- ���ü������λ�����룬Ĭ��Ϊ 62.5����ÿ����� 16�Σ���ֵ�Զ�������� 62.5 ��������
HM.BreatheCall = function(szKey, fnAction, nTime)
	local key = StringLowerW(szKey)
	if type(fnAction) == "function" then
		local nFrame = 1
		if nTime and nTime > 0 then
			nFrame = math.ceil(nTime / 62.5)
		end
		_HM.tBreatheCall[key] = { fnAction = fnAction, nNext = GetLogicFrameCount() + 1, nFrame = nFrame }
	else
		_HM.tBreatheCall[key] = nil
	end
end

-- (void) HM.DelayCall(number nDelay, func fnAction)		-- �ӳٵ���
-- nTime		-- �ӳٵ���ʱ�䣬��λ�����룬ʵ�ʵ����ӳ��ӳ��� 62.5 ��������
-- fnAction	-- ���ú���
HM.DelayCall = function(nDelay, fnAction)
	local nTime = nDelay + GetTime()
	table.insert(_HM.tDelayCall, { nTime = nTime, fnAction = fnAction })
end

-- (void) HM.RemoteRequest(string szUrl, func fnAction)		-- ����Զ�� HTTP ����
-- szUrl		-- ��������� URL������ http:// �� https://��
-- fnAction 	-- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle)
HM.RemoteRequest = function(szUrl, fnAction)
	local page = Station.Lookup("Normal/HM/Page_1")
	if page then
		_HM.tRequest[szUrl] = fnAction
		page:Navigate(szUrl)
	end
end

-- (KObject) HM.GetTarget()														-- ȡ�õ�ǰĿ���������
-- (KObject) HM.GetTarget([number dwType, ]number dwID)	-- ���� dwType ���ͺ� dwID ȡ�ò�������
HM.GetTarget = function(dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end

-- ���� dwType ���ͺ� dwID ����Ŀ��
-- (void) HM.SetTarget([number dwType, ]number dwID)
-- dwType	-- *��ѡ* Ŀ������
-- dwID		-- Ŀ�� ID
HM.SetTarget = function(dwType, dwID)
	if not dwType or dwType <= 0 then
		dwType, dwID = TARGET.NO_TARGET, 0
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	SetTarget(dwType, dwID)
end

-- �л���ʱĿ�꣬���ı�Ŀ�����
HM.SetInsTarget = function(...)
	TargetPanel_SetOpenState(true)
	HM.SetTarget(...)
	TargetPanel_SetOpenState(false)
end

-- ����Ŀ�������ʾ������
-- (string) HM.GetTargetName(userdata KNpc/KPlayer)
HM.GetTargetName = function(tar)
	local szName = tar.szName
	if tar.dwEmployer and tar.dwEmployer ~= 0 then
		local emp = GetPlayer(tar.dwEmployer)
		if not emp then
			szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		else
			szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		end
	end
	return szName
end

-- �ж�ĳ��Ƶ���ܷ���
-- (bool) HM.CanTalk(number nChannel)
HM.CanTalk = function(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end

-- ������������
-- (void) HM.Talk(string szTarget, string szText[, boolean bNoEmotion])
-- (void) HM.Talk([number nChannel, ] string szText[, boolean bNoEmotion])
-- szTarget			-- ���ĵ�Ŀ���ɫ��
-- szText				-- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel			-- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEmotion	-- *��ѡ* ���������������еı���ͼƬ��Ĭ��Ϊ false
-- bSaveDeny	-- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�
HM.Talk = function(nChannel, szText, bNoEmotion, bSaveDeny)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		local tar = HM.GetTarget(me.GetTarget())
		szText = string.gsub(szText, "%$zj", me.szName)
		if tar then
			szText = string.gsub(szText, "%$mb", tar.szName)
		end
		tSay = {{ type = "text", text = szText .. "\n"}}
	end
	if not bNoEmotion then
		tSay = _HM.ParseFaceIcon(tSay)
	end
	me.Talk(nChannel, szTarget, tSay)
	if bSaveDeny and not HM.CanTalk(nChannel) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
	end
end

-- �޷�����ʱ���������������
HM.Talk2 = function(nChannel, szText, bNoEmotion)
	HM.Talk(nChannel, szText, bNoEmotion, true)
end

-- ������̨����ͨѶ
-- (void) HM.BgTalk(szTarget, ...)
-- (void) HM.BgTalk(nChannel, ...)
-- szTarget			-- ���ĵ�Ŀ���ɫ��
-- nChannel			-- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- ...						-- ���ɸ��ַ���������ɣ���ԭ��������
HM.BgTalk = function(nChannel, ...)
	local tSay = { { type = "text", text = "BG_CHANNEL_MSG" } }
	local tArg = { ... }
	for _, v in ipairs(tArg) do
		if v == nil then
			break
		end
		table.insert(tSay, { type = "text", text = tostring(v) })
	end
	HM.Talk(nChannel, tSay, true)
end

-- ��ȡ��̨�������ݣ��� ON_BG_CHANNEL_MSG �¼���������ʹ�ò�������
-- (table) HM.BgHear([string szKey])
-- szKey			-- ͨѶ���ͣ�Ҳ���� HM.BgTalk �ĵ�һ���ݲ���������ƥ�������
-- arg0: dwTalkerID, arg1: nChannel, arg2: bEcho, arg3: szName
HM.BgHear = function(szKey)
	local me = GetClientPlayer()
	local tSay = me.GetTalkData()
	if tSay and arg0 ~= me.dwID and tSay[1].text == "BG_CHANNEL_MSG" then
		local tData, nOff = {}, 2
		if szKey then
			if tSay[nOff].text ~= szKey then
				return nil
			end
			nOff = nOff + 1
		end
		for i = nOff, #tSay do
			table.insert(tData, tSay[i].text)
		end
		return tData
	end
end

-- (boolean) HM.IsDps([KPlayer tar])			-- �������Ƿ�Ϊ DPS �ڹ���ʡ���ж����ж�����
HM.IsDps = function(tar)
	tar = tar or GetClientPlayer()
	local mnt = tar.GetKungfuMount()
	return not mnt or (mnt.dwSkillID ~= 10080 and mnt.dwSkillID ~= 10028 and mnt.dwSkillID ~= 10176)
end

-- HM.GetMe
HM.Me = GetClientPlayer

-- (boolean) HM.IsParty(number dwID)		-- ������� ID �ж��Ƿ�Ϊ����
HM.IsParty = function(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
end

-- (table) HM.GetAllPlayer([number nLimit])			-- ��ȡ�����ڵ����� ���
-- nLimit	-- �������ޣ�Ĭ�ϲ���
HM.GetAllPlayer = function(nLimit)
	local aPlayer = {}
	for k, _ in pairs(_HM.aPlayer) do
		local p = GetPlayer(k)
		if not p then
			_HM.aPlayer[k] = nil
		elseif p.szName ~= "" then
			table.insert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

-- (table) HM.GetAllPlayerID()			-- ��ȡ�����ڵ� NPC ID �б�
HM.GetAllPlayerID = function()
	return _HM.aPlayer
end

-- (table) HM.GetAllNpc([number nLimit])				-- ��ȡ�����ڵ����� NPC
-- nLimit	-- �������ޣ�Ĭ�ϲ���
HM.GetAllNpc = function(nLimit)
	local aNpc = {}
	for k, _ in pairs(_HM.aNpc) do
		local p = GetNpc(k)
		if not p then
			_HM.aNpc[k] = nil
		else
			table.insert(aNpc, p)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

-- (table) HM.GetAllNpcID()			-- ��ȡ�����ڵ� NPC ID �б�
HM.GetAllNpcID = function()
	return _HM.aNpc
end

-- ����Ŀ��������ľ���
-- (number) HM.GetDistance(KObject tar)
-- (number) HM.GetDistance(number nX, number nY[, number nZ])
-- tar		-- ���� nX��nY��nZ �����Ե� table �� KPlayer��KNpc��KDoodad
-- nX		-- ��������ϵ�µ�Ŀ��� X ֵ
-- nY		-- ��������ϵ�µ�Ŀ��� Y ֵ
-- nZ		-- *��ѡ* ��������ϵ�µ�Ŀ��� Z ֵ
HM.GetDistance = function(nX, nY, nZ)
	local me = GetClientPlayer()
	if not nY and not nZ then
		local tar = nX
		nX, nY, nZ = tar.nX, tar.nY, tar.nZ
	elseif not nZ then
		return math.floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2) ^ 0.5)/64
	end
	return math.floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2 + (me.nZ/8 - nZ/8) ^ 2) ^ 0.5)/64
end

-- ����Ŀ������λ�á�����������������Ļ�ϵ���Ӧλ��
-- (number, number) HM.GetScreenPoint(KObject tar)
-- (number, number) HM.GetScreenPoint(number nX, number nY, number nZ)
-- tar		-- ���� nX��nY��nZ �����Ե� table �� KPlayer��KNpc��KDoodad
-- nX		-- ��������ϵ�µ�Ŀ��� X ֵ
-- nY		-- ��������ϵ�µ�Ŀ��� Y ֵ
-- nZ		-- ��������ϵ�µ�Ŀ��� Z ֵ
-- ����ֵ����Ļ����� X��Y ֵ��ת��ʧ�ܷ��� nil
HM.GetScreenPoint = function(nX, nY, nZ)
	if not nY then
		local tar = nX
		nX, nY, nZ = tar.nX, tar.nY, tar.nZ
	end
	nX, nY, nZ = Scene_GameWorldPositionToScenePosition(nX, nY, nZ, 0)
	if nX and nY and nZ then
		nX, nY, nZ = Scene_ScenePointToScreenPoint(nX, nY, nZ)
		if nZ then
			return Station.AdjustToOriginalPos(nX, nY)
		end
	end
end

-- (number, number) HM.GetTopPoint(KObject tar[, number nH])
-- (number, number) HM.GetTopPoint(number dwID[, number nH])
-- tar			-- Ŀ����� KPlayer��KNpc��KDoodad
-- dwID		-- Ŀ�� ID
-- nH			-- *��ѡ* �߶ȣ���λ�ǣ���*64��Ĭ�϶��� NPC/PLAYER �����ܼ���ͷ��
HM.GetTopPoint = function(tar, nH)
	if type(tar) == "number" then
		tar = HM.GetTarget(tar)
	end
	if tar then
		local nX, nY, nZ = nil, nil, nil
		if not nH then
			nX, nY, nZ = Scene_GetCharacterTop(tar.dwID)
		end
		if not nX and tar.nX and tar.nY and tar.nZ then
			nH = nH or 768
			if nH < 64 then
				nH = nH * 64
			end
			nX, nY, nZ = Scene_GameWorldPositionToScenePosition(tar.nX, tar.nY, tar.nZ + nH, 0)
		end
		if nX and nY and nZ then
			nX, nY, nZ = Scene_ScenePointToScreenPoint(nX, nY, nZ)
			if nZ then
				return Station.AdjustToOriginalPos(nX, nY)
			end
		end
	end
end

-- (table) HM.Split(string szFull, string szSep)		-- ���� szSep �ָ��ַ��� szFull����֧�ֱ��ʽ
HM.Split = function(szFull, szSep)
	local nOff, tResult = 1, {}
	while true do
		local nEnd = StringFindW(szFull, szSep, nOff)
		if not nEnd then
			table.insert(tResult, string.sub(szFull, nOff, string.len(szFull)))
			break
		else
			table.insert(tResult, string.sub(szFull, nOff, nEnd - 1))
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end

-- (string) HM.Trim(string szText)				-- ����ַ�����β�Ŀհ��ַ�
HM.Trim = function(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end

-- (string) HM.UrlEncode(string szText)		-- ת��Ϊ URL ����
HM.UrlEncode = function(szText)
	local str = szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = str:gsub(" ", "+")
	return str
end

-- ���ݼ��� ID ���ȼ���ȡ���ܵ����Ƽ�ͼ�� ID�����û��洦��
-- (string, number) HM.GetSkillName(number dwSkillID[, number dwLevel])
HM.GetSkillName = function(dwSkillID, dwLevel)
	if not _HM.tSkillCache[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow and StringFindW(tLine.szDesc, "_") == nil then
			_HM.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "SKILL#" .. dwSkillID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_HM.tSkillCache[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(_HM.tSkillCache[dwSkillID])
end

-- ����Buff ID ���ȼ���ȡ BUFF �����Ƽ�ͼ�� ID�����û��洦��
-- (string, number) HM.GetBuffName(number dwBuffID[, number dwLevel])
HM.GetBuffName = function(dwBuffID, dwLevel)
	if not _HM.tBuffCache[dwBuffID] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			_HM.tBuffCache[dwBuffID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "BUFF#" .. dwBuffID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_HM.tBuffCache[dwBuffID] = { szName, -1 }
		end
	end
	return unpack(_HM.tBuffCache[dwBuffID])
end

-- ע���¼�����ϵͳ���������ڿ���ָ��һ�� KEY ��ֹ��μ���
-- (void) HM.RegisterEvent(string szEvent, func fnAction[, string szKey])
-- szEvent		-- �¼������ں����һ���㲢����һ����ʶ�ַ������ڷ�ֹ�ظ���ȡ���󶨣��� LOADING_END.xxx
-- fnAction		-- �¼���������arg0 ~ arg9������ nil �൱��ȡ�����¼�
--�ر�ע�⣺�� fnAction Ϊ nil ���� szKey ҲΪ nil ʱ��ȡ������ͨ��������ע����¼�������
HM.RegisterEvent = function(szEvent, fnAction)
	local szKey = nil
	local nPos = StringFindW(szEvent, ".")
	if nPos then
		szKey = string.sub(szEvent, nPos + 1)
		szEvent = string.sub(szEvent, 1, nPos - 1)
	end
	if not _HM.tEvent[szEvent] then
		_HM.tEvent[szEvent] = {}
		RegisterEvent(szEvent, function() _HM.EventHandler(szEvent) end)
	end
	local tEvent = _HM.tEvent[szEvent]
	if fnAction then
		if not szKey then
			table.insert(tEvent, fnAction)
		else
			tEvent[szKey] = fnAction
		end
	else
		if not szKey then
			_HM.tEvent[szEvent] = {}
		else
			tEvent[szKey] = nil
		end
	end
end

-- ȡ���¼�������
-- (void) HM.UnRegisterEvent(string szEvent)
HM.UnRegisterEvent = function(szEvent)
	HM.RegisterEvent(szEvent, nil)
end

-- Role Custom Data ���غ��жϱȽ� nUpdateDate Ȼ����� fnAction
-- (void) HM.RegisterCustomUpdater(func fnAction, number nUpdateDate)
HM.RegisterCustomUpdater = function(fnAction, nUpdateDate)
	table.insert(_HM.tCustomUpdateCall, { nDate = nUpdateDate, fnAction = fnAction })
end

-- �жϵ�ǰ�û��Ƿ����ĳ������
-- (bool) HM.CanUseSkill(number dwSkillID)
HM.CanUseSkill = function(dwSkillID)
	local me, box = GetClientPlayer(), _HM.hBox
	if me and box then
		local dwLevel = 1
		if dwSkillID ~= 9007 then
			dwLevel = me.GetSkillLevel(dwSkillID)
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end

-- �������ƻ�ȡ�����˵����ݣ��ɵ�����ֵ�е� fnAction ִ�в���
-- (table) HM.GetPopupMenuItem(string szOption)
HM.GetPopupMenuItem = function(szOption)
    local frame = Station.Lookup("Topmost1/PopupMenuPanel")
    if not frame or not frame:IsVisible() then
        return
    end
    local hItemGroup = frame:Lookup("", ""):Lookup(0):Lookup("Handle_Item_Group")
    for i = 0, hItemGroup:GetItemCount() - 1, 1 do
        local hItem = hItemGroup:Lookup(i)
        if hItem.tData then
            local t = _HM.FetchMenuItem(hItem.tData, szOption)
            if t then
                return t
            end
        end
    end
end

-- �Զ�ִ�е�����ȷ�Ͽ�
-- (void) HM.DoMessageBox(string szName, [number i ])
-- szName		-- ȷ�Ͽ������
-- i 					-- Ҫִ�е�ѡ���ţ��� 1 ��ʼ��Ĭ��Ϊ 1
HM.DoMessageBox = function(szName, i)
	local frame = Station.Lookup("Topmost2/MB_" .. szName) or Station.Lookup("Topmost/MB_" .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup("Wnd_All/Btn_Option" .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				btn.fnAction(i)
			elseif frame.fnAction then
				frame.fnAction(i)
			end
			CloseMessageBox(szName)
		end
	end
end

---------------------------------------------------------------------
-- ���ظ����õļ��� Handle Ԫ�������
---------------------------------------------------------------------
_HM.HandlePool= class()

-- construct
function _HM.HandlePool:ctor(handle, xml)
	self.handle, self.xml = handle, xml
	handle.nFreeCount = 0
	handle:Clear()
end

-- clear
function _HM.HandlePool:Clear()
	self.handle:Clear()
	self.handle.nFreeCount = 0
end

-- new item
function _HM.HandlePool:New()
	local handle = self.handle
	local nCount = handle:GetItemCount()
	if handle.nFreeCount > 0 then
		for i = nCount - 1, 0, -1 do
			local item = handle:Lookup(i)
			if item.bFree then
				item.bFree = false
				handle.nFreeCount = handle.nFreeCount - 1
				return item
			end
		end
		handle.nFreeCount = 0
	else
		handle:AppendItemFromString(self.xml)
		local item = handle:Lookup(nCount)
		item.bFree = false
		return item
	end
end

-- remove item
function _HM.HandlePool:Remove(item)
	if item:IsValid() then
		self.handle:RemoveItem(item)
	end
end

-- free item
function _HM.HandlePool:Free(item)
	if item:IsValid() then
		self.handle.nFreeCount = self.handle.nFreeCount + 1
		item.bFree = true
		item:Hide()
	end
end

-- public api, create pool
-- (class) HM.HandlePool(userdata handle, string szXml)
HM.HandlePool = _HM.HandlePool.new

---------------------------------------------------------------------
-- ���ص� UI �������
---------------------------------------------------------------------
_HM.UI = {}

-------------------------------------
-- Base object class
-------------------------------------
_HM.UI.Base = class()

-- (userdata) Instance:Raw()		-- ��ȡԭʼ����/�������
function _HM.UI.Base:Raw()
	if self.type == "Label" then
		return self.txt
	end
	return self.wnd or self.edit or self.self
end

-- (void) Instance:Remove()		-- ɾ�����
function _HM.UI.Base:Remove()
	if self.fnDestroy then
		local wnd = self.wnd or self.self
		self.fnDestroy(wnd)
	end
	local hP = self.self:GetParent()
	if hP.___uis then
		local szName = self.self:GetName()
		hP.___uis[szName] = nil
	end
	if self.type == "WndFrame" then
		Wnd.CloseWindow(self.self)
	elseif string.sub(self.type, 1, 3) == "Wnd" then
		self.self:Destroy()
	else
		hP:RemoveItem(self.self:GetIndex())
	end
end

-- (string) Instance:Name()					-- ȡ������
-- (self) Instance:Name(szName)			-- ��������Ϊ szName ������������֧�ִ��ӵ���
function _HM.UI.Base:Name(szName)
	if not szName then
		return self.self:GetName()
	end
	self.self:SetName(szName)
	return self
end

-- (self) Instance:Toggle([boolean bShow])			-- ��ʾ/����
function _HM.UI.Base:Toggle(bShow)
	if bShow == false or (not bShow and self.self:IsVisible()) then
		self.self:Hide()
	else
		self.self:Show()
		if self.type == "WndFrame" then
			self.self:BringToTop()
		end
	end
	return self.self
end

-- (number, number) Instance:Pos()					-- ȡ��λ������
-- (self) Instance:Pos(number nX, number nY)	-- ����λ������
function _HM.UI.Base:Pos(nX, nY)
	if not nX then
		return self.self:GetRelPos()
	end
	self.self:SetRelPos(nX, nY)
	if self.type == "WndFrame" then
		self.self:CorrectPos()
	elseif string.sub(self.type, 1, 3) ~= "Wnd" then
		self.self:GetParent():FormatAllItemPos()
	end
	return self
end

-- (number, number) Instance:Pos_()			-- ȡ�����½ǵ�����
function _HM.UI.Base:Pos_()
	local nX, nY = self:Pos()
	local nW, nH = self:Size()
	return nX + nW, nY + nH
end

-- (number, number) Instance:CPos_()			-- ȡ�����һ����Ԫ�����½�����
-- �ر�ע�⣺����ͨ�� :Append() ׷�ӵ�Ԫ����Ч���Ա����ڶ�̬��λ
function _HM.UI.Base:CPos_()
	local hP = self.wnd or self.self
	if not hP.___last and string.sub(hP:GetType(), 1, 3) == "Wnd" then
		hP = hP:Lookup("", "")
	end
	if hP.___last then
		local ui = HM.UI.Fetch(hP, hP.___last)
		if ui then
			return ui:Pos_()
		end
	end
	return 0, 0
end

-- (class) Instance:Append(string szType, ...)	-- ��� UI �����
-- NOTICE��only for Handle��WndXXX
function _HM.UI.Base:Append(szType, ...)
	local hP = self.wnd or self.self
	if string.sub(hP:GetType(), 1, 3) == "Wnd" and string.sub(szType, 1, 3) ~= "Wnd" then
		hP.___last = nil
		hP = hP:Lookup("", "")
	end
	return HM.UI.Append(hP, szType, ...)
end

-- (class) Instance:Fetch(string szName)	-- �������ƻ�ȡ UI �����
function _HM.UI.Base:Fetch(szName)
	local hP = self.wnd or self.self
	local ui = HM.UI.Fetch(hP, szName)
	if not ui and self.handle then
		ui = HM.UI.Fetch(self.handle, szName)
	end
	return ui
end

-- (number, number) Instance:Align()
-- (self) Instance:Align(number nHAlign, number nVAlign)
function _HM.UI.Base:Align(nHAlign, nVAlign)
	local txt = self.edit or self.txt
	if txt then
		if not nHAlign and not nVAlign then
			return txt:GetHAlign(), txt:GetVAlign()
		else
			if nHAlign then
				txt:SetHAlign(nHAlign)
			end
			if nVAlign then
				txt:SetVAlign(nVAlign)
			end
		end
	end
	return self
end

-- (number) Instance:Font()
-- (self) Instance:Font(number nFont)
function _HM.UI.Base:Font(nFont)
	local txt = self.edit or self.txt
	if txt then
		if not nFont then
			return txt:GetFontScheme()
		end
		txt:SetFontScheme(nFont)
	end
	return self
end

-- (number, number, number) Instance:Color()
-- (self) Instance:Color(number nRed, number nGreen, number nBlue)
function _HM.UI.Base:Color(nRed, nGreen, nBlue)
	if self.type == "Shadow" then
		if not nRed then
			return self.self:GetColorRGB()
		end
		self.self:SetColorRGB(nRed, nGreen, nBlue)
	else
		local txt = self.edit or self.txt
		if txt then
			if not nRed then
				return txt:GetFontColor()
			end
			txt:SetFontColor(nRed, nGreen, nBlue)
		end
	end
	return self
end

-- (number) Instance:Alpha()
-- (self) Instance:Alpha(number nAlpha)
function _HM.UI.Base:Alpha(nAlpha)
	local txt = self.edit or self.txt or self.self
	if txt then
		if not nAlpha then
			return txt:GetAlpha()
		end
		txt:SetAlpha(nAlpha)
	end
	return self
end

-------------------------------------
-- Dialog frame
-------------------------------------
_HM.UI.Frm = class(_HM.UI.Base)

-- constructor
function _HM.UI.Frm:ctor(szName, bEmpty)
	local frm, szIniFile = nil, "interface\\HM\\ui\\WndFrame.ini"
	if bEmpty then
		szIniFile = "interface\\HM\\ui\\WndFrameEmpty.ini"
	end
	if type(szName) == "string" then
		frm = Station.Lookup("Normal/" .. szName)
		if frm then
			Wnd.CloseWindow(frm)
		end
		frm = Wnd.OpenWindow(szIniFile, szName)
	else
		frm = Wnd.OpenWindow(szIniFile)
	end
	frm:Show()
	if not bEmpty then
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frm:Lookup("Btn_Close").OnLButtonClick = function()
			if frm.bClose then
				Wnd.CloseWindow(frm)
			else
				frm:Hide()
			end
		end
		self.wnd = frm:Lookup("Window_Main")
	end
	self.self, self.type = frm, "WndFrame"
end

-- (number, number) Instance:Size()						-- ȡ�ô����͸�
-- (self) Instance:Size(number nW, number nH)	-- ���ô���Ŀ�͸�
-- �ر�ע�⣺������С�߶�Ϊ 200������Զ����ӽ�ȡ  234/380/770 �е�һ��
function _HM.UI.Frm:Size(nW, nH)
	local frm = self.self
	if not nW then
		return frm:GetSize()
	end
	local hnd = frm:Lookup("", "")
	-- empty frame
	if not self.wnd then
		frm:SetSize(nW, nH)
		hnd:SetSize(nW, nH)
		return self
	end
	-- fix size
	if nW > 400 then
		nW = 770
		hnd:Lookup("Image_CBg1"):SetSize(385, 70)
		hnd:Lookup("Image_CBg2"):SetSize(384, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(2)
		hnd:Lookup("Image_CBg2"):SetFrame(2)
	elseif nW > 250 then
		nW = 380
		hnd:Lookup("Image_CBg1"):SetSize(190, 70)
		hnd:Lookup("Image_CBg2"):SetSize(189, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(1)
		hnd:Lookup("Image_CBg2"):SetFrame(1)
	else
		nW = 234
		hnd:Lookup("Image_CBg1"):SetSize(117, 70)
		hnd:Lookup("Image_CBg2"):SetSize(117, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(0)
		hnd:Lookup("Image_CBg2"):SetFrame(0)
	end
	if nH < 200 then nH = 200 end
	-- set size
	frm:SetSize(nW, nH)
	frm:SetDragArea(0, 0, nW, 70)
	hnd:SetSize(nW, nH)
	hnd:Lookup("Image_CBg3"):SetSize(8, nH - 160)
	hnd:Lookup("Image_CBg4"):SetSize(nW - 16, nH - 160)
	hnd:Lookup("Image_CBg5"):SetSize(8, nH - 160)
	hnd:Lookup("Image_CBg7"):SetSize(nW - 132, 85)
	hnd:Lookup("Text_Title"):SetSize(nW - 90, 30)
	hnd:FormatAllItemPos()
	frm:Lookup("Btn_Close"):SetRelPos(nW - 35, 15)
	self.wnd:SetSize(nW - 90, nH - 90)
	self.wnd:Lookup("", ""):SetSize(nW - 90, nH - 90)
	-- reset position
	local an = GetFrameAnchor(frm)
	frm:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	return self
end

-- (string) Instance:Title()					-- ȡ�ô������
-- (self) Instance:Title(string szTitle)	-- ���ô������
function _HM.UI.Frm:Title(szTitle)
	local ttl = self.self:Lookup("", "Text_Title")
	if not szTitle then
		return ttl:GetText()
	end
	ttl:SetText(szTitle)
	return self
end

-- (boolean) Instance:Drag()						-- �жϴ����Ƿ������
-- (self) Instance:Drag(boolean bEnable)	-- ���ô����Ƿ������
function _HM.UI.Frm:Drag(bEnable)
	local frm = self.self
	if bEnable == nil then
		return frm:IsDragable()
	end
	frm:EnableDrag(bEnable == true)
	return self
end

-- (string) Instance:Relation()
-- (self) Instance:Relation(string szName)	-- Normal/Lowest ...
function _HM.UI.Frm:Relation(szName)
	local frm = self.self
	if not szName then
		return frm:GetParent():GetName()
	end
	frm:ChangeRelation(szName)
	return self
end

-- (userdata) Instance:Lookup(...)
function _HM.UI.Frm:Lookup(...)
	local wnd = self.wnd or self.self
	return self.wnd:Lookup(...)
end

-------------------------------------
-- Window Component
-------------------------------------
_HM.UI.Wnd = class(_HM.UI.Base)

-- constructor
function _HM.UI.Wnd:ctor(pFrame, szType, szName)
	local wnd = nil
	if not szType and not szName then
		-- convert from raw object
		wnd, szType = pFrame, pFrame:GetType()
	else
		-- append from ini file
		local szFile = "interface\\HM\\ui\\" .. szType .. ".ini"
		local frame = Wnd.OpenWindow(szFile, "HM_Virtual")
		if not frame then
			return HM.Sysmsg(_L("Unable to open ini file [%s]", szFile))
		end
		wnd = frame:Lookup(szType)
		if not wnd then
			HM.Sysmsg(_L("Can not find wnd component [%s]", szType))
		else
			wnd:SetName(szName)
			wnd:ChangeRelation(pFrame, true, true)
		end
		Wnd.CloseWindow(frame)
	end
	if wnd then
		self.type = szType
		self.edit = wnd:Lookup("Edit_Default")
		self.handle = wnd:Lookup("", "")
		self.self = wnd
		if self.handle then
			self.txt = self.handle:Lookup("Text_Default")
		end
		if szType == "WndTrackBar" then
			local scroll = wnd:Lookup("Scroll_Track")
			scroll.nMin, scroll.nMax, scroll.szText = 0, scroll:GetStepCount(), self.txt:GetText()
			scroll.nVal = scroll.nMin
			self.txt:SetText(scroll.nVal .. scroll.szText)
			scroll.OnScrollBarPosChanged = function()
				this.nVal = this.nMin + math.ceil((this:GetScrollPos() / this:GetStepCount()) * (this.nMax - this.nMin))
				if this.OnScrollBarPosChanged_ then
					this.OnScrollBarPosChanged_(this.nVal)
				end
				self.txt:SetText(this.nVal .. this.szText)
			end
		end
	end
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _HM.UI.Wnd:Size(nW, nH)
	local wnd = self.self
	if not nW then
		local nW, nH = wnd:GetSize()
		if self.type == "WndRadioBox" or self.type == "WndCheckBox" or self.type == "WndTrackBar" then
			local xW, _ = self.txt:GetTextExtent()
			nW = nW + xW + 5
		end
		return nW, nH
	end
	if self.edit then
		wnd:SetSize(nW + 2, nH)
		self.handle:SetSize(nW + 2, nH)
		self.handle:Lookup("Image_Default"):SetSize(nW + 2, nH)
		self.edit:SetSize(nW, nH)
	else
		wnd:SetSize(nW, nH)
		if self.handle then
			self.handle:SetSize(nW, nH)
			if self.type == "WndButton" or self.type == "WndTabBox" then
				self.txt:SetSize(nW, nH)
			elseif self.type == "WndComboBox" then
				self.handle:Lookup("Image_ComboBoxBg"):SetSize(nW, nH)
				local btn = wnd:Lookup("Btn_ComboBox")
				local hnd = btn:Lookup("", "")
				local bW, bH = btn:GetSize()
				btn:SetRelPos(nW - bW - 5, math.ceil((nH - bH)/2))
				hnd:SetAbsPos(self.handle:GetAbsPos())
				hnd:SetSize(nW, nH)
				self.txt:SetSize(nW - math.ceil(bW/2), nH)
			elseif self.type == "WndCheckBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW - 20, math.floor((nH - xH)/2))
				self.handle:FormatAllItemPos()
			elseif self.type == "WndRadioBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW + 5, math.floor((nH - xH)/2))
				self.handle:FormatAllItemPos()
			elseif self.type == "WndTrackBar" then
				wnd:Lookup("Scroll_Track"):SetSize(nW, nH - 13)
				wnd:Lookup("Scroll_Track/Btn_Track"):SetSize(math.ceil(nW/5), nH - 13)
				self.handle:Lookup("Image_BG"):SetSize(nW, nH - 15)
				self.handle:Lookup("Text_Default"):SetRelPos(nW + 5, math.ceil((nH - 25)/2))
				self.handle:FormatAllItemPos()
			end
		end
	end
	return self
end

-- (boolean) Instance:Enable()
-- (self) Instance:Enable(boolean bEnable)
function _HM.UI.Wnd:Enable(bEnable)
	local wnd = self.edit or self.self
	local txt = self.edit or self.txt
	if bEnable == nil then
		if self.type == "WndButton" then
			return wnd:IsEnabled()
		end
		return self.enable ~= false
	end
	if bEnable then
		wnd:Enable(1)
		if txt and self.font then
			txt:SetFontScheme(self.font)
		end
		self.enable = true
	else
		wnd:Enable(0)
		if txt and self.enable ~= false then
			self.font = txt:GetFontScheme()
			txt:SetFontScheme(161)
		end
		self.enable = false
	end
	return self
end

-- (self) Instance:AutoSize([number hPad[, number vPad]])
function _HM.UI.Wnd:AutoSize(hPad, vPad)
	local wnd = self.self
	if self.type == "WndTabBox" or self.type == "WndButton" then
		local _, nH = wnd:GetSize()
		local nW, _ = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + nEx + 16, nH)
	elseif self.type == "WndComboBox" then
		local bW, _ = wnd:Lookup("Btn_ComboBox"):GetSize()
		local nW, nH = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + bW + 20, nH + 6)
	end
	return self
end

-- (boolean) Instance:Check()
-- (self) Instance:Check(boolean bCheck)
-- NOTICE��only for WndCheckBox
function _HM.UI.Wnd:Check(bCheck)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if bCheck == nil then
			return wnd:IsCheckBoxChecked()
		end
		wnd:Check(bCheck == true)
	end
	return self
end

-- (string) Instance:Group()
-- (self) Instance:Group(string szGroup)
-- NOTICE��only for WndCheckBox
function _HM.UI.Wnd:Group(szGroup)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if not szGroup then
			return wnd.group
		end
		wnd.group = szGroup
	end
	return self
end

-- (string) Instance:Url()
-- (self) Instance:Url(string szUrl)
-- NOTICE��only for WndWebPage
function _HM.UI.Wnd:Url(szUrl)
	local wnd = self.self
	if self.type == "WndWebPage" then
		if not szUrl then
			return wnd:GetLocationURL()
		end
		wnd:Navigate(szUrl)
	end
	return self
end

-- (number, number, number) Instance:Range()
-- (self) Instance:Range(number nMin, number nMax[, number nStep])
-- NOTICE��only for WndTrackBar
function _HM.UI.Wnd:Range(nMin, nMax, nStep)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nMin and not nMax then
			return scroll.nMin, scroll.nMax, scroll:GetStepCount()
		end
		if nMin then scroll.nMin = nMin end
		if nMax then scroll.nMax = nMax end
		if nStep then scroll:SetStepCount(nStep) end
		self:Value(scroll.nVal)
	end
	return self
end

-- (number) Instance:Value()
-- (self) Instance:Value(number nVal)
-- NOTICE��only for WndTrackBar
function _HM.UI.Wnd:Value(nVal)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nVal then
			return scroll.nVal
		end
		scroll.nVal = math.min(math.max(nVal, scroll.nMin), scroll.nMax)
		scroll:SetScrollPos(math.ceil((scroll.nVal - scroll.nMin) / (scroll.nMax - scroll.nMin) * scroll:GetStepCount()))
		self.txt:SetText(scroll.nVal .. scroll.szText)
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText[, boolean bDummy])
-- bDummy		-- ��Ϊ true ������������ onChange �¼�
function _HM.UI.Wnd:Text(szText, bDummy)
	local txt = self.edit or self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		if self.type == "WndTrackBar" then
			local scroll = self.self:Lookup("Scroll_Track")
			scroll.szText = szText
			txt:SetText(scroll.nVal .. scroll.szText)
		elseif self.type == "WndEdit" and bDummy then
			local fnChanged = txt.OnEditChanged
			txt.OnEditChanged = nil
			txt:SetText(szText)
			txt.OnEditChanged = fnChanged
		else
			txt:SetText(szText)
		end
		if self.type == "WndTabBox" then
			self:AutoSize()
		end
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for WndEdit
function _HM.UI.Wnd:Multi(bEnable)
	local edit = self.edit
	if edit then
		if bEnable == nil then
			return edit:IsMultiLine()
		end
		edit:SetMultiLine(bEnable == true)
	end
	return self
end

-- (number) Instance:Limit()
-- (self) Instance:Limit(number nLimit)
-- NOTICE: only for WndEdit
function _HM.UI.Wnd:Limit(nLimit)
	local edit = self.edit
	if edit then
		if not nLimit then
			return edit:GetLimit()
		end
		edit:SetLimit(nLimit)
	end
	return self
end

-- (self) Instance:Change()			-- �����༭���޸Ĵ�����
-- (self) Instance:Change(func fnAction)
-- NOTICE��only for WndEdit��WndTrackBar
function _HM.UI.Wnd:Change(fnAction)
	if self.type == "WndTrackBar" then
		self.self:Lookup("Scroll_Track").OnScrollBarPosChanged_ = fnAction
	elseif self.edit then
		local edit = self.edit
		if not fnAction then
			if edit.OnEditChanged then
				local _this = this
				this = edit
				edit.OnEditChanged()
				this = _this
			end
		else
			edit.OnEditChanged = function()
				if not this.bChanging then
					this.bChanging = true
					fnAction(this:GetText())
					this.bChanging = false
				end
			end
		end
	end
	return self
end

-- (self) Instance:Menu(table menu)		-- ���������˵�
-- NOTICE��only for WndComboBox
function _HM.UI.Wnd:Menu(menu)
	if self.type == "WndComboBox" then
		local wnd = self.self
		self:Click(function()
			local _menu = nil
			local nX, nY = wnd:GetAbsPos()
			local nW, nH = wnd:GetSize()
			if type(menu) == "function" then
				_menu = menu()
			else
				_menu = menu
			end
			_menu.nMiniWidth = nW
			_menu.x = nX
			_menu.y = nY + nH
			PopupMenu(_menu)
		end)
	end
	return self
end

-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction)	-- �����������󴥷�ִ�еĺ���
-- fnAction = function([bCheck])			-- ���� WndCheckBox �ᴫ�� bCheck �����Ƿ�ѡ
function _HM.UI.Wnd:Click(fnAction)
	local wnd = self.self
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd:GetType() == "WndCheckBox" then
		if not fnAction then
			self:Check(not self:Check())
		else
			wnd.OnCheckBoxCheck = function()
				if wnd.group then
					local uis = this:GetParent().___uis or {}
					for _, ui in pairs(uis) do
						if ui:Group() == this.group and ui:Name() ~= this:GetName() then
							ui:Check(false)
						end
					end
				end
				fnAction(true)
			end
			wnd.OnCheckBoxUncheck = function() fnAction(false) end
		end
	else
		if not fnAction then
			if wnd.OnLButtonClick then
				local _this = this
				this = wnd
				wnd.OnLButtonClick()
				this = _this
			end
		else
			wnd.OnLButtonClick = fnAction
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _HM.UI.Wnd:Hover(fnEnter, fnLeave)
	local wnd = wnd
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd then
		fnLeave = fnLeave or fnEnter
		if fnEnter then
			wnd.OnMouseEnter = function() fnEnter(true) end
		end
		if fnLeave then
			wnd.OnMouseLeave = function() fnLeave(false) end
		end
	end
	return self
end

-------------------------------------
-- Handle Item
-------------------------------------
_HM.UI.Item = class(_HM.UI.Base)

-- xml string
_HM.UI.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=257 </text>",
	["Image"] = "<image>w=100 h=100 eventid=257 </image>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </text>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>w=10 h=10</handle>",
	["Label"] = "<handle>w=150 h=30 eventid=257 <text>name=\"Text_Label\" w=150 h=30 font=162 valign=1 </text></handle>",
}

-- construct
function _HM.UI.Item:ctor(pHandle, szType, szName)
	local hnd = nil
	if not szType and not szName then
		-- convert from raw object
		hnd, szType = pHandle, pHandle:GetType()
	else
		local szXml = _HM.UI.tItemXML[szType]
		if szXml then
			-- append from xml
			local nCount = pHandle:GetItemCount()
			pHandle:AppendItemFromString(szXml)
			hnd = pHandle:Lookup(nCount)
			if hnd then hnd:SetName(szName) end
		else
			-- append from ini
			hnd = pHandle:AppendItemFromIni("interface\\HM\\ui\\HandleItems.ini","Handle_" .. szType, szName)
		end
		if not hnd then
			return HM.Sysmsg(_L("Unable to append handle item [%s]", szType))
		end
	end
	if szType == "BoxButton" then
		self.txt = hnd:Lookup("Text_BoxButton")
		self.img = hnd:Lookup("Image_BoxIco")
		hnd.OnItemMouseEnter = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Hide()
				this:Lookup("Image_BoxBgOver"):Show()
			end
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Show()
				this:Lookup("Image_BoxBgOver"):Hide()
			end
		end
	elseif szType == "TxtButton" then
		self.txt = hnd:Lookup("Text_TxtButton")
		self.img = hnd:Lookup("Image_TxtBg")
		hnd.OnItemMouseEnter = function()
			self.img:Show()
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				self.img:Hide()
			end
		end
	elseif szType == "Label" then
		self.txt = hnd:Lookup("Text_Label")
	elseif szType == "Text" then
		self.txt = hnd
	elseif szType == "Image" then
		self.img = hnd
	end
	self.self, self.type = hnd, szType
	hnd:SetRelPos(0, 0)
	hnd:GetParent():FormatAllItemPos()
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _HM.UI.Item:Size(nW, nH)
	local hnd = self.self
	if not nW then
		local nW, nH = hnd:GetSize()
		if self.type == "Text" or self.type == "Label" then
			nW, nH = self.txt:GetTextExtent()
		end
		return nW, nH
	end
	hnd:SetSize(nW, nH)
	if self.type == "BoxButton" then
		local nPad = math.ceil(nH * 0.2)
		hnd:Lookup("Image_BoxBg"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgOver"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgSel"):SetSize(nW - 1, nH + 11)
		self.img:SetSize(nH - nPad, nH - nPad)
		self.img:SetRelPos(10, math.ceil(nPad / 2))
		self.txt:SetSize(nW - nH - nPad, nH)
		self.txt:SetRelPos(nH + 10, 0)
		hnd:FormatAllItemPos()
	elseif self.type == "TxtButton" then
		self.img:SetSize(nW, nH - 5)
		self.txt:SetSize(nW - 10, nH - 5)
	elseif self.type == "Label" then
		self.txt:SetSize(nW, nH)
	end
	return self
end

-- (self) Instance:Zoom(boolean bEnable)	-- �Ƿ����õ����Ŵ�
-- NOTICE��only for BoxButton
function _HM.UI.Item:Zoom(bEnable)
	local hnd = self.self
	if self.type == "BoxButton" then
		local bg = hnd:Lookup("Image_BoxBg")
		local sel = hnd:Lookup("Image_BoxBgSel")
		if bEnable == true then
			local nW, nH = bg:GetSize()
			sel:SetSize(nW + 11, nH + 3)
			sel:SetRelPos(1, -5)
		else
			sel:SetSize(bg:GetSize())
			sel:SetRelPos(5, -2)
		end
		hnd:FormatAllItemPos()
	end
	return self
end

-- (self) Instance:Select()		-- ����ѡ�е�ǰ��Ŧ��������Ч����
-- NOTICE��only for BoxButton��TxtButton
function _HM.UI.Item:Select()
	local hnd = self.self
	if self.type == "BoxButton" or self.type == "TxtButton" then
		local hParent, nIndex = hnd:GetParent(), hnd:GetIndex()
		local nCount = hParent:GetItemCount() - 1
		for i = 0, nCount do
			local item = HM.UI.Fetch(hParent:Lookup(i))
			if item and item.type == self.type then
				if i == nIndex then
					if not item.self.bSelected then
						hnd.bSelected = true
						hnd.nIndex = i
						if self.type == "BoxButton" then
							hnd:Lookup("Image_BoxBg"):Hide()
							hnd:Lookup("Image_BoxBgOver"):Hide()
							hnd:Lookup("Image_BoxBgSel"):Show()
							self.txt:SetFontScheme(65)
							local icon = hnd:Lookup("Image_BoxIco")
							local nW, nH = icon:GetSize()
							local nX, nY = icon:GetRelPos()
							icon:SetSize(nW + 8, nH + 8)
							icon:SetRelPos(nX - 3, nY - 5)
							hnd:FormatAllItemPos()
						else
							self.img:Show()
						end
					end
				elseif item.self.bSelected then
					item.self.bSelected = false
					if item.type == "BoxButton" then
						item.self:SetIndex(item.self.nIndex)
						if hnd.nIndex >= item.self.nIndex then
							hnd.nIndex = hnd.nIndex + 1
						end
						item.self:Lookup("Image_BoxBg"):Show()
						item.self:Lookup("Image_BoxBgOver"):Hide()
						item.self:Lookup("Image_BoxBgSel"):Hide()
						item.txt:SetFontScheme(163)
						local icon = item.self:Lookup("Image_BoxIco")
						local nW, nH = icon:GetSize()
						local nX, nY = icon:GetRelPos()
						icon:SetSize(nW - 8, nH - 8)
						icon:SetRelPos(nX + 3, nY + 5)
						item.self:FormatAllItemPos()
					else
						item.img:Hide()
					end
				end
			end
		end
		if hnd.nIndex then
			hnd:SetIndex(nCount)
		end
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText)
function _HM.UI.Item:Text(szText)
	local txt = self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		txt:SetText(szText)
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for Text��Label
function _HM.UI.Item:Multi(bEnable)
	local txt = self.txt
	if txt then
		if bEnable == nil then
			return txt:IsMultiLine()
		end
		txt:SetMultiLine(bEnable == true)
	end
	return self
end

-- (self) Instance:File(string szUitexFile, number nFrame)
-- (self) Instance:File(string szTextureFile)
-- (self) Instance:File(number dwIcon)
-- NOTICE��only for Image��BoxButton
function _HM.UI.Item:File(szFile, nFrame)
	local img = nil
	if self.type == "Image" then
		img = self.self
	elseif self.type == "BoxButton" then
		img = self.img
	end
	if img then
		if type(szFile) == "number" then
			img:FromIconID(szFile)
		elseif not nFrame then
			img:FromTextureFile(szFile)
		else
			img:FromUITex(szFile, nFrame)
		end
	end
	return self
end

-- (self) Instance:Type()
-- (self) Instance:Type(number nType)		-- �޸�ͼƬ���ͻ� BoxButton �ı�������
-- NOTICE��only for Image��BoxButton
function _HM.UI.Item:Type(nType)
	local hnd = self.self
	if self.type == "Image" then
		if not nType then
			return hnd:GetImageType()
		end
		hnd:SetImageType(nType)
	elseif self.type == "BoxButton" then
		if nType == nil then
			local nFrame = hnd:Lookup("Image_BoxBg"):GetFrame()
			if nFrame == 16 then
				return 2
			elseif nFrame == 18 then
				return 1
			end
			return 0
		elseif nType == 0 then
			hnd:Lookup("Image_BoxBg"):SetFrame(1)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(2)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(3)
		elseif nType == 1 then
			hnd:Lookup("Image_BoxBg"):SetFrame(18)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(19)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(22)
		elseif nType == 2 then
			hnd:Lookup("Image_BoxBg"):SetFrame(16)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(17)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(15)
		end
	end
	return self
end

-- (self) Instance:Icon(number dwIcon)
-- NOTICE��only for Box��Image��BoxButton
function _HM.UI.Item:Icon(dwIcon)
	if self.type == "BoxButton" or self.type == "Image" then
		self.img:FromIconID(dwIcon)
	elseif self.type == "Box" then
		self.self:SetObjectIcon(dwIcon)
	end
	return self
end

-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction[, boolean bSound[, boolean bSelect]])	-- �Ǽ������������
-- (self) Instance:Click(func fnAction[, table tLinkColor[, tHoverColor]])		-- ͬ�ϣ�ֻ���ı�
function _HM.UI.Item:Click(fnAction, bSound, bSelect)
	local hnd = self.self
	--hnd:RegisterEvent(0x001)
	if not fnAction then
		if hnd.OnItemLButtonDown then
			local _this = this
			this = hnd
			hnd.OnItemLButtonDown()
			_this = this
		end
	elseif self.type == "BoxButton" or self.type == "TxtButton" then
		hnd.OnItemLButtonDown = function()
			if bSound then PlaySound(SOUND.UI_SOUND, g_sound.Button) end
			if bSelect then self:Select() end
			fnAction()
		end
	else
		hnd.OnItemLButtonDown = fnAction
		-- text link��tLinkColor��tHoverColor
		local txt = self.txt
		if txt then
			local tLinkColor = bSound or { 255, 255, 0 }
			local tHoverColor = bSelect or { 255, 200, 100 }
			txt:SetFontColor(unpack(tLinkColor))
			if tHoverColor then
				self:Hover(function(bIn)
					if bIn then
						txt:SetFontColor(unpack(tHoverColor))
					else
						txt:SetFontColor(unpack(tLinkColor))
					end
				end)
			end
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _HM.UI.Item:Hover(fnEnter, fnLeave)
	local hnd = self.self
	--hnd:RegisterEvent(0x300)
	fnLeave = fnLeave or fnEnter
	if fnEnter then
		hnd.OnItemMouseEnter = function() fnEnter(true) end
	end
	if fnLeave then
		hnd.OnItemMouseLeave = function() fnLeave(false) end
	end
	return self
end

---------------------------------------------------------------------
-- ������ API��HM.UI.xxx
---------------------------------------------------------------------
HM.UI = {}

-- ����Ԫ���������Ե����������ã���Ч���൱�� HM.UI.Fetch
setmetatable(HM.UI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

-- ����һ���յĶԻ�������棬������ HM.UI ��װ����
-- (class) HM.UI.OpenFrame([string szName, ]table tArg)
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С��ע���Ȼ��Զ����ͽ�����Ϊ��770/380/234���߶���С 200
--		x, y,			-- λ�����꣬Ĭ������Ļ���м�
--		title			-- �������
--		drag			-- ���ô����Ƿ���϶�
--		close		-- ����رհ�Ŧ���Ƿ������رմ��壨��Ϊ false �������أ�
--		empty		-- �����մ��壬����������ȫ͸����ֻ�ǽ�������
--		fnCreate = function(frame)		-- �򿪴����ĳ�ʼ��������frame Ϊ���ݴ��壬�ڴ���� UI
--		fnDestroy = function(frame)	-- �ر����ٴ���ʱ���ã�frame Ϊ���ݴ��壬���ڴ��������
-- }
-- ����ֵ��ͨ�õ�  HM.UI ���󣬿�ֱ�ӵ��÷�װ����
HM.UI.CreateFrame = function(szName, tArg)
	if type(szName) == "table" then
		szName, tArg = nil, szName
	end
	tArg = tArg or {}
	local ui = _HM.UI.Frm.new(szName, tArg.empty == true)
	-- apply init setting
	if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
	if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
	if tArg.title then ui:Title(tArg.title) end
	if tArg.drag ~= nil then ui:Drag(tArg.drag) end
	if tArg.close ~= nil then ui.self.bClose = tArg.close end
	if tArg.fnCreate then tArg.fnCreate(ui:Raw()) end
	if tArg.fnDestroy then ui.fnDestroy = tArg.fnDestroy end
	if tArg.parent then ui:Relation(tArg.parent) end
	return ui
end

-- �����մ���
HM.UI.CreateFrameEmpty = function(szName, szParent)
	return HM.UI.CreateFrame(szName, { empty  = true, parent = szParent })
end

-- ��ĳһ��������������  INI �����ļ��еĲ��֣������� HM.UI ��װ����
-- (class) HM.UI.Append(userdata hParent, string szIniFile, string szTag, string szName)
-- hParent		-- �����������ԭʼ����HM.UI ������ֱ����  :Append ������
-- szIniFile		-- INI �ļ�·��
-- szTag			-- Ҫ��ӵĶ���Դ�����������ڵĲ��� [XXXX]������ hParent ƥ����� Wnd ���������
-- szName		-- *��ѡ* �������ƣ�����ָ��������ԭ����
-- ����ֵ��ͨ�õ�  HM.UI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺�������Ҳ֧����Ӵ������
HM.UI.AppendIni = function(hParent, szFile, szTag, szName)
	local raw = nil
	if hParent:GetType() == "Handle" then
		if not szName then
			szName = "Child_" .. hParent:GetItemCount()
		end
		raw = hParent:AppendItemFromIni(szFile, szTag, szName)
	elseif string.sub(hParent:GetType(), 1, 3) == "Wnd" then
		local frame = Wnd.OpenWindow(szFile, "HM_Virtual")
		if frame then
			raw = frame:Lookup(szTag)
			if raw and string.sub(raw:GetType(), 1, 3) == "Wnd" then
				raw:ChangeRelation(hParent, true, true)
				if szName then
					raw:SetName(szName)
				end
			else
				raw = nil
			end
			Wnd.CloseWindow(frame)
		end
	end
	if not raw then
		HM.Sysmsg(_L("Fail to add component [%s@%s]", szTag, szFile))
	else
		return HM.UI.Fetch(raw)
	end
end

-- ��ĳһ�������������� HM.UI ��������ط�װ����
-- (class) HM.UI.Append(userdata hParent, string szType[, string szName], table tArg)
-- hParent		-- �����������ԭʼ����HM.UI ������ֱ����  :Append ������
-- szType			-- Ҫ��ӵ�������ͣ��磺WndWindow��WndEdit��Handle��Text ������
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ�����û�������
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С
--		x, y,			-- λ������
--		txt, font, multi, limit, align		-- �ı����ݣ����壬�Ƿ���У��������ƣ����뷽ʽ��0����1���У�2���ң�
--		color, alpha			-- ��ɫ����͸����
--		checked				-- �Ƿ�ѡ��CheckBox ר��
--		enable					-- �Ƿ�����
--		file, icon, type		-- ͼƬ�ļ���ַ��ͼ���ţ�����
--		group					-- ��ѡ���������
-- }
-- ����ֵ��ͨ�õ�  HM.UI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺Ϊͳһ�ӿڴ˺���Ҳ������ AppendIni �ļ��������� HM.UI.AppendIni һ��
-- (class) HM.UI.Append(userdata hParent, string szIniFile, string szTag, string szName)
HM.UI.Append = function(hParent, szType, szName, tArg)
	-- compatiable with AppendIni
	if StringFindW(szType, ".ini") ~= nil then
		return HM.UI.AppendIni(hParent, szType, szName, tArg)
	end
	-- reset parameters
	if not tArg and type(szName) == "table" then
		szName, tArg = nil, szName
	end
	if not szName then
		if not hParent.nAutoIndex then
			hParent.nAutoIndex = 1
		end
		szName = szType .. "_" .. hParent.nAutoIndex
		hParent.nAutoIndex = hParent.nAutoIndex + 1
	else
		szName = tostring(szName)
	end
	-- create ui
	local ui = nil
	if string.sub(szType, 1, 3) == "Wnd" then
		if string.sub(hParent:GetType(), 1, 3) ~= "Wnd" then
			return HM.Sysmsg(_L["The 1st arg for adding component must be a [WndXxx]"])
		end
		ui = _HM.UI.Wnd.new(hParent, szType, szName)
	else
		if hParent:GetType() ~= "Handle" then
			return HM.Sysmsg(_L["The 1st arg for adding item must be a [Handle]"])
		end
		ui = _HM.UI.Item.new(hParent, szType, szName)
	end
	local raw = ui:Raw()
	if raw then
		-- for reverse fetching
		hParent.___uis = hParent.___uis or {}
		for k, v in pairs(hParent.___uis) do
			if not v.self.___id then
				hParent.___uis[k] = nil
			end
		end
		hParent.___uis[szName] = ui
		hParent.___last = szName
		-- apply init setting
		tArg = tArg or {}
		if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
		if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
		if tArg.font then ui:Font(tArg.font) end
		if tArg.multi ~= nil then ui:Multi(tArg.multi) end
		if tArg.limit then ui:Limit(tArg.limit) end
		if tArg.color then ui:Color(unpack(tArg.color)) end
		if tArg.align ~= nil then ui:Align(tArg.align) end
		if tArg.alpha then ui:Alpha(tArg.alpha) end
		if tArg.txt then ui:Text(tArg.txt) end
		if tArg.checked ~= nil then ui:Check(tArg.checked) end
		-- wnd only
		if tArg.enable ~= nil then ui:Enable(tArg.enable) end
		if tArg.group then ui:Group(tArg.group) end
		if ui.type == "WndComboBox" and (not tArg.w or not tArg.h) then
			ui:Size(185, 25)
		end
		-- item only
		if tArg.file then ui:File(tArg.file, tArg.num) end
		if tArg.icon ~= nil then ui:Icon(tArg.icon) end
		if tArg.type then ui:Type(tArg.type) end
		return ui
	end
end

-- (class) HM.UI(...)
-- (class) HM.UI.Fetch(hRaw)						-- �� hRaw ԭʼ����ת��Ϊ HM.UI ��װ����
-- (class) HM.UI.Fetch(hParent, szName)	-- �� hParent ����ȡ��Ϊ szName ����Ԫ����ת��Ϊ HM.UI ����
-- ����ֵ��ͨ�õ�  HM.UI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
HM.UI.Fetch = function(hParent, szName)
	if type(hParent) == "string" then
		hParent = Station.Lookup(hParent)
	end
	if not szName then
		szName = hParent:GetName()
		hParent = hParent:GetParent()
	end
	-- exists
	if hParent.___uis and hParent.___uis[szName] then
		local ui = hParent.___uis[szName]
		if ui and ui.self.___id then
			return ui
		end
	end
	-- convert
	local hRaw = hParent:Lookup(szName)
	if hRaw then
		local ui
		if string.sub(hRaw:GetType(), 1, 3) == "Wnd" then
			ui = _HM.UI.Wnd.new(hRaw)
		else
			ui = _HM.UI.Item.new(hRaw)
		end
		hParent.___uis = hParent.___uis or {}
		hParent.___uis[szName] = ui
		return ui
	end
end

---------------------------------------------------------------------
-- ���������ص����� HM.OnXXX
---------------------------------------------------------------------
-- create frame
HM.OnFrameCreate = function()
	-- var
	_HM.frame = this
	_HM.hTotal = this:Lookup("Wnd_Content", "")
	_HM.hScroll = this:Lookup("Wnd_Content/Scroll_List")
	_HM.hList = _HM.hTotal:Lookup("Handle_List")
	_HM.hContent = _HM.hTotal:Lookup("Handle_Content")
	_HM.hBox = _HM.hTotal:Lookup("Box_1")
	-- title
	local szTitle =_HM.szTitle .. " v" .. HM.GetVersion() .. " (" .. HM.szBuildDate .. ")"
	_HM.hTotal:Lookup("Text_Title"):SetText(szTitle)
	-- position
	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	-- update list/detail
	_HM.UpdateTabBox(this)
	--_HM.UpdateDetail()
end

-- breathe
HM.OnFrameBreathe = function()
	-- run breathe calls
	local nFrame = GetLogicFrameCount()
	for k, v in pairs(_HM.tBreatheCall) do
		if nFrame >= v.nNext then
			v.nNext = nFrame + v.nFrame
			local res, err = pcall(v.fnAction)
			if not res then
				HM.Debug("BreatheCall#" .. k .." ERROR: " .. err)
			end
		end
	end
	-- run delay calls
	local nTime = GetTime()
	for k, v in ipairs(_HM.tDelayCall) do
		if v.nTime <= nTime then
			local res, err = pcall(v.fnAction)
			if not res then
				HM.Debug("DelayCall#" .. k .." ERROR: " .. err)
			end
			table.remove(_HM.tDelayCall, k)
		end
	end
	-- run player monitor
	_HM.SetTempTarget()
end

-- button click
HM.OnLButtonClick = function()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		_HM.ClosePanel()
	elseif szName == "Btn_Up" then
		_HM.hScroll:ScrollPrev(1)
	elseif szName == "Btn_Down" then
		_HM.hScroll:ScrollNext(1)
	end
end

-- scrolls
HM.OnScrollBarPosChanged = function()
	local handle, frame = _HM.hList, this:GetParent()
	local nPos = this:GetScrollPos()
	if nPos == 0 then
		frame:Lookup("Btn_Up"):Enable(0)
	else
		frame:Lookup("Btn_Up"):Enable(1)
	end
	if nPos == this:GetStepCount() then
		frame:Lookup("Btn_Down"):Enable(0)
	else
		frame:Lookup("Btn_Down"):Enable(1)
	end
    handle:SetItemStartRelPos(0, - nPos * 10)
end

-- web page title changed
HM.OnTitleChanged = function()
	local szUrl, szTitle = this:GetLocationURL(), this:GetLocationName()
	if szUrl ~= szTitle and _HM.tRequest[szUrl] then
		local fnAction = _HM.tRequest[szUrl]
		fnAction(szTitle)
		_HM.tRequest[szUrl] = nil
	end
end

---------------------------------------------------------------------
-- ע���¼�����ʼ��
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_ENTER_GAME", _HM.Init)
HM.RegisterEvent("LOADING_END", function()
	if _HM.tConflict then
		for _, v in ipairs(_HM.tConflict) do v() end
		_HM.tConflict = nil
		HM.Sysmsg(_L("%s are welcome to use HM plug-in", GetClientPlayer().szName) .. "/" .. HM.GetVersion())
	end
	-- reseting frame count (FIXED BUG FOR Cross Server)
	_HM.nTempFrame = nil
	for k, v in pairs(_HM.tBreatheCall) do
		v.nNext = GetLogicFrameCount()
	end
end)
HM.RegisterEvent("PLAYER_ENTER_SCENE", function() _HM.aPlayer[arg0] = true end)
HM.RegisterEvent("PLAYER_LEAVE_SCENE", function() _HM.aPlayer[arg0] = nil end)
HM.RegisterEvent("NPC_ENTER_SCENE", function() _HM.aNpc[arg0] = true end)
HM.RegisterEvent("NPC_LEAVE_SCENE", function() _HM.aNpc[arg0] = nil end)
HM.RegisterEvent("CUSTOM_DATA_LOADED", function()
	if arg0 == "Role" then
		for _, v in ipairs(_HM.tCustomUpdateCall) do
			if not v.nDate or v.nDate > HM.nBuildDate then
				v.fnAction()
			end
		end
		HM.nBuildDate = tonumber(_HM.szBuildDate)
	end
end)

-- player menu
HM.AppendPlayerMenu(function()
	return {
		szOption = _L["Open HM setting panel"] .. HM.GetHotKey("Total", true),
		bCheck = true, bChecked = _HM.frame and _HM.frame:IsVisible(),
		fnAction = _HM.TogglePanel
	}
end)
