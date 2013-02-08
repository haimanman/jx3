--
-- 海鳗插件：自动砸年兽陶罐
--
HM_Taoguan = {
	nUseGold = 320,		-- 优先使用金锤子的分数
	nUseZJ = 1280,		-- 开始吃醉生、寄优谷的分数
	bPauseNoZJ = true,	-- 缺少醉生、寄优时停砸
	nPausePoint = 327680,	-- 停砸分数线
	nUseJX = 80,				-- 自动用掉锦囊、香囊
	bNonZS = false,	-- 不使用醉生
	bUseGold = false,	-- 没银锤时使用金锤
	tFilterItem = {
		["鞭炮"] = true,
		["火树银花"] = true,
		["龙凤呈祥"] = true,
		["彩云逐月"] = true,
		["熠熠生辉"] = true,
		["焰火棒"] = true,
		["窜天猴"] = true,
		["剪纸：龙腾"] = true,
		["剪纸：凤舞"] = true,
		["元宝灯"] = true,
		["桃花灯"] = true,
		["桃木牌·蛇"] = false,
		["桃木牌·年"] = false,
		["桃木牌·吉"] = false,
		["桃木牌·祥"] = true,
		["图样：彩云逐月"] = true,
		["图样：熠熠生辉"] = true,
		["监本印文兑换券"] = false,
		["战魂佩"] = false,
		["豪侠贡"] = false,
		["年年有鱼灯"] = true,
	},
}

for k, _ in pairs(HM_Taoguan) do
	RegisterCustomData("HM_Taoguan." .. k)
end

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Taoguan = {
	bEnable = false,
	bHaveZJ = false,
	nPoint = 0,
	tListed = {},
	szName = "年兽陶罐",
	dwDoodadID = 0,
}

-- use bag item
_HM_Taoguan.UseBagItem = function(szName, bWarn)
	local me = GetClientPlayer()
	for i = 1, 5 do
		for j = 0, me.GetBoxSize(i) - 1 do
		local it = GetPlayerItem(me, i, j)
			if it and it.szName == szName then
				OnUseItem(i, j)
				return true
			end
		end
	end
	if bWarn then
		HM.Sysmsg("自动砸陶罐：缺少[" .. szName .. "]！")
	end
end

-- switch
_HM_Taoguan.Switch = function()
	_HM_Taoguan.bEnable = not _HM_Taoguan.bEnable
	_HM_Taoguan.bHaveZJ = false
	if _HM_Taoguan.bEnable then
		HM.Sysmsg("自动砸陶罐：开")
		_HM_Taoguan.FindNear()
	else
		HM.Sysmsg("自动砸陶罐：关")
	end
end

-- search next
_HM_Taoguan.FindNear = function()
	for k, _ in pairs(_HM_Taoguan.tListed) do
		local npc = GetNpc(k)
		if not npc then
			_HM_Taoguan.tListed[k] = nil
		elseif HM.GetDistance(npc) < 4 then
			FireUIEvent("NPC_ENTER_SCENE", k)
		end
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
_HM_Taoguan.MonitorZP = function(szMsg)
	local _, _, nP = string.find(szMsg, "目前的总积分为：(%d+)")
	if nP then
		_HM_Taoguan.nPoint = tonumber(nP)
		_HM_Taoguan.bHaveZJ = false
		if _HM_Taoguan.nPoint >= HM_Taoguan.nPausePoint then
			_HM_Taoguan.bEnable = false
			HM.Sysmsg("自动砸陶罐：已达设置上限！")
		else
			-- foreced to find next
			HM.DelayCall(5500, _HM_Taoguan.FindNear)
		end
	elseif _HM_Taoguan.bEnable and StringFindW(szMsg, _HM_Taoguan.szName) then
		-- foreced to find next [年兽陶罐已破碎|请选中年兽陶罐后使用]
		HM.DelayCall(5500, _HM_Taoguan.FindNear)
	end
end

_HM_Taoguan.OnNpcEnter = function()
	local npc = GetNpc(arg0)
	if not npc or npc.szName ~= _HM_Taoguan.szName then
		return
	end
	_HM_Taoguan.tListed[arg0] = true
	if not _HM_Taoguan.bEnable
		or (HM_Taoguan.bPauseNoZJ and _HM_Taoguan.nPoint >= HM_Taoguan.nUseZJ and not _HM_Taoguan.bHaveZJ)
	then
		return
	end
	if HM.GetDistance(npc) < 4 then
		HM.SetTarget(arg0)
		if _HM_Taoguan.nPoint < HM_Taoguan.nUseGold or not _HM_Taoguan.UseBagItem("小金锤") then
			if not _HM_Taoguan.UseBagItem("小银锤", true)
				and (not HM_Taoguan.bUseGold or not _HM_Taoguan.UseBagItem("小金锤", true))
			then
				_HM_Taoguan.bEnable = false
			end
		end
	end
end

_HM_Taoguan.OnLootItem = function()
	if arg0 == GetClientPlayer().dwID and arg2 > 2 and GetItem(arg1).szName == "梅良玉签" then
		_HM_Taoguan.nPoint = 0
		_HM_Taoguan.bHaveZJ = false
		HM.Sysmsg("自动砸陶罐：积分换光清零！")
	end
end

_HM_Taoguan.OnDoodadEnter = function()
	if _HM_Taoguan.bEnable then
		local d = GetDoodad(arg0)
		if d and d.szName == _HM_Taoguan.szName and d.CanDialog(GetClientPlayer())
			and HM.GetDistance(d) < 4.1
		then
			_HM_Taoguan.dwDoodadID = arg0
			HM.DelayCall(520, function()
				InteractDoodad(_HM_Taoguan.dwDoodadID)
			end)
		end
	end
end

_HM_Taoguan.OnOpenDoodad = function()
	if _HM_Taoguan.bEnable then
		local d = GetDoodad(_HM_Taoguan.dwDoodadID)
		if d and d.szName == _HM_Taoguan.szName then
			local nQ, nM, me = 1, d.GetLootMoney(), GetClientPlayer()
			if nM > 0 then
				LootMoney(d.dwID)
			end
			for i = 0, 31 do
				local it, bRoll, bDist = d.GetLootItem(i, me)
				if not it then
					break
				end
				local szName = GetItemNameByItem(it)
				if it.nQuality >= nQ and not bRoll and not bDist
					and not HM_Taoguan.tFilterItem[szName]
				then
					LootItem(d.dwID, it.dwID)
				else
					HM.Sysmsg("自动砸陶罐：过滤 [" .. szName .. "]")
				end
			end
			local hL = Station.Lookup("Normal/LootList", "Handle_LootList")
			if hL then
				hL:Clear()
			end
		end
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Taoguan.PS = {}

-- init
_HM_Taoguan.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { txt = "功能设置", x = 0, y = 0, font = 27 })
	-- gold
	nX = ui:Append("Text", { txt = "优先使用小金锤，当分数达到", x = 10, y = 28 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size1", { x = nX, y = 28, w = 100, h = 25 })
	:Text(tostring(HM_Taoguan.nUseGold)):Menu(function()
		local m0 = {}
		for i = 3, 9 do
			local v = 10 * 2 ^ i
			table.insert(m0, { szOption = tostring(v), fnAction = function()
				HM_Taoguan.nUseGold = v
				ui:Fetch("Combo_Size1"):Text(tostring(v))
			end })
		end
		return m0
	end):Pos_()
	ui:Append("WndCheckBox", { txt = "缺银锤时总是用金锤？", x = nX + 10, y = 28, checked = HM_Taoguan.bUseGold })
	:Click(function(bChecked) HM_Taoguan.bUseGold = bChecked end)
	-- max
	nX = ui:Append("Text", { txt = "停止无脑砸罐子，当分数达到", x = 10, y = 56 }):Pos_()
	ui:Append("WndComboBox", "Combo_Size3", { x = nX, y = 56, w = 100, h = 25 })
	:Text(tostring(HM_Taoguan.nPausePoint)):Menu(function()
		local m0 = {}
		for i = 7, 17 do
			local v = 10 * 2 ^ i
			table.insert(m0, { szOption = tostring(v), fnAction = function()
				HM_Taoguan.nPausePoint = v
				ui:Fetch("Combo_Size3"):Text(tostring(v))
			end })
		end
		return m0
	end)
	-- zj
	nX = ui:Append("Text", { txt = "使用寄忧谷醉生，当分数达到", x = 10, y = 84 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size2", { x = nX, y = 84, w = 100, h = 25 })
	:Text(tostring(HM_Taoguan.nUseZJ)):Menu(function()
		local m0 = {}
		for i = 5, 11 do
			local v = 10 * 2 ^ i
			table.insert(m0, { szOption = tostring(v), fnAction = function()
				HM_Taoguan.nUseZJ = v
				ui:Fetch("Combo_Size2"):Text(tostring(v))
			end })
		end
		return m0
	end):Pos_()
	nX = ui:Append("WndCheckBox", { txt = "若缺停砸", x = nX + 10, y = 84, checked = HM_Taoguan.bPauseNoZJ })
	:Click(function(bChecked) HM_Taoguan.bPauseNoZJ = bChecked end):Pos_()
	ui:Append("WndCheckBox", { txt = "不吃醉生", x = nX + 10, y = 84, checked = HM_Taoguan.bNonZS })
	:Click(function(bChecked) HM_Taoguan.bNonZS = bChecked end)
	-- JX
	nX = ui:Append("Text", { txt = "使用锦囊和香囊，当分数达到", x = 10, y = 112 }):Pos_()
	ui:Append("WndComboBox", "Combo_Size4", { x = nX, y = 112, w = 100, h = 25 })
	:Text(tostring(HM_Taoguan.nUseJX)):Menu(function()
		local m0 = {}
		for i = 2, 10 do
			local v = 10 * 2 ^ i
			table.insert(m0, { szOption = tostring(v), fnAction = function()
				HM_Taoguan.nUseJX = v
				ui:Fetch("Combo_Size4"):Text(tostring(v))
			end })
		end
		return m0
	end)
	-- filter
	nX = ui:Append("WndComboBox", { x = 10, y = 140, txt = "拾取过滤设置" })
	:Menu(function()
		local m0 = {}
		for k, v in pairs(HM_Taoguan.tFilterItem) do
			table.insert(m0, { szOption = k, bCheck = true, bChecked = v == true, fnAction = function(d, b)
				HM_Taoguan.tFilterItem[k] = b
			end })
		end
		return m0
	end):Pos_()
	ui:Append("Text", { x = nX + 10, y = 140, txt = "（打勾的不捡，若还捡请关盒子的自动拾取）" })
	-- begin
	nX = ui:Append("WndButton", { x = 10, y = 176, txt = "开始/停止砸罐" }):AutoSize():Click(_HM_Taoguan.Switch):Pos_()
	ui:Append("Text", { x = nX + 10, y = 176, txt = "（宏命令开关：/" .. _HM_Taoguan.szName .. "）" })
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
RegisterMsgMonitor(_HM_Taoguan.MonitorZP, {"MSG_SYS"})
HM.BreatheCall("taoguan1", function()
	if _HM_Taoguan.bEnable then
		HM.DoMessageBox("PlayerMessageBoxCommon")
	end
end)
HM.BreatheCall("taoguan2", function()
	if _HM_Taoguan.bEnable and _HM_Taoguan.nPoint >= HM_Taoguan.nUseZJ then
		local bJ, bZ = true, HM_Taoguan.bNonZS == false
		for _, v in ipairs(GetClientPlayer().GetBuffList()) do
			if v.dwID == 1660 and v.nLevel == 3 then
				bJ = false
			elseif v.dwID == 1661 and v.nLevel == 3 then
				bZ = false
			end
		end
		_HM_Taoguan.bHaveZJ = bJ == false and bZ == false
		if bJ and not _HM_Taoguan.UseBagItem("寄忧谷", HM_Taoguan.bPauseNoZJ) and HM_Taoguan.bPauseNoZJ then
			_HM_Taoguan.bEnable = false
		elseif bZ and not _HM_Taoguan.UseBagItem("醉生", HM_Taoguan.bPauseNoZJ) and HM_Taoguan.bPauseNoZJ then
			_HM_Taoguan.bEnable = false
		end
	elseif _HM_Taoguan.bEnable and _HM_Taoguan.nPoint >= HM_Taoguan.nUseJX then
		if not HM_Force.HasBuff(1660) and not _HM_Taoguan.UseBagItem("如意香囊") then
			_HM_Taoguan.UseBagItem("幸运香囊")
		end
		if not HM_Force.HasBuff(1661) and not _HM_Taoguan.UseBagItem("如意锦囊") then
			_HM_Taoguan.UseBagItem("幸运锦囊")
		end
    end
end, 1000)
HM.RegisterEvent("NPC_ENTER_SCENE", _HM_Taoguan.OnNpcEnter)
HM.RegisterEvent("LOOT_ITEM", _HM_Taoguan.OnLootItem)
HM.RegisterEvent("DOODAD_ENTER_SCENE", _HM_Taoguan.OnDoodadEnter)
HM.RegisterEvent("HELP_EVENT", function()
	if arg0 == "OnOpenpanel" and arg1 == "LOOT"
		and _HM_Taoguan.bEnable and _HM_Taoguan.dwDoodadID ~= 0
	then
		_HM_Taoguan.OnOpenDoodad()
		_HM_Taoguan.dwDoodadID = 0
	end
end)
AppendCommand(_HM_Taoguan.szName, _HM_Taoguan.Switch)

-- add to HM collector
HM.RegisterPanel(_HM_Taoguan.szName .. "助手", 119, _L["Others"], _HM_Taoguan.PS)

