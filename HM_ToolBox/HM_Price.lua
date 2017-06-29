--
-- 海鳗插件：角色估价
-- 根据当前持有的外观、头发、成就装备等 角色数据进行估价
--
-- 优化称号和挂件数据，不要全部上传？
--
HM_Price = {}

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local ROOT_URL = HM.szRemoteHost
local OFFICAL_URL = ROOT_URL .. "/jx3/gujia"
local _HM_Price = {
	szName = "角色估价",
	nBagCount = 6,
	nBankCount = 6,
}

-- 扫描装备、背包、仓库格子
_HM_Price.WalkInventory = function(dwBox, fnAction)
	local me = GetClientPlayer()
	local dwSize = me.GetBoxSize(dwBox)
	for dwX = 0, dwSize - 1, 1 do
		local item = GetPlayerItem(me, dwBox, dwX)
		if item and item.bBind then
			pcall(fnAction, item)
		end
	end
end

_HM_Price.WalkAllItems = function(fnAction, bEquip, bBag, bBank)
	local me = GetClientPlayer()
	if bEquip ~= false then
		_HM_Price.WalkInventory(INVENTORY_INDEX.EQUIP, fnAction)
	end
	if bBag ~= false then
		for i = 1, _HM_Price.nBagCount, 1 do
			local dwBox = INVENTORY_INDEX.PACKAGE + i - 1
			_HM_Price.WalkInventory(dwBox, fnAction)
		end
	end
	if bBank ~= false then
		for i = 1, _HM_Price.nBankCount, 1 do
			local dwBox = INVENTORY_INDEX.BANK + i - 1
			_HM_Price.WalkInventory(dwBox, fnAction)
		end
	end
end

_HM_Price.ConvertToForce = function(dwSchool)
	local szName = Table_GetSkillSchoolName(dwSchool)
	for k, v  in pairs(g_tStrings.tForceTitle) do
		if v == szName then
			return k
		end
	end
end

-- 基础信息：gid, name, server, shcool, camp, body, pet, score, point, camp ...
_HM_Price.GetBasicInfo = function()
	local me = GetClientPlayer()
	-- 基本
	local t = {
		gid = me.GetGlobalID(),
		reward = me.GetRewards(),
		coin = me.nCoin,
		gold = me.GetMoney().nGold,
	}
	-- 装备分全记录
	t.scores = _HM_Price.scores
	-- 二内
	t.slaves = {}
	local _exists = {}
	_exists[me.dwForceID] = true
	for k, v in pairs(me.GetAllMountKungfu() or {}) do
		local skill = GetSkill(k, v)
		local nForce = _HM_Price.ConvertToForce(skill.dwBelongSchool)
		if not _exists[nForce] then
			_exists[nForce] = true
			table.insert(t.slaves, nForce)
		end
	end
	return t
end

-- 提取橙武、玄晶
_HM_Price.LoadBestItems = function(t)
	local nMaxLevel = GetClientPlayer().nMaxLevel
	t.oranges = _HM_Price.oranges
	_HM_Price.WalkAllItems(function(item)
		if item.nGenre == ITEM_GENRE.EQUIPMENT 
			and (item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.RANGE_WEAPON)
			and item.nQuality == 5
		then
			-- weapon
			table.insert(t.oranges, item.nUiId)
		elseif item.nQuality == 5 and item.nGenre == ITEM_GENRE.MATERIAL and item.dwTabType == ITEM_TABLE_TYPE.OTHER then
			-- material **玄晶
			local info = GetItemInfo(ITEM_TABLE_TYPE.OTHER, 6630)
			local szPattern = string.sub(info.szName, math.ceil(string.len(info.szName) / 2) + 1) .. "$"
			if string.find(item.szName, szPattern) then
				table.insert(t.oranges, item.nUiId)
			end
		end
	end, false)
end

-- 提取坐骑、马具
_HM_Price.LoadHorses = function(t)
	t.horses = {}
	local fnAction = function(item)
		if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
			table.insert(t.horses, item.nUiId)
		end
	end
	_HM_Price.WalkInventory(INVENTORY_INDEX.HORSE, fnAction)
	_HM_Price.WalkInventory(INVENTORY_INDEX.RARE_HORSE1, fnAction)
	_HM_Price.WalkInventory(INVENTORY_INDEX.RARE_HORSE2, fnAction)
	_HM_Price.WalkAllItems(fnAction, false, true, false)
	-- 马具, >= 5%
	t.horse_equips = {}
	for _, v in ipairs(GetClientPlayer().GetAllHorseEquip() or {}) do
		local info = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, v.dwItemIndex)
		local attr = GetItemMagicAttrib(info.GetMagicAttribIndexList())
		if attr[1] and attr[1].nID == 2 and attr[1].Param0 >= 50 then
			table.insert(t.horse_equips, info.nUiId)
		end
	end
end

-- 提取披风、挂件、捏脸、头发、拓印
_HM_Price.LoadExteriors = function(t)
	local me = GetClientPlayer()
	t.weapon_collect_num = table.getn(me.GetAllWeaponExterior())	-- 武器数量
	t.face_collect_num = table.getn(me.GetAllHair(HAIR_STYLE.FACE)) -- 脸型数量（不太正确）
	t.hairs = me.GetAllHair(HAIR_STYLE.HAIR) -- 发型
	-- 时装、拓印
	t.exteriors = {}
	for _, v in ipairs(me.GetAllExterior() or {}) do
		if v.nTimeType == 0 and v.nEndTime == 0 then
			table.insert(t.exteriors, v.dwExteriorID)
		end
	end
	-- 披风
	t.cloaks = {}
	for _, v in ipairs(me.GetAllBackCloakPendent() or {}) do
		table.insert(t.cloaks, v.dwItemIndex)
	end
	-- 挂件
	t.back_pendants = {}
	t.waist_pendants = {}
	for _, v in ipairs(me.GetAllBackPendent() or {}) do
		table.insert(t.back_pendants, v.dwItemIndex)
	end
	for _, v in ipairs(me.GetAllWaistPendent() or {}) do
		table.insert(t.waist_pendants, v.dwItemIndex)
	end
	t.back_pendant_num = table.getn(t.back_pendants)
	t.waist_pendant_num = table.getn(t.waist_pendants)
	t.face_pendant_num = table.getn(me.GetAllFacePendent() or {})
	t.lshoulder_pendant_num = table.getn(me.GetAllLShoulderPendent() or {})
	t.rshoulder_pendant_num = table.getn(me.GetAllRShoulderPendent() or {})	
end

-- 提取称号、奇遇等
_HM_Price.LoadAdventures = function(t)
	local me = GetClientPlayer()
	-- 前缀：300=侠客行, 120=济世菩萨, 266=红尘,  168=老江湖, new: id > 360
	-- 后缀：251=傲岸,  194=追梦人, new: id > 268
	t.designations = {}
	for _, v in ipairs(me.GetAcquiredDesignationPrefix() or {}) do
		if v == 300 or v == 120 or v == 266 or v == 168 or v > 360 then
			table.insert(t.designations, v)
		end
	end
	for _, v in ipairs(me.GetAcquiredDesignationPostfix() or {}) do
		if v == 251 or v == 194 or v > 268 then
			table.insert(t.designations, v + 10000)
		end
	end
	-- 奇遇
	t.adventures = {}
	local tab = g_tTable.Adventure
	for i = 2, tab:GetRowCount(), 1 do
		local row = tab:GetRow(i)
		if row.dwFinishID ~= 0 then
			if me.GetAdventureFlag(row.dwFinishID) then
				table.insert(t.adventures, row.dwID)
			end
		elseif row.nFinishQuestID ~= 0 then
			if me.GetQuestPhase(row.nFinishQuestID) == 3 then
				table.insert(t.adventures, row.dwID)
			end
		end
	end	
end

-- 获取估价所需全部信息
_HM_Price.GetAllInfo = function()
	local t = _HM_Price.GetBasicInfo()
	_HM_Price.LoadBestItems(t)
	_HM_Price.LoadHorses(t)
	_HM_Price.LoadExteriors(t)
	_HM_Price.LoadAdventures(t)
	return t
end

-- 获取全套装备分
_HM_Price.GetCurrentScore = function()
	-- 心法装备类型，武器魔法属性ID
	-- AttributeStringToID("atDecriticalDamagePowerBase") = 100
	-- AttributeStringToID("atDecriticalDamagePowerPercent") = 101
	-- AttributeStringToID("atToughnessBase") = 97
	-- AttributeStringToID("atToughnessPercent") = 98
	local me = GetClientPlayer()
	local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	if not item then
		return
	end
	-- pvp or pve
	local pvx = "PVE"
	local attrib = item.GetMagicAttrib()
	for _, v in pairs(attrib) do
		if v.nID == 100 or v.nID == 97 or v.nID == 101 or v.nID == 98 then
			pvx = "PVP"
			break
		end
	end
	-- fir for kungfu
	local info = GetItemInfo(item.dwTabType, item.dwIndex)
	local school = GetForceTitle(me.dwForceID)
	if info.nRecommendID and g_tTable.EquipRecommend then
		local t = g_tTable.EquipRecommend:Search(info.nRecommendID)
		if StringFindW(t.szDesc, school) == 1 then
			local skill = GetSkill(tonumber(string.match(t.kungfu_ids, "^%d+")), 1)
			if skill then
				local score = me.GetTotalEquipScore()
				local name = skill.szSkillName
				local s = _HM_Price.scores
				if not s[name] then
					s[name] = {}
				end
				if not s[name][pvx] or s[name][pvx] < score then
					s[name][pvx] = score
				end
			end
		end
	end
end

_HM_Price.LoadScoreAndNext = function()
	local me = GetClientPlayer()
	local nCur = me.GetEquipIDArray(0)
	local nNext = (nCur + 1) % 4
	_HM_Price.GetCurrentScore()
	_HM_Price.nCurSuit = nNext
	if nNext == _HM_Price.nOrgSuit then
		HM.UnRegisterEvent("EQUIP_CHANGE.p")
		if _HM_Price.ui then
			_HM_Price.ui:Fetch("Btn_Submit"):Text("获取估价"):Enable(true)
		end
	end
	-- weapons
	local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
	if item and item.nQuality == 5 then
		table.insert(_HM_Price.oranges, item.nUiId)
	end
	if me.dwForceID == 8 then
		local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
		if item and item.nQuality == 5 then
			table.insert(_HM_Price.oranges, item.nUiId)
		end
	end
	PlayerChangeSuit(nNext + 1)
end

_HM_Price.LoadAllScores = function()
	_HM_Price.scores = {}
	_HM_Price.oranges = {}	-- 套装上的 cw
	_HM_Price.nCurSuit = GetClientPlayer().GetEquipIDArray(0)
	_HM_Price.nOrgSuit = _HM_Price.nCurSuit
	HM.RegisterEvent("EQUIP_CHANGE.p", _HM_Price.LoadScoreAndNext)
	_HM_Price.LoadScoreAndNext()
end

_HM_Price.GetImage = function()
	HM.GetJson(ROOT_URL .. "/api/jx3/price-images/" .. GetClientPlayer().GetGlobalID()):done(function(res)
		if res.errcode == 0 and res.qrcode then
			HM.ViewQrcode(res.qrcode, "获取估价图片")
		else
			HM.Alert(res.errmsg)
		end
	end)
end

-------------------------------------
-- 事件处理
-------------------------------------

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Price.PS = {}

-- deinit
_HM_Price.PS.OnPanelDeactive = function(frame)
	HM.UnRegisterEvent("EQUIP_CHANGE.p")
	_HM_Price.ui = nil
	if _HM_Price.nOrgSuit then
		PlayerChangeSuit(_HM_Price.nOrgSuit + 1)
	end
end

-- init
_HM_Price.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { x = 0, y = 0, txt = "估价原理", font = 27 })
	ui:Append("Text", { x = 0, y = 28, txt = "根据您当前装备、成就、商城外观发型等角色数据，依据近期市场成交价综合动态评测。", multi = true, w = 520, h = 50 })
	local bY = 90
	ui:Append("Text", { x = 0, y = bY, txt = GetUserRoleName() .. "（" .. select(6, GetUserServer()) .. "）的价值大约为：", font = 27 })
	nX = ui:Append("Text", "Text_Price", { x = 3, y = bY + 45, txt = "???", font = 24 }):Pos_()
	ui:Append("Text", "Text_Unit", { x = nX + 5, y = bY + 45, txt = "元" })
	nX = ui:Append("WndButton", "Btn_Submit", { x = 0, y =  bY + 90, txt = "请稍候", enable = false }):Click(function()
		-- check level
		local me = GetClientPlayer()
		if me.nLevel ~= me.nMaxLevel then
			ui:Fetch("Text_Unit"):Toggle(false)
			return ui:Fetch("Text_Price"):Text("请先满级")
		end
		HM.Confirm("声明：此价格由插件自动评估，仅供参考和娱乐，切勿用于交易！", function()
			ui:Fetch("Btn_Submit"):Enable(false)
			-- update role
			local data = HM_About.GetSyncData()
			data.__qrcode = "0"
			HM.PostJson(ROOT_URL .. "/api/jx3/roles", data):done(function(res)
				if not res or  res.errcode ~= 0 then
					ui:Fetch("Text_Price"):Text(res and res.errmsg or "Unknown")
					ui:Fetch("Btn_Submit"):Enable(true)
				else
					local data = _HM_Price.GetAllInfo()
					HM.PostJson(ROOT_URL .. "/api/jx3/price-records", HM.JsonEncode(data)):done(function(res)
						local _nX = ui:Fetch("Text_Price"):Text(res.nPrice or res.errmsg):Pos_()
						ui:Fetch("Text_Unit"):Pos(_nX + 5, bY + 45)
						if res.errcode == 0 then
							ui:Fetch("Btn_Scan"):Enable(true)
							_HM_Price.result = res
						else
							HM.Debug(res.data or res.errmsg)
						end
					end)
				end
			end)
		end, nil, "同意", "拒绝")
	end):Pos_()
	-- 查看详情
	ui:Append("WndButton", "Btn_Scan", { x = nX + 10, y =  bY + 90, txt = "查看详情", enable = false }):Click(function()
		--HM_Price.OpenDetail()
		_HM_Price.GetImage()
	end)
	ui:Append("Text", { x = 3, y = bY + 130, font = 218, txt = "注1：不计算未绑定物品、通宝、积分等" })
	ui:Append("Text", { x = 3, y = bY + 152, font = 218, txt = "注2：如需模拟估价，请自行至官网配置生成" })
	-- url
	ui:Append("Text", { x = 0, y = bY + 206 , txt = "估价器官网", font = 27 })
	ui:Append("WndEdit", { x = 0, y = bY + 234 , w = 300, h = 28, txt = ROOT_URL .. "/jx3/gujia", color = { 255, 255, 200 } })
	-- load equip scores
	_HM_Price.ui = ui
	_HM_Price.LoadAllScores()
end

---------------------------------------------------------------------
-- 界面函数
---------------------------------------------------------------------
local ACHI_ANCHOR  = { s = "CENTER", r = "CENTER", x = 0, y = 0 }
function HM_Price.IsOpened()
	return Station.Lookup("Normal/HM_Price")
end

function HM_Price.GetFrame()
	local frame = HM_Price.IsOpened()
	if not frame then
		frame = Wnd.OpenWindow("interface\\HM\\HM_ToolBox\\HM_Price.ini", "HM_Price")
	end
	return frame
end

function HM_Price.ClosePanel()
	local frame = HM_Price.IsOpened()
	if frame then
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

function HM_Price.UpdateAnchor(frame)
	frame:SetPoint(ACHI_ANCHOR.s, 0, 0, ACHI_ANCHOR.r, ACHI_ANCHOR.x, ACHI_ANCHOR.y)
end

function HM_Price.GetLinkScript(szLink)
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

function HM_Price.OpenDetail()
	local res = _HM_Price.result
	if not res then
		return
	end
	local frame = HM_Price.GetFrame()
	frame:Lookup("", "Text_Title"):SetText(GetUserRoleName() .. "≈" .. res.nPrice .. "元")
	frame:Lookup("", "Text_Link"):SetText("估价官网：" .. OFFICAL_URL)
	frame:Lookup("", "Text_Link"):AutoSize()
	frame:Lookup("Btn_Edit"):Lookup("", "Text_Edit"):SetText("生成图片")
	frame:BringToTop()
	handle:Clear()
	handle:AppendItemFromString(GetFormatText(res.szText or "", 6))
	handle:FormatAllItemPos()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function HM_Price.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	RegisterGlobalEsc("HM_Price", HM_Price.IsOpened, HM_Price.ClosePanel)
	HM_Price.UpdateAnchor(this)
end

function HM_Price.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Text_Link" then
		this:SetFontColor(139, 46, 28)
	end
end

function HM_Price.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Text_Link" then
		this:SetFontColor(0, 126, 255)
	end
end

function HM_Price.OnFrameDragEnd()
	ACHI_ANCHOR = GetFrameAnchor(this)
end

function HM_Price.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		HM_Price.UpdateAnchor(this)
	end
end

function HM_Price.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		HM_Price.ClosePanel()
	elseif szName == "Btn_Edit" then
		_HM_Price.GetImage()
	end
end

function HM_Price.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Text_Link" then
		local frame = this:GetRoot()
		OpenInternetExplorer(OFFICAL_URL)
		HM_Price.ClosePanel()
	end
end
---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------

-- add to HM collector
HM.RegisterPanel(_HM_Price.szName, 301, _L["Recreation"], _HM_Price.PS)
