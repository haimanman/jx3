--
-- 海鳗插件：秘密/Secret（来自身边朋友的秘密，匿名空间……）
--
HM_Secret = {
	bShowButton = true,
	bAutoSync = false,
}
HM.RegisterCustomData("HM_Secret")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Secret = {
	szName = "秘密/Secret",
	szIniFile = "interface\\HM\\HM_Secret\\HM_Secret.ini",
}

-- format time
--[[
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
	table.insert(t, "_=" .. GetCurrentTime())
	HM.RemoteRequest("http://jx3.hightman.cn/sr/" .. szAction .. ".php?" .. table.concat(t, "&"), function(szTitle, szContent)
		if fnCallback and szContent and szContent ~= "" then
			local data, err = HM.JsonDecode(szContent)
			if not data then
				--HM.Alert("解析 JSON 数据错误：" .. tostring(err), fnCallback)
				HM.Sysmsg("解析 JSON 数据错误：" .. tostring(err))
			elseif type(data) == "table" and data.error then
				--HM.Alert("服务端出错：" .. HM.UrlDecode(data.error), fnCallback)
				HM.Sysmsg("插件服务端出错：" .. HM.UrlDecode(data.error))
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
		-- add btn_face
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local btn = dummy:Lookup("Btn_Face")
		btn:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		btn:SetRelPos(270, 6)
		btn:SetSize(20, 20)
		btn:Show()
		btn.OnLButtonClick = function()
			local frame = Wnd.OpenWindow("EmotionPanel")
			local _, nH = frame:GetSize()
			local nX, nY = this:GetAbsPos()
			frame:SetAbsPos(nX, nY - nH)
			frame.bSecret = true
		end
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
	Wnd.CloseWindow("EmotionPanel")
	frm:Toggle(true)
	frm:Fetch("Btn_Submit"):Enable(true)
	Station.SetFocusWindow(frm:Fetch("Edit_Content"):Raw())
end

-- emotion hook
HM.BreatheCall("HM_Secret_Emotion", function()
	local frame = Station.Lookup("Normal/EmotionPanel")
	if frame and frame.bSecret then
		local hL = frame:Lookup("WndContainer_Page/Wnd_EM", "Handle_Image")
		local hI = hL:Lookup(0)
		if hI and hI.bFace and not hI.bSecret then
			hI.bSecret = true
			for i = 0, hL:GetItemCount() - 1, 1 do
				local hI = hL:Lookup(i)
				hI.OnItemLButtonClick = function()
					if _HM_Secret.eFrame and Station.Lookup("Normal/HM_Secret_Post"):IsVisible() then
						local edit = _HM_Secret.eFrame:Fetch("Edit_Content"):Raw()
						edit:InsertText(this.szCmd)
					elseif _HM_Secret.vFrame and Station.Lookup("Normal/HM_Secret_View"):IsVisible() and not _HM_Secret.vFrame.bForward then
						local edit = _HM_Secret.vFrame:Fetch("Edit_Comment"):Raw()
						if edit:GetText() == _HM_Secret.vFrame.ctip then
							edit:SetText(this.szCmd)
							edit:SetFontScheme(162)
						else
							edit:InsertText(this.szCmd)
						end
					else
						Wnd.CloseWindow(this:GetRoot())
					end
				end
			end
		end
	end
end)

-- set all child text node font
_HM_Secret.SetChildrenFont = function(h, nFont)
	for i = 0, h:GetItemCount() - 1, 1 do
		local t = h:Lookup(i)
		if t:GetType() == "Text" then
			t:SetFontScheme(nFont)
		end
	end
	h:FormatAllItemPos()
end

-- append rich text to handle
_HM_Secret.AppendRichText = function(h, szText, nFont, tColor)
	local t = HM.ParseFaceIcon({{ type = "text", text = szText }})
	local szXml, szDeco = "", " font=" .. (nFont or 41)
	if type(tColor) == "table" then
		szDeco = szDeco .. " r=" .. tColor[1] .. " g=" .. tColor[2] .. " b=" .. tColor[3]
	end
	local nS = 20, 20
	if Station.GetUIScale() < 0.8 then
		nS = math.floor(Station.GetUIScale()  / 0.8 * 20)
	end
	for _, v in ipairs(t) do
		if v.type == "text" then
			szXml = szXml .. "<text>text=" .. EncodeComponentsString(v.text) .. szDeco .. " </text>"
		elseif v.type == "emotion" then
			local r = g_tTable.FaceIcon:GetRow(v.id + 1)
			if not r then
				szXml = szXml .. "<text>text=" .. EncodeComponentsString(v.text) ..  szDeco .. " </text>"
			elseif r.szType == "animate" then
				szXml = szXml .. "<animate>path=" .. EncodeComponentsString(r.szImageFile) .. " disablescale=1 group=" .. r.nFrame .. " w=" .. nS .. " h=" .. nS .. " </animate>"
			else
				szXml = szXml .. "<image>path=" .. EncodeComponentsString(r.szImageFile) .. " disablescale=1 frame=" .. r.nFrame .. " w=" .. nS .. " h=" .. nS .. " </image>"
			end
		end
	end
	h:AppendItemFromString(szXml)
	h:FormatAllItemPos()
end

-- set rich text
_HM_Secret.SetRichText = function(h, ...)
	h:Clear()
	_HM_Secret.AppendRichText(h, ...)
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
	Wnd.CloseWindow("EmotionPanel")
	local frm = _HM_Secret.vFrame
	local hC = frm:Fetch("Handle_Content"):Raw()
	_HM_Secret.SetRichText(hC, string.gsub(data.content, "[\r\n]", ""), 201, { 255, 160, 255 })
	local nW, nH = hC:GetAllItemSize()
	hC:SetRelPos((680 - nW) / 2, (100 - nH) / 2)
	hC:GetParent():FormatAllItemPos()
	frm:Fetch("Text_Time"):Text(_HM_Secret.FormatTime(data.time_post) .. "，" .. data.cnum .. "条评论"):Toggle(true)
	frm.bForward = data.forward
	if data.forward then
		frm:Fetch("Edit_Comment"):Text("转发的秘密不可评论"):Enable(false):Toggle(true)
	else
		frm:Fetch("Edit_Comment"):Text(frm.ctip):Enable(true):Font(108):Toggle(true)
	end
	frm:Fetch("Btn_Comment"):Enable(data.forward == false):Toggle(true)
	frm:Fetch("Btn_Laud"):Text("赞(" .. data.znum .. ")"):Enable(data.lauded == false):Toggle(true)
	frm:Fetch("Btn_Hiss"):Text("嘘(" .. data.xnum .. ")"):Enable(data.hiss == false):Toggle(true)
	-- show comments
	local hnd =frm:Fetch("Handle_Comment")
	hnd:Raw():Clear()
	for _, v in ipairs(data.comments) do
		local h = hnd:Append("Handle3", { w = 665, h = 25 }):Raw()
		h:AppendItemFromString("<text>text=" .. EncodeComponentsString((v.owner or _L["<OUTER GUEST>"]) .. "：") .. " font=27 </text>")
		_HM_Secret.AppendRichText(h, v.content, 162)
		h:AppendItemFromString("<text>text=" .. EncodeComponentsString("  " .. _HM_Secret.FormatTime(v.time_post)) .. " font=108 </text>")
		h:FormatAllItemPos()
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
		frm:Append("Handle3", "Handle_Content", { x = 0, y = 0, w = 680, h = 100 })
		frm:Append("Text", "Text_Time", { x = 0, y = 100 })
		frm:Append("WndEdit", "Edit_Comment", { x = 160, y = 100, w = 296, h = 25, limit = 60 })
		frm:Append("WndButton", "Btn_Comment", { txt = "发表", x = 480, y = 100, w = 70, h = 26 }):Click(function()
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
		frm:Append("WndButton", "Btn_Laud", { txt = "赞(99)", x = 550, y = 100, w = 70, h = 26 }):Click(function()
			_HM_Secret.RemoteCall("laud", { d = frm.id, o = frm.name }, function(data)
				_HM_Secret.ShowOne(data)
				_HM_Secret.PostNotify(frm.id, nil, true)
			end)
		end)
		frm:Append("WndButton", "Btn_Hiss", { txt = "嘘(0)", x = 620, y = 100, w = 60, h = 26, font = 166 }):Click(function()
			_HM_Secret.RemoteCall("hiss", { d = frm.id, o = frm.name }, function(data)
				if type(data) == "table" then
					-- refresh
					_HM_Secret.ShowOne(data)
				else
					-- deleted
					frm:Toggle(false)
					_HM_Secret.LoadList()
				end
			end)
		end)
		-- add btn_face
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local btn = dummy:Lookup("Btn_Face")
		btn:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		btn:SetRelPos(454, 100)
		btn:SetSize(20, 25)
		btn:Show()
		btn.OnLButtonClick = function()
			local frame = Wnd.OpenWindow("EmotionPanel")
			local _, nH = frame:GetSize()
			local nX, nY = this:GetAbsPos()
			frame:SetAbsPos(nX, nY - nH)
			frame.bSecret = true
		end
		-- comments: 25*8
		frm:Append("Handle3", "Handle_Comment", { x= 0, y = 140, w = 665, h = 200 }):Raw():RegisterEvent(2048)
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
	frm:Fetch("Handle_Content"):Raw():Clear()
	frm:Fetch("Handle_Content"):Append("Text", { txt = "Loading...", x = 20, y = 20 })
	frm:Fetch("Handle_Content"):Raw():FormatAllItemPos()
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
	hI.new = data.new
	hI:Lookup("Text_Time"):SetText(_HM_Secret.FormatTime(data.time_update))
	_HM_Secret.SetRichText(hI:Lookup("Handle_Content"), data.content, (hI.new and 40) or 41)
	if hI.new then
		hI:Lookup("Text_Time"):SetFontScheme(40)
	end
	hI.OnItemMouseEnter = function() this:Lookup("Image_Light"):Show() end
	hI.OnItemMouseLeave = function() this:Lookup("Image_Light"):Hide() end
	hI.OnItemLButtonDown = function()
		_HM_Secret.ReadOne(this.id)
		if this.new then
			_HM_Secret.SetChildrenFont(this:Lookup("Handle_Content"), 41)
			this:Lookup("Text_Time"):SetFontScheme(41)
			this.new = false
		end
	end
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
--]]
-------------------------------------
-- 事件处理
-------------------------------------
local ROOT_URL = "https://haimanchajian.com"
local CLIENT_LANG = select(3, GetVersion())

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Secret.PS = {}

-- init
_HM_Secret.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- buttons
	--nX = ui:Append("WndButton", { x = 0, y = 0, txt = "刷新列表" }):Click(_HM_Secret.LoadList):Pos_()
	--nX = ui:Append("WndButton", { x = nX, y = 0, txt = "发布秘密" }):Click(_HM_Secret.PostNew):Pos_()
	-- Tips
	ui:Append("Text", { x = 0, y = 0, txt = "海鳗秘密", font = 27 })
	nX = ui:Append("Text", { x = 0, y = 28, txt = "树洞、吐槽、趣事分享，关注微信公众号【" }):Pos_()
	nX = ui:Append("Text", { x = nX, y = 28, txt = "海鳗插件", font = 51 }):Hover(function()
		local x, y = Cursor.GetPos()
		OutputTip(GetFormatImage("interface\\HM\\HM_0Base\\image.UiTex", 2, 148, 148), 200, {x, y, 0, 0})
	end, function()
		HideTip()
	end):Pos_()
	ui:Append("Text", { x = nX, y = 0 + 28, txt = "】后访问。" })
	--ui:Append("Text", { x = 0, y = 378, txt = "小提示：包括插件作者在内任何人都无法知道秘密的来源，请放心发布。", font = 47 })
	-- tips
	--ui:Append("Image", "Image_Wechat", { x = 0, y = 36 + 164, w = 150, h = 150 }):File("interface\\HM\\HM_0Base\\image.UiTex", 2)
	-- verify
	ui:Append("Text", { x = 0, y = 214 - 134, txt = "海鳗插件认证", font = 27 })
	ui:Append("Text", "Text_Verify", { x = 0, y = 242 - 134, txt = "loading...", font = 47 })
	nX = ui:Append("Text", { x= 0, y = 276 - 134, txt = "认证选项：" }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Basic", { x = nX, y = 276 - 134, txt = "区服体型", checked = true, enable = false }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Name", { x = nX + 10, y = 276 - 134, txt = "角色名", checked = true }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Equip", { x = nX + 10, y = 276 - 134, txt = "武器&坐骑", checked = true }):Pos_()
	nX = ui:Append("WndButton", "Btn_Delete", { x = 0, y =  312 - 134, txt = "解除认证", enable = false }):Click(function()
		HM.Confirm("确定要解除认证吗？", function()
			local data = {}
			data.gid = GetClientPlayer().GetGlobalID()
			data.isOpenVerify = "0"
			HM.PostJson(ROOT_URL .. "/api/data/roles", data):done(function(res)
				HM_Secret.bAutoSync = false
				HM.OpenPanel(_HM_Secret.szName)
			end)
		end)
	end):Pos_()
	nX = ui:Append("WndButton", "Btn_Submit", { x = nX + 10, y =  312 - 134, txt = "立即认证" }):Click(function()
		local btn = ui:Fetch("Btn_Submit")
		local data = HM_About.GetSyncData()
		data.isOpenName = ui:Fetch("Check_Name"):Check() and 1 or 0
		data.isOpenEquip = ui:Fetch("Check_Equip"):Check() and 1 or 0
		data.__qrcode = "1"
		btn:Enable(false)
		if GetClientPlayer().nLevel < 95 then
			return HM.Alert(g_tStrings.tCraftResultString[CRAFT_RESULT_CODE.TOO_LOW_LEVEL])
		end
		HM.PostJson(ROOT_URL .. "/api/data/roles", data):done(function(res)
			HM_Secret.bAutoSync = true
			if not res then
				-- unknown error
			elseif res.errcode ~= 0 then
				ui:Fetch("Text_Verify"):Text(res.errmsg):Color(255, 0, 0)
			elseif res.qrcode then
				local w, h = 240, 240
				local frm = HM.UI.CreateFrame("HM_ImageView", { w = w + 90, h = h + 90 + 20, bgcolor = {222, 210, 190, 240}, title = _L["Scan by wechat"], close = true })
				frm:Append("Image", { x = 0, y = 0, w = w, h = h }):Raw():FromRemoteFile(res.qrcode:gsub("https:", "http:"), true)
				frm:Append("Text", { x = 0, y = h + 10, w = w, h = 36, align = 1, font = 6, txt = "微信扫码完成认证" })
				frm:Raw():GetRoot():SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
				ui:Fetch("Image_Wechat"):Toggle(false)
				ui:Fetch("Text_Verify"):Text("扫码后请点击左侧菜单刷新")
			elseif res.errcode ~= 0 then
				ui:Fetch("Text_Verify"):Text(res.errmsg):Color(255, 0, 0)
			end
			btn:Text("重新认证")
			btn:Enable(true)
		end)
	end):Pos_()
	-- /api/data/roles/{gid}
	_HM_Secret.PS.active = true
	HM.GetJson(ROOT_URL .. "/api/data/roles/" .. GetClientPlayer().GetGlobalID()):done(function(res)
		if not _HM_Secret.PS.active then
			return
		end
		if res.verify then
			local szText = res.verify .. " (" .. FormatTime("%Y/%m/%d %H:%M", res.time_update) .. ")"
			ui:Fetch("Text_Verify"):Text(szText)
			ui:Fetch("Check_Name"):Check(res.open_name == true)
			ui:Fetch("Check_Equip"):Check(res.open_equip == true)
			ui:Fetch("Btn_Delete"):Enable(true)
			ui:Fetch("Btn_Submit"):Text("重新认证")
			HM_Secret.bAutoSync = true
		else
			ui:Fetch("Text_Verify"):Text("<未认证>"):Color(255, 0, 0)
		end
	end):fail(function()
		if not _HM_Secret.PS.active then
			return
		end
		ui:Fetch("Text_Verify"):Text(_L["Request failed"]):Color(255, 0, 0)
	end)
	do return end
	--[[
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
	-- add checkbox
	ui:Append("WndCheckBox", { x = 206, y = 32, font = 47, txt = "在小地图显示未读通知", checked = HM_Secret.bShowButton }):Click(function(bChecked)
		HM_Secret.bShowButton = bChecked
		local btn = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over/Btn_Secret")
		if btn then
			if bChecked then
				btn:Show()
			else
				btn:Hide()
			end
		end
	end)
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
	--]]
end

_HM_Secret.PS.OnPanelDeactive = function()
	_HM_Secret.PS.active = nil
end
--[[
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
		btn:SetRelPos(28, 178)
		btn:Show()
		btn.OnLButtonClick = function()
			this:Lookup("", ""):Hide()
			HM.OpenPanel(_HM_Secret.szName)
		end
	end
	if not HM_Secret.bShowButton then
		return btn:Hide()
	else
		btn:Show()
	end
	-- get unread
	local me = GetClientPlayer()
	if IsRemotePlayer(me.dwID) then
		return
	end
	_HM_Secret.RemoteCall("unread", { o = me.szName .. "-" .. me.dwID }, function(nNum)
		local h = btn:Lookup("", "")
		if not nNum or nNum == 0 then
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
--]]

-- sync events
HM.RegisterEvent("FIRST_LOADING_END", function()
	if HM_Secret.bAutoSync then
		local data = HM_About.GetSyncData()
		HM.PostJson(ROOT_URL .. "/api/data/roles", data)
	end
end)

-- add to HM collector
HM.RegisterPanel(_HM_Secret.szName, 2, _L["Recreation"], _HM_Secret.PS)
