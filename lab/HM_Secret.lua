--
-- 海鳗插件：秘密/Secret（来自身边朋友的秘密，匿名空间……）
--
HM_Secret = {}

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
_HM_Secret = {
	szName = "秘密/Secret",
	szIniFile = "interface\\HM\\ui\\HM_Secret.ini",
}

-- format time
_HM_Secret.FormatTime = function(nTime)
	local nNow = GetCurrentTime()
	nTime = nNow - (tonumber(nTime) or nNow)
	if nTime < 60 then
		return "刚刚"
	elseif nTime < 3600 then
		return string.format("%d分钟前", nTime / 60)
	elseif nTime < 86400 then
		return string.format("%d小时前", nTime / 3600)
	else
		return string.format("%d天前", nTime / 86400)
	end
end

-- 解码整个 table
_HM_Secret.TableDecode = function(t)
	if type(t) == "table" then
		for k, v in pairs(t) do
			if type(v) == "table" then
				_HM_Secret.TableDecode(v)
			elseif type(v) == "string" and string.find(v, "%", 1, 1) then
				t[k] = HM.UrlDecode(v)
			end
		end
	end
end

-- 远程请求并解析 urlencoed-JSON，出错时自动弹 alert
_HM_Secret.RemoteCall = function(szAction, tParam, fnCallback)
	local t = {}
	for k, v in pairs(tParam) do
		table.insert(t, k .. "=" .. HM.UrlEncode(tostring(v)))
	end
	HM.RemoteRequest("http://jx3.hightman.cn/sr/" .. szAction .. ".php?" .. table.concat(t, "&"), function(szTitle, szContent)
		if fnCallback then
			local data, err = HM.JsonDecode(szContent)
			if not data then
				HM.Alert("解析 JSON 数据错误：" .. tostring(err), fnCallback)
			elseif type(data) == "table" and data.error then
				HM.Alert("服务端出错：" .. HM.UrlDecode(data.error), fnCallback)
			else
				_HM_Secret.TableDecode(data)
				pcall(fnCallback, data)
			end
		end
	end)
end

-- post notify (myself + friend ids)
_HM_Secret.PostNotify = function(dwID, fnAction, bForward)
	local me, t = GetClientPlayer(), {}
	local aGroup = me.GetFellowshipGroupInfo() or {}
	local szList = me.szName .. "-" .. me.dwID
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if szList == "" then
				szList = vv.name .. "-" .. vv.id
			else
				szList = szList .. "," .. vv.name .. "-" .. vv.id
				if string.len(szList) > 512 then
					table.insert(t, szList)
					szList = ""
				end
			end
		end
	end
	if szList ~= "" then
		table.insert(t, szList)
	end
	for i = 1, #t, 1 do
		_HM_Secret.RemoteCall("notify", { d = dwID, f = t[i], z = bForward and 1 }, i == #t and fnAction)
	end
end

-- post new
_HM_Secret.PostNew = function()
	local frm = _HM_Secret.eFrame
	if not frm then
		local nMaxLen, szFormatLen = 198, "字数：%d/%d"
		frm = HM.UI.CreateFrame("HM_Secret_Post", { close = false, w = 380, h = 360, title = "写下您的小秘密", drag = true })
		frm:Append("Text", "Text_Length", { txt = szFormatLen:format(0, nMaxLen), x = 0, y = 0, font = 27 })
		frm:Append("WndEdit", "Edit_Content", { x = 0, y = 28, limit = nMaxLen, w = 290, h = 140, multi = true }):Change(function(szText)
			frm:Fetch("Text_Length"):Text(string.format(szFormatLen, string.len(szText), nMaxLen))
		end)
		-- buttons
		frm:Append("WndButton", "Btn_Submit", { txt = "发布", x = 45, y = 180 }):Click(function()
			local szContent = frm:Fetch("Edit_Content"):Text()
			_HM_Secret.RemoteCall("post", { c = szContent }, function(data)
				if not data then
					frm:Fetch("Btn_Submit"):Enable(true)
				else
					_HM_Secret.PostNotify(data, function()
						_HM_Secret.LoadList()
						frm:Toggle(false)
						frm:Fetch("Edit_Content"):Text("")
					end)
				end
			end)
			frm:Fetch("Btn_Submit"):Enable(false)
		end)
		frm:Append("WndButton", "Btn_Cancel", { txt = "取消", x = 145, y = 180 }):Click(function()
			frm:Toggle(false)
		end)
		frm:Append("Text", { txt = "提示：发出的秘密只有自己和好友能看到，并且没有人能知道谁发布的。", x = 0, y = 214, font = 47, multi = true, w = 290, h = 50 })
		_HM_Secret.eFrame = frm
	end
	if _HM_Secret.vFrame then
		_HM_Secret.vFrame:Toggle(false)
	end
	frm:Toggle(true)
	frm:Fetch("Btn_Submit"):Enable(true)
	Station.SetFocusWindow(frm:Fetch("Edit_Content"):Raw())
end

-- post comment
_HM_Secret.CommentOne = function(dwID)
end

-- update comment scroll (nH = 31)
_HM_Secret.UpdateListScroll = function(scroll, handle, nH, nPos)
	local w, h = handle:GetSize()
	local wA, hA = handle:GetAllItemSize()
	local nStep = math.ceil((hA - h) / nH)
	scroll:SetStepCount(nStep)
	if nStep > 0 then
		scroll:Show()
	else
		scroll:Hide()
	end
	if nPos then
		scroll:SetScrollPos(nPos)
	end
	if scroll:GetScrollPos() > nStep then
		scroll:SetScrollPos(nStep)
	end
end

-- show one
_HM_Secret.ShowOne = function(data)
	if not data then
		return
	end
	local frm = _HM_Secret.vFrame
	frm:Fetch("Text_Content"):Text(string.gsub(data.content, "[\r\n]", ""))
	frm:Fetch("Text_Time"):Text(_HM_Secret.FormatTime(data.time_post) .. "，" .. data.cnum .. "条评论"):Toggle(true)
	if data.forward then
		frm:Fetch("Edit_Comment"):Text("转发的秘密不可评论"):Enable(false):Toggle(true)
	else
		frm:Fetch("Edit_Comment"):Text(frm.ctip):Enable(true):Font(108):Toggle(true)
	end
	frm:Fetch("Btn_Comment"):Enable(data.forward == false):Toggle(true)
	frm:Fetch("Btn_Laud"):Text("赞(" .. data.znum .. ")"):Enable(data.lauded == false):Toggle(true)
	-- show comments
	local hnd =frm:Fetch("Handle_Comment")
	hnd:Raw():Clear()
	for _, v in ipairs(data.comments) do
		local h = hnd:Append("Handle2", { w = 665, h = 25 })
		local x = h:Append("Text", { x = 0, y = 0, font = 27 }):Text((v.owner or _L["<OUTER GUEST>"]) .. "："):Pos_()
		x = h:Append("Text", { x = x, y = 0, txt = v.content }):Pos_()
		h:Append("Text", { x = x + 10, y = 0, font = 108 }):Text(_HM_Secret.FormatTime(v.time_post)):Raw():SetFontScale(0.9)
	end
	hnd:Raw():FormatAllItemPos()
	-- update coments scrollbar
	_HM_Secret.UpdateListScroll(frm:Fetch("Scroll_List"):Raw(), hnd:Raw(), 25, 0)
	frm.bLoading = false
end

-- read one
_HM_Secret.ReadOne = function(dwID)
	local frm = _HM_Secret.vFrame
	if not frm then
		local me = GetClientPlayer()
		frm = HM.UI.CreateFrame("HM_Secret_View", { close = false, w = 770, h = 430, title = "阅读秘密", drag = true })
		frm.name = me.szName .. "-" .. me.dwID
		frm:Append("Image", { x = 0, y = 130, w = 680, h = 3 }):File("ui\\Image\\Minimap\\MapMark.UITex", 65)		
		frm:Append("Text", "Text_Content", { x = 0, y = 0, w = 680, h = 100, font = 27, font = 201, multi = true }):Color(255, 160, 255):Align(1, 1):Raw():SetCenterEachLine(true)
		frm:Append("Text", "Text_Time", { x = 0, y = 100 })
		frm:Append("WndEdit", "Edit_Comment", { x = 180, y = 100, w = 296, h = 25, limit = 60 })
		frm:Append("WndButton", "Btn_Comment", { txt = "发表", x = 480, y = 100 }):Click(function()
			local szContent = frm:Fetch("Edit_Comment"):Text()
			if szContent == frm.ctip then
				return
			end
			local szRealName = nil
			if string.sub(szContent, 1, 1) == "@" then
				szRealName = "1"
				szContent = string.sub(szContent, 2)
			end
			_HM_Secret.RemoteCall("comment", { d = frm.id, o = frm.name, c = szContent, r = szRealName }, _HM_Secret.ShowOne)
		end)
		frm:Append("WndButton", "Btn_Laud", { txt = "赞 (100)", x = 580, y = 100 }):Click(function()
			_HM_Secret.RemoteCall("laud", { d = frm.id, o = frm.name }, function(data)
				_HM_Secret.ShowOne(data)
				_HM_Secret.PostNotify(frm.id, nil, true)
			end)
		end)
		-- comments: 25*8
		frm.handle:AppendItemFromString("<handle>name=\"Handle_Comment\" handletype=3 pixelscroll=1 w=665 h=200 eventid=2048 </handle>")
		frm:Fetch("Handle_Comment"):Pos(0, 140)
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local scroll = dummy:Lookup("Wnd_Result/Scroll_List")
		scroll:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		scroll:SetRelPos(665, 140)
		scroll:SetSize(15, 200)
		scroll.OnScrollBarPosChanged = function()
			local nPos = this:GetScrollPos()
			local handle =frm.handle:Lookup("Handle_Comment")
			handle:SetItemStartRelPos(0, - nPos * 25)
		end
		frm.handle:Lookup("Handle_Comment").OnItemMouseWheel = function()
			if scroll:IsVisible() then
				scroll:ScrollNext(Station.GetMessageWheelDelta())
				return true
			end
		end
		frm.ctip = "以@开头的评论则不匿名 -_-"
		frm:Fetch("Edit_Comment"):Raw().OnSetFocus = function()
			if this:GetText() == frm.ctip then
				this:SetText("")
				this:SetFontScheme(162)
			end
		end
		frm:Fetch("Edit_Comment"):Raw().OnKillFocus = function()
			if this:GetText() == "" then
				this:SetText(frm.ctip)
				this:SetFontScheme(108)
			end
		end
		_HM_Secret.vFrame = frm
	end
	if frm.bLoading then
		return
	end
	frm.bLoading = true
	if _HM_Secret.eFrame then
		_HM_Secret.eFrame:Toggle(false)
	end
	-- hide all things
	frm:Fetch("Text_Content"):Text("Loading...")
	frm:Fetch("Text_Time"):Toggle(false)
	frm:Fetch("Edit_Comment"):Toggle(false)
	frm:Fetch("Btn_Comment"):Toggle(false)
	frm:Fetch("Btn_Laud"):Toggle(false)
	frm:Toggle(true)
	frm.id = dwID
	-- remote call
	_HM_Secret.RemoteCall("read", { d = dwID, o = frm.name }, _HM_Secret.ShowOne)
end

-- draw one item
_HM_Secret.AddTableRow = function(data)
	local hI = _HM_Secret.handle:AppendItemFromIni(_HM_Secret.szIniFile, "Handle_Item")
	hI.id = data.id
	hI:Lookup("Text_Time"):SetText(_HM_Secret.FormatTime(data.time_update))
	hI:Lookup("Text_Content"):SetText(data.content)
	if data.new then
		hI:Lookup("Text_Time"):SetFontScheme(40)
		hI:Lookup("Text_Content"):SetFontScheme(40)
	end
	hI.OnItemMouseEnter = function() this:Lookup("Image_Light"):Show() end
	hI.OnItemMouseLeave = function() this:Lookup("Image_Light"):Hide() end
	hI.OnItemLButtonDown = function() _HM_Secret.ReadOne(this.id) end
	hI:Show()
end

-- draw list
_HM_Secret.DrawTable = function(data_all)
	_HM_Secret.loading:Hide()
	_HM_Secret.handle:Clear()
	for _, v in ipairs(data_all) do
		_HM_Secret.AddTableRow(v)
	end
	_HM_Secret.handle:FormatAllItemPos()
	_HM_Secret.UpdateListScroll(_HM_Secret.win:Lookup("Scroll_List"), _HM_Secret.handle, 31, 0)
end

-- load lsit
_HM_Secret.LoadList = function()
	local me = GetClientPlayer()
	_HM_Secret.handle:Clear()
	_HM_Secret.loading:Show()
	if IsRemotePlayer(me.dwID) then
		return HM.Alert("跨服中，暂不支持该功能！")
	end
	_HM_Secret.RemoteCall("list", { o = me.szName .. "-" .. me.dwID }, _HM_Secret.DrawTable)
end

-------------------------------------
-- 事件处理
-------------------------------------

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Secret.PS = {}

-- init
_HM_Secret.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- buttons
	nX = ui:Append("WndButton", { x = 0, y = 0, txt = "刷新列表" }):Click(_HM_Secret.LoadList):Pos_()
	nX = ui:Append("WndButton", { x = nX, y = 0, txt = "发布秘密" }):Click(_HM_Secret.PostNew):Pos_()
	-- Tips
	ui:Append("Text", { x = nX + 10, y = 0, txt = "这不是树洞，秘密就来自你身边的朋友。", font = 27 })
	ui:Append("Text", { x = 0, y = 378, txt = "小提示：包括插件作者在内任何人都无法知道秘密的来源，请放心发布。", font = 47 })
	-- table frame
	local fx = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret")
	local win = fx:Lookup("Wnd_Result")
	win:ChangeRelation(frame, true, true)
	Wnd.CloseWindow(fx)
	win:SetRelPos(0, 32)
	win:Lookup("", "Text_TimeTitle"):SetText("发布/更新")
	win:Lookup("", "Text_ContentTitle"):SetText("内容摘要")
	_HM_Secret.win = win
	_HM_Secret.handle = win:Lookup("", "Handle_List")
	_HM_Secret.loading = win:Lookup("", "Text_Loading")
	-- scroll
	win:Lookup("Scroll_List").OnScrollBarPosChanged = function()
		local nPos = this:GetScrollPos()
		_HM_Secret.handle:SetItemStartRelPos(0, - nPos * 31)
	end
	_HM_Secret.handle.OnItemMouseWheel = function()
		local scroll = win:Lookup("Scroll_List")
		if scroll:IsVisible() then
			scroll:ScrollNext(Station.GetMessageWheelDelta())
			return true
		end
	end
	_HM_Secret.LoadList()
end

-- deinit
_HM_Secret.PS.OnPanelDeactive = function(frame)
	_HM_Secret.handle =nil
	_HM_Secret.loading = nil
	_HM_Secret.win = nil
	if _HM_Secret.eFrame then
		_HM_Secret.eFrame:Toggle(false)
	end
	if _HM_Secret.vFrame then
		_HM_Secret.vFrame:Toggle(false)
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("LOADING_END", function()
	-- attach button
	local win = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over")
	local btn = win:Lookup("Btn_Secret")
	if not btn then
		local frame = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		btn = frame:Lookup("Btn_Secret")
		btn:ChangeRelation(win, true, true)
		Wnd.CloseWindow(frame)
		btn:SetRelPos(-12, 84)
		btn:Show()
		btn.OnLButtonClick = function()
			this:Lookup("", ""):Hide()
			HM.OpenPanel(_HM_Secret.szName)
		end
	end
	-- get unread
	local me = GetClientPlayer()
	if IsRemotePlayer(me.dwID) then
		return
	end
	_HM_Secret.RemoteCall("unread", { o = me.szName .. "-" .. me.dwID }, function(nNum)
		local h = btn:Lookup("", "")
		if nNum == 0 then
			h:Hide()
		else
			if nNum > 9 then
				nNum = 9
			end
			h:Lookup("Text_News"):SetText(tostring(nNum))
			h:Show()
		end
	end)
end)

-- add to HM collector
HM.RegisterPanel(_HM_Secret.szName, 2, "开发", _HM_Secret.PS)

