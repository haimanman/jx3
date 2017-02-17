--
-- 海鳗插件：成就百科，源于菊花插件
--
local ACHI_ANCHOR  = { s = "CENTER", r = "CENTER", x = 0, y = 0 }
local ACHI_ROOT_URL = "https://haimanchajian.com"
local ACHI_CLIENT_LANG = select(3, GetVersion())
local Achievement = {}
local tinsert = table.insert

HM_AchieveWiki = {
	bAutoSync = false,
	nSyncPoint = 0,
}
HM.RegisterCustomData("HM_AchieveWiki")

---------------------------------------------------------------------
-- 百科阅读界面
---------------------------------------------------------------------
function HM_AchieveWiki.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	RegisterGlobalEsc("HM_AchieveWiki", Achievement.IsOpened, Achievement.ClosePanel)
	
	local handle = this:Lookup("", "")
	this.pedia = this:Lookup("WndScroll_Pedia", "")
	this.link = handle:Lookup("Text_Link")
	this.title = handle:Lookup("Text_Title")
	this.desc = handle:Lookup("Text_Desc")
	this.box = handle:Lookup("Box_Icon")
	this:Lookup("Btn_Edit"):Lookup("", "Text_Edit"):SetText(_L["Edit"])
	Achievement.UpdateAnchor(this)
end

function HM_AchieveWiki.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Box_Icon" then
		this:SetObjectMouseOver(true)
		local frame = this:GetRoot()
		local x, y  = this:GetAbsPos()
		local w, h  = this:GetSize()
		local xml   = {}
		table.insert(xml, GetFormatText(frame.title:GetText() .. "\n", 27))
		table.insert(xml, GetFormatText(frame.desc:GetText(), 41))
		OutputTip(table.concat(xml), 300, { x, y, w, h })
	elseif szName == "Text_Link" then
		this:SetFontColor(139, 46, 28)
	elseif szName == "Image_Wechat" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatImage(HM.GetCustomFile("image.UiTeX", "interface\\HM\\HM_0Base\\image.UiTex"), 2, 150, 150), 200, { x, y, w, h })
	end
end

function HM_AchieveWiki.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Box_Icon" then
		this:SetObjectMouseOver(false)
		HideTip()
	elseif szName == "Text_Link" then
		this:SetFontColor(0, 126, 255)
	elseif szName == "Image_Wechat" then
		HideTip()
	end
end

function HM_AchieveWiki.OnFrameDragEnd()
	ACHI_ANCHOR = GetFrameAnchor(this)
end

function HM_AchieveWiki.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		Achievement.UpdateAnchor(this)
	end
end

function HM_AchieveWiki.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		Achievement.ClosePanel()
	elseif szName == "Btn_Edit" then
		HM.Alert(_L["For user experience, game inline editing has been canceld.\nPlease click the link at the bottom for editing, thank you!"])
	end
end

function HM_AchieveWiki.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Text_Link" then
		local frame = this:GetRoot()
		OpenInternetExplorer(ACHI_ROOT_URL .. "/wiki/view/" .. frame.dwAchievement)
		Achievement.ClosePanel()
	end
end

-- OnItemUpdateSize autosize callback
function HM_AchieveWiki.OnItemUpdateSize()
	local item = this
	if item and item:IsValid() and item.src then
		local w, h = item:GetSize()
		local fScale = Station.GetUIScale()
		local fW, fH = w / fScale, h / fScale
		if fW > 670 then -- fixed size
			local f = 670 / fW
			item:SetSize(fW * f, fH * f)
		else
			item:SetSize(fW, fH)
		end
		item:RegisterEvent(16)
		item.OnItemLButtonClick = function()
			local sW, sH = fW + 90, fH + 90
			local ui = HM.UI.CreateFrame("HM_ImageView", { w = sW, h = sH, bgcolor = {222, 210, 190}, title = "Image Viewer" })
			local hImageview = ui:Raw():GetRoot()
			hImageview.fScale = 1
			local img = ui:Append("Image", { x = 0, y = 0, w = fW, h = fH, file = item.localsrc }):Click(function()
				HM.Animate(hImageview, 200):FadeOut(function()
					ui:Remove()
				end)
			end)
			HM.Animate(hImageview, 200):FadeIn()
			hImageview:RegisterEvent(2048)
			hImageview:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
			hImageview.OnMouseWheel = function()
				local nDelta = Station.GetMessageWheelDelta()
				if nDelta < 0 then
					if hImageview.fScale < 1.3 then
						hImageview.fScale = hImageview.fScale + 0.05
					end
				else
					if hImageview.fScale > 0.3 then
						hImageview.fScale = hImageview.fScale - 0.05
					end
				end
				local nW, nH = fW * hImageview.fScale, fH * hImageview.fScale
				ui:Size(math.max(nW + 90, 150), nH + 90)
				img:Size(nW, nH)
				return true
			end
		end
		item:GetParent():FormatAllItemPos()
	end
end

---------------------------------------------------------------------
-- 本地函数集
---------------------------------------------------------------------
function Achievement.IsOpened()
	return Station.Lookup("Normal/HM_AchieveWiki")
end

function Achievement.GetFrame()
	local frame = Achievement.IsOpened()
	if not frame then
		frame = Wnd.OpenWindow("interface\\HM\\HM_AchieveWiki\\HM_AchieveWiki.ini", "HM_AchieveWiki")
	end
	return frame
end

function Achievement.ClosePanel()
	if Achievement.IsOpened() then
		Wnd.CloseWindow(Achievement.IsOpened())
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

function Achievement.UpdateAnchor(frame)
	frame:SetPoint(ACHI_ANCHOR.s, 0, 0, ACHI_ANCHOR.r, ACHI_ANCHOR.x, ACHI_ANCHOR.y)
end

function Achievement.GetLinkScript(szLink)
	return [[
		this.OnItemLButtonClick = function()
			OpenInternetExplorer(]] .. EncodeComponentsString(szLink) .. [[)
		end
		this.OnItemMouseEnter = function()
			this:SetFontColor(255, 0, 0)
		end
		this.OnItemMouseLeave = function()
			this:SetFontColor(20, 150, 220)
		end
	]]
end

function Achievement.UpdateEncyclopedia(result)
	local frame = Achievement.GetFrame()
	local pedia = frame.pedia
	pedia:Clear()
	if type(result.desc) == "table" then
		local xml = {}
		for k, v in ipairs(result.desc) do
			if v.type == "text" then
				local r, g, b = nil, nil, nil
				if v.color then
					r, g, b = unpack(v.color)
				end
				tinsert(xml, GetFormatText(v.text, 6, r, g, b))
			elseif v.type == "image" then
				tinsert(xml, "<image>script=".. EncodeComponentsString("this.src=" .. EncodeComponentsString(v.url))  .." </image>")
			elseif v.type == "link" then
				local r, g, b = 20, 150, 220
				if v.color then
					r, g, b = unpack(v.color)
				end
				tinsert(xml, GetFormatText(v.text, 6, r, g, b, 272, Achievement.GetLinkScript(v.url)))
			end
		end
		pedia:AppendItemFromString(table.concat(xml))
		for i = pedia:GetItemCount() - 1, 0, -1 do
			local item = pedia:Lookup(i)
			if item and item:GetType() == 'Image' and item.FromRemoteFile then
				item:FromRemoteFile(item.src, true, function(e, a, b, c)
					if e and e:IsValid() then
						e.localsrc = b
						e:AutoSize()
						if not IsMultiThread() then
							local _this = this
							this = e
							HM_AchieveWiki.OnItemUpdateSize()
							this = _this
						end
					end
				end)
			end
		end
		pedia:AppendItemFromString(GetFormatText("\n\n", 6))
		pedia:AppendItemFromString(GetFormatText(_L["revise"], 172))
		pedia:AppendItemFromString(GetFormatText(" " .. result.ver .. "\n", 6))
		pedia:AppendItemFromString(GetFormatText(_L["Author"], 172))
		pedia:AppendItemFromString(GetFormatText(" " .. table.concat(result.authors, _L[", "]) .. "\n", 6))
		pedia:AppendItemFromString(GetFormatText(_L["Last modification"], 172))
		pedia:AppendItemFromString(GetFormatText(FormatTime(" %Y/%m/%d %H:%M:%S", result.time_create), 6))
	else
		pedia:AppendItemFromString(GetFormatText(result.desc, 6))
	end
	pedia:FormatAllItemPos()
end

function Achievement.OpenEncyclopedia(dwID, dwIcon, szTitle, szDesc)
	local frame = Achievement.GetFrame()
	frame.dwAchievement = dwID
	frame:BringToTop()
	frame.title:SetText(szTitle)
	frame.box:SetObjectIcon(dwIcon)
	frame.desc:SetText(szDesc)
	frame:Lookup("Btn_Edit"):Enable(false)
	frame.pedia:Clear()
	frame.link:SetText(_L("Link(Open URL):%s", ACHI_ROOT_URL .. "/wiki/view/" .. dwID))
	frame.link:AutoSize()
	frame.pedia:AppendItemFromString(GetFormatText(_L["Loading..."], 6))
	frame.pedia:FormatAllItemPos()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	HM.GetJson(ACHI_ROOT_URL .. "/api/wiki/" .. dwID .. "?__lang=" .. ACHI_CLIENT_LANG):done(function(res)
		frame:Lookup("Btn_Edit"):Enable(true)
		if res.aid then
			Achievement.UpdateEncyclopedia(res)
		elseif res.errmsg then
			HM.Alert(res.errmsg)
		end
	end):fail(function()
		HM.Sysmsg(_L["Request failed"])
	end)
end

function Achievement.AppendBoxEvent(handle)
	for i = 0, handle:GetItemCount() -1 do
		local item = handle:Lookup(i)
		if item and item:IsValid() then
			local dwID = item.dwAchievement
			if dwID ~= item.__JH_Append then
				local hDescribe = item:Lookup("Text_AchiDescribe")
				local hName = item:Lookup("Text_AchiName")
				local box = item:Lookup("Box_AchiBox")
				if dwID and box and hDescribe and hName then
					box:RegisterEvent(272)
					box.OnItemMouseEnter = function()
						this:SetObjectMouseOver(true)
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local xml   = {}
						table.insert(xml, GetFormatText(_L["Click for Achievepedia"], 41))
						if IsCtrlKeyDown() then
							table.insert(xml, GetFormatText("\n\n" .. g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n", 102))
							table.insert(xml, GetFormatText("dwAchievement: " .. dwID, 102))
						end
						OutputTip(table.concat(xml), 300, { x, y, w, h })
					end
					box.OnItemMouseLeave = function()
						this:SetObjectMouseOver(false)
						HideTip()
					end
					box.OnItemLButtonClick = function()
						Achievement.OpenEncyclopedia(dwID, box:GetObjectIcon(), hName:GetText(), hDescribe:GetText())
					end
				end
				item.__JH_Append = dwID
			end
		end
	end
end

function Achievement.OnFrameBreathe()
	local handle = Station.Lookup("Normal/AchievementPanel/PageSet_Achievement/Page_Achievement/WndScroll_AShow", "")
	if handle then
		Achievement.AppendBoxEvent(handle)
	end
	local handle2 = Station.Lookup("Normal/AchievementPanel/PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_AlmostFinish", "")
	if handle2 then
		Achievement.AppendBoxEvent(handle2)
	end
	local handle3 = Station.Lookup("Normal/AchievementPanel/PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_Scene", "")
	if handle3 then
		Achievement.AppendBoxEvent(handle3)
	end
end

-------------------------------------
-- 成就同步
-------------------------------------
local sformat = string.format
local tinsert = table.insert
local function GetAchievementCode()
	local me = GetClientPlayer()
	local dwMaxID = g_tTable.Achievement:GetRow(g_tTable.Achievement:GetRowCount()).dwID
	local bitmap = {}
	for i = 1, dwMaxID, 8 do
		local n = 0
		for j = 0, 7, 1 do
			if me.IsAchievementAcquired(i + j) then
				n = n + 2 ^ j
			end
		end
		tinsert(bitmap, sformat("%02x", n))
	end
	return table.concat(bitmap)
end

function Achievement.SyncUserData(fnCallBack, __qrcode)
	local data = HM_About.GetSyncData()
	data.code = GetAchievementCode()
	data.__qrcode = __qrcode
	HM.PostJson(ACHI_ROOT_URL .. "/api/wiki/data", data):done(function(res)
		HM_AchieveWiki.nSyncPoint = GetClientPlayer().GetAchievementRecord()
		if fnCallBack then
			fnCallBack(res)
		end
	end)
end

-------------------------------------
-- 设置界面
-------------------------------------
local PS = {}
function PS.OnPanelActive(frame)
	local ui, nX, nY = HM.UI(frame), 10, 0
	local me = GetClientPlayer()
	local gid = me.GetGlobalID()
	ui:Append("Text", { x = 0, y = 0, txt = _L["Achievepedia"], font = 27 })
	ui:Append("Text", { x = 0, y = 28, w = 520, h = 100 , multi = true, txt = _L["About the achievepedia."] })
	-- zhcn 版本可用
	nY = 134
	PS.active = true
	if ACHI_CLIENT_LANG == "zhcn" then
		nX, nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Sync game info"], font = 27 }):Pos_()
		-- name
		nX = ui:Append("Text", { x = 10, y = nY + 5 , txt = _L["Role name:"], color = { 255, 255, 200 } }):Pos_()
		nX, nY = ui:Append("Text", { x = nX + 5, y = nY + 5 , txt = GetUserRoleName() }):Pos_()
		nX = ui:Append("Text", { x = 10, y = nY + 5 , txt = _L["Last sync time:"], color = { 255, 255, 200 } }):Pos_()
		nX, nY = ui:Append("Text", "Text_Time", { x = nX + 5, y = nY + 5 , txt = _L["Loading..."] }):Pos_()
		-- /api/wiki/data/{gid}
		HM.GetJson(ACHI_ROOT_URL .. "/api/wiki/data/" .. gid):done(function(res)
			if not PS.active then
				return
			end
			if res.time_update then
				ui:Fetch("Text_Time"):Text(FormatTime("%Y/%m/%d %H:%M:%S", res.time_update))
			else
				ui:Fetch("Text_Time"):Text(res.errmsg or _L["No record"])
			end
		end):fail(function()
			if not PS.active then
				return
			end
			ui:Fetch("Text_Time"):Text(_L["Request failed"]):Color(255, 0, 0)
		end)
		nX, nY = ui:Append("WndCheckBox", "Check_Sync", { x = 5, y = nY + 12, txt = _L["Auto-sync achievement"], checked = HM_AchieveWiki.bAutoSync }):Click(function(bCheck)
			HM_AchieveWiki.bAutoSync = bCheck == true
			if bCheck then
				local box = ui:Fetch("Check_Sync")
				box:Enable(false)
				Achievement.SyncUserData(function()
					--GetUserInput(_L["Synchronization completed, please copy the global id."], nil, nil, nil, nil, gid);
					box:Enable(true)
					ui:Fetch("Text_Time"):Text(FormatTime("%Y/%m/%d %H:%M:%S", GetCurrentTime()))
				end)
			end
		end):Pos_()
		-- manual
		nX = ui:Append("WndButton", "Btn_Manual", { x = 5, y =  nY + 8, txt = _L["Manual sync"] }):AutoSize(8):Click(function()
			local btn = ui:Fetch("Btn_Manual")
			btn:Enable(false)
			Achievement.SyncUserData(function()
				btn:Enable(true)
				ui:Fetch("Text_Time"):Text(FormatTime("%Y/%m/%d %H:%M:%S", GetCurrentTime()))
			end)
		end):Pos_()
		-- wechat
		nX, nY = ui:Append("WndButton", "Btn_Wechat", { x = nX + 10, y = nY + 8, txt = _L["View in wechat"] }):AutoSize(8):Click(function()
			local btn = ui:Fetch("Btn_Wechat")
			btn:Enable(false)
			Achievement.SyncUserData(function(res)
				btn:Enable(true)
				ui:Fetch("Text_Time"):Text(FormatTime("%Y/%m/%d %H:%M:%S", GetCurrentTime()))
				if res and res.qrcode then
					local w, h = 240, 240
					local frm = HM.UI.CreateFrame("HM_ImageView", { w = w + 90, h = h + 90 + 20, bgcolor = {222, 210, 190, 240}, title = _L["Scan by wechat"], close = true })
					frm:Append("Image", { x = 0, y = 0, w = w, h = h }):Raw():FromRemoteFile(res.qrcode:gsub("https:", "http:"), true)
					frm:Append("Text", { x = 0, y = h + 10, w = w, h = 36, align = 1, font = 6, txt = _L["View your achievements"] })
					frm:Raw():GetRoot():SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
					ui:Fetch("Image_Wechat"):Toggle(false)
				end
			end, 1)
		end):Pos_()
		nY = nY + 8
	end
	nX, nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Others"], font = 27 }):Pos_()
	nX = ui:Append("Text", { x = 10, y = nY + 10 , txt = _L["Achievepedia Website"], color = { 255, 255, 200 } }):Pos_()
	nX, nY = ui:Append("WndEdit", { x = 120, y = nY + 10 , txt = ACHI_ROOT_URL .. "/wiki" }):Pos_()
	nX = ui:Append("Text", { x = 10, y = nY + 5 , txt = _L["Global ID"], color = { 255, 255, 200 } }):Pos_()
	nX, nY = ui:Append("WndEdit", { x = 120, y = nY + 5 , txt = gid }):Pos_()
	ui:Append("Image", "Image_Wechat", { x = 360, y = nY - 150, h = 150, w = 150 }):File(HM.GetCustomFile("image.UiTeX", "interface\\HM\\HM_0Base\\image.UiTex"), 2)
end

function PS.OnPanelDeactive()
	PS.active = nil
end

-- add to HM panel
HM.RegisterPanel(_L["Achievepedia"], 3151, _L["Others"], PS)

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- kill  exists AchievementPanel
Wnd.CloseWindow("AchievementPanel")

--  hook events
HM.RegisterEvent("ON_FRAME_CREATE.wiki", function()
	if arg0 and arg0:GetName() == "AchievementPanel" then
		arg0.OnFrameShow = function()
			HM.BreatheCall("AchieveWiki", Achievement.OnFrameBreathe)
		end
		arg0.OnFrameHide = function()
			HM.BreatheCall("AchieveWiki")
		end
		HM.BreatheCall("AchieveWiki", Achievement.OnFrameBreathe)
		HM.UnRegisterEvent("ON_FRAME_CREATE.wiki")
	end
end)

-- sync events
HM.RegisterEvent("FIRST_LOADING_END", function()
	if HM_AchieveWiki.bAutoSync then
		local nPoint = GetClientPlayer().GetAchievementRecord()
		if HM_AchieveWiki.nSyncPoint ~= nPoint then
			Achievement.SyncUserData()
		end
	end
end)
HM.RegisterEvent("UPDATE_ACHIEVEMENT_POINT", function()
	if HM_AchieveWiki.bAutoSync then
		Achievement.SyncUserData()
	end
end)
