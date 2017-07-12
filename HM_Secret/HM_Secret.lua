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
	szName = _L["Haiman Site"],
	szIniFile = "interface\\HM\\HM_Secret\\HM_Secret.ini",
}

-------------------------------------
-- 事件处理
-------------------------------------
local ROOT_URL = HM.szRemoteHost
local CLIENT_LANG = HM.szClientLang

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Secret.PS = {}

-- init
_HM_Secret.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- Tips
	ui:Append("Text", { x = 0, y = 0, txt = "关于官网", font = 27 })
	ui:Append("Text", { x = 0, y = 28, txt = "海鳗插件官网由海鳗鳗及其团队开发并维护，与剑网3游戏官方无关。在游戏之外提供相关辅助功能，包括数据查询、成就百科、科举答题、开服监控、日常提醒、情缘证书、玩家交流等。", multi = true, w = 520, h = 70 })
	ui:Append("WndEdit", { x = 0, y = 100 , w = 240, h = 28, txt = ROOT_URL, color = { 255, 255, 200 } })
	local bY = 142
	ui:Append("Text", { x = 0, y = bY, txt = "海鳗茶馆", font = 27 })
	nX = ui:Append("Text", { x = 0, y = bY + 28, txt = "投稿或倾听树洞故事、独家评论，请关注微信公众号【" }):Pos_()
	nX = ui:Append("Text", { x = nX, y = bY + 28, txt = "海鳗茶馆", font = 51 }):Pos_()
	ui:Append("Text", { x = nX, y = bY + 28, txt = "】" })
	-- verify
	bY = 212
	ui:Append("Text", { x = 0, y = bY, txt = "海鳗认证", font = 27 })
	ui:Append("Text", "Text_Verify", { x = 0, y = bY + 28, txt = "loading...", font = 47 }):Color(6, 204, 178)
	nX = ui:Append("Text", { x= 0, y = bY + 56, txt = "认证选项：" }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Basic", { x = nX, y = bY + 56, txt = "区服体型", checked = true, enable = false }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Name", { x = nX + 10, y = bY + 56, txt = "角色名", checked = true }):Pos_()
	nX = ui:Append("WndCheckBox", "Check_Equip", { x = nX + 10, y = bY + 56, txt = "武器&坐骑", checked = true }):Pos_()
	nX = ui:Append("WndButton", "Btn_Delete", { x = 0, y =  bY + 90, txt = "解除认证", enable = false }):Click(function()
		HM.Confirm("确定要解除认证吗？", function()
			local data = {
				gid = GetClientPlayer().GetGlobalID(),
				isOpenVerify = false
			}
			HM.PostJson(ROOT_URL .. "/api/jx3/game-roles", HM.JsonEncode(data)):done(function(res)
				HM_Secret.bAutoSync = false
				HM.OpenPanel(_HM_Secret.szName)
			end)
		end)
	end):Pos_()
	nX = ui:Append("WndButton", "Btn_Submit", { x = nX + 10, y =  bY + 90, txt = "立即认证" }):Click(function()
		local btn = ui:Fetch("Btn_Submit")
		local data = HM_About.GetSyncData()
		data.isOpenName = ui:Fetch("Check_Name"):Check() and 1 or 0
		data.isOpenEquip = ui:Fetch("Check_Equip"):Check() and 1 or 0
		data.__qrcode = 1
		btn:Enable(false)
		if GetClientPlayer().nLevel < 95 then
			return HM.Alert(g_tStrings.tCraftResultString[CRAFT_RESULT_CODE.TOO_LOW_LEVEL])
		end
		HM.PostJson(ROOT_URL .. "/api/jx3/game-roles", HM.JsonEncode(data)):done(function(res)
			HM_Secret.bAutoSync = true
			if not res or res.errcode ~= 0 then
				ui:Fetch("Text_Verify"):Text(res and res.errmsg or "Unknown"):Color(255, 0, 0)
			elseif res.data and res.data.qrcode then
				HM.ViewQrcode(res.data.qrcode, "微信扫码完成认证")				
				--ui:Fetch("Image_Wechat"):Toggle(false)
				ui:Fetch("Text_Verify"):Text("扫码后请点击左侧菜单刷新")
			end
			btn:Text("重新认证")
			btn:Enable(true)
		end)
	end):Pos_()
	-- /api/jx3/roles/{gid}
	_HM_Secret.PS.active = true
	HM.GetJson(ROOT_URL .. "/api/jx3/game-roles/" .. GetClientPlayer().GetGlobalID()):done(function(res)
		if not _HM_Secret.PS.active then
			return
		end
		if res.data and res.data.verify then
			local data = res.data
			local szText = data.verify .. " (" .. FormatTime("%Y/%m/%d %H:%M", data.time_update) .. ")"
			ui:Fetch("Text_Verify"):Text(szText)
			ui:Fetch("Check_Name"):Check(data.open_name == true)
			ui:Fetch("Check_Equip"):Check(data.open_equip == true)
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
end

_HM_Secret.PS.OnPanelDeactive = function()
	_HM_Secret.PS.active = nil
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- sync events
HM.RegisterEvent("FIRST_LOADING_END", function()
	if HM_Secret.bAutoSync then
		local data = HM_About.GetSyncData()
		HM.PostJson(ROOT_URL .. "/api/jx3/game-roles", HM.JsonEncode(data))
	end
end)

-- add to HM collector
HM.RegisterPanel(_HM_Secret.szName, 244, _L["Recreation"], _HM_Secret.PS)
