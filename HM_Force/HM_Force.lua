--
-- 海鳗插件：职业特色增强（天策上下马切技能栏，纯阳智能对自己生太极）
--

HM_Force = {
	bHorsePage = true,	-- 上下马切换技能栏（仅天策）
	bAlertPet = true,			-- 五毒宠物消失提醒
	bMarkPet = true,			-- 五毒宠物标记
	bFeedHorse = true,	-- 提示喂马
	bWarningDebuff = false,	-- 警告  debuff 类型
	nDebuffNum = 3,			-- debuff 类型达到几个时警告
	bActionTime = true,	-- 显示读条动作计时
	bHorseReplace = true,	-- 战斗中智能替换战马
	bAlertWanted = true,	-- 在线被悬赏时提醒自己
	bEngBar = false,	-- 显示职业能量条
}
HM.RegisterCustomData("HM_Force")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Force = {
	nFrameXJ = 0,
	nFrameMP = 0,
}

-- update pet mark
_HM_Force.UpdatePetMark = function(bMark)
	local pet = GetClientPlayer().GetPet()
	if pet then
		local dwEffect = 13
		if not bMark then
			dwEffect = 0
		end
		SceneObject_SetTitleEffect(TARGET.NPC, pet.dwID, dwEffect)
	end
end

-- check horse page
_HM_Force.OnRideHorse = function()
	if HM_Force.bHorsePage then
		local me = GetClientPlayer()
		if me then
			local mnt = me.GetKungfuMount()
			if mnt and (mnt.dwSkillID == 10026 or mnt.dwSkillID == 10062) then
				local nPage = GetUserPreferences(1390, "c")
				if me.bOnHorse and nPage < 3 then
					SelectMainActionBarPage(nPage + 2)
				elseif not me.bOnHorse and nPage > 2 then
					SelectMainActionBarPage(nPage - 2)
				end
			end
		end
	end
end

-- check to mark pet
_HM_Force.OnNpcEnter = function()
	if HM_Force.bMarkPet then
		local pet = GetClientPlayer().GetPet()
		if pet and arg0 == pet.dwID then
			HM.DelayCall(500, function()
				_HM_Force.UpdatePetMark(true)
			end)
		else
			local npc = GetNpc(arg0)
			if npc.dwTemplateID == 46297 and npc.dwEmployer == UI_GetClientPlayerID() then
				SceneObject_SetTitleEffect(TARGET.NPC, npc.dwID, 13)
			end
		end
	end
end
_HM_Force.OnNpcUpdate = _HM_Force.OnNpcEnter

-- check pet of 5D （XJ：2226）
_HM_Force.OnNpcLeave = function()
	if HM_Force.bAlertPet then
		local me = GetClientPlayer()
		if me then
			local pet = me.GetPet()
			if pet and pet.dwID == arg0 and (GetLogicFrameCount() - _HM_Force.nFrameXJ) >= 32 then
				OutputWarningMessage("MSG_WARNING_YELLOW", _L("Your pet [%s] disappeared!",  pet.szName))
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			end
		end
	end
end

-- warning buff type
_HM_Force.WarningDebuff = function(nType, nNum)
	local szText = _L("Your debuff of type [%s] reached [%d]", g_tStrings.tBuffDetachType[nType], nNum)
	OutputWarningMessage("MSG_WARNING_GREEN", szText)
	PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
end

-- buff update：
-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
-- arg8：nLevel，arg9：dwSkillSrcID
_HM_Force.OnBuffUpdate = function()
	if arg0 ~= GetClientPlayer().dwID or not HM_Force.bWarningDebuff or (not arg7 and arg3) then
		return
	end
	local t, t2 = {}, {}
	HM.WalkAllBuff(GetClientPlayer(), function(dwID, nLevel, bCanCancel)
		if not bCanCancel and not t2[dwID] then
			local info = GetBuffInfo(dwID, nLevel, {})
			if info and info.nDetachType > 2 then
				if not t[info.nDetachType] then
					t[info.nDetachType] = 1
				else
					t[info.nDetachType] = t[info.nDetachType] + 1
				end
				t2[dwID] = true
			end
		end
	end)
	for k, v in pairs(t) do
		if v >= HM_Force.nDebuffNum then
			_HM_Force.WarningDebuff(k, v)
		end
	end
end

-- record otaction
_HM_Force.SaveOTAction = function(nTotal, bDec)
	if HM_Force.bActionTime then
		_HM_Force.nActionTotal = nTotal
		_HM_Force.nActionEnd = GetLogicFrameCount() + nTotal
		_HM_Force.bActionDec = bDec
	end
end

-- update otaction bar
_HM_Force.UpdateOTActionBar = function()
	if not HM_Force.bActionTime or not _HM_Force.nActionTotal then
		return
	end
	local frame = Station.Lookup("Topmost/OTActionBar")
	if not frame or not frame:IsVisible() then
		_HM_Force.nActionTotal = nil
		return
	end
	local nFrame = _HM_Force.nActionEnd - GetLogicFrameCount()
	local nTotal = _HM_Force.nActionTotal
	if nFrame < 0 then
		_HM_Force.nActionTotal = nil
		nFrame = 0
	end
	local handle = frame:Lookup("", "Handle_Common")
	local hText = handle:Lookup("Text_Name")
	if not handle:IsVisible() then
		hText = frame:Lookup("", "Handle_GaiBang"):Lookup("Text_GBName")
	end
	local szText = string.gsub(hText:GetText(), " %(.-%)$", "")
	if not _HM_Force.bActionDec then
		nFrame = nTotal - nFrame
	end
	hText:SetText(szText .. string.format(" (%.2f/%.2f)", nFrame / 16, nTotal / 16))
end

-- on wanted msg
_HM_Force.OnMsgAnnounce = function(szMsg)
	local _, _, sM, sN = string.find(szMsg, _L["Now somebody pay (%d+) gold to buy life of (.-)"])
	if sM and sN == GetClientPlayer().szName then
		local fW = function()
			OutputWarningMessage("MSG_WARNING_RED", _L("Congratulations, you offered a reward [%s] gold!", sM))
			PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
		end
		SceneObject_SetTitleEffect(TARGET.PLAYER, GetClientPlayer().dwID, 47)
		fW()
		HM.DelayCall(2000, fW)
		HM.DelayCall(4000, fW)
		_HM_Force.bHasWanted = true
	end
end

-- try to replace horse via UUID
_HM_Force.tPlayHorse = {
	[3278] = true,	-- 小毛驴
	[5781] = true,	-- 银铃
	[7722] = true,	-- 神机·木轮
	[12160] = true,	-- 太白仙鹿
	[13605] = true,	-- 太白仙鹿
	[49667] = true,	-- 双峰驼·祥祥
	[58147] = true,	-- 西山秘宝·虚位交椅
	[58148] = true,	-- 西山秘宝·虚空交椅
	[60358] = true,	-- 渡情
	[63440] = true,	-- 鸾
	[90491] = true,	-- 咫尺天涯
	[90728] = true,	-- 卷黄尘 
}
_HM_Force.ReplaceHorse = function()
	-- is now a play horse
	local me = GetClientPlayer()
	local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.HORSE)
	-- find fastest horse to replace it
	if not item or _HM_Force.tPlayHorse[item.nUiId] then
		local dwBox, dwX, nSpeed
		for i = 1, BigBagPanel_nCount do
			local dwSize = me.GetBoxSize(i) or 0
			for j = 0, dwSize - 1 do
				local item = me.GetItem(i, j)
				if item and not _HM_Force.tPlayHorse[item.nUiId]
					and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE
				then
					local _nSpeed = nil
					OutputItemTip(UI_OBJECT_ITEM, i, j)
					local hM = Station.Lookup("Topmost1/TipPanel_Normal", "Handle_Message")
					for x = 0, hM:GetItemCount() - 1, 1 do
						local hT = hM:Lookup(x)
						if hT:GetType() == "Text" then
							local szSpeed = string.match(hT:GetText(), "(%d+)%%$")
							if szSpeed then
								_nSpeed = tonumber(szSpeed)
								break
							end
						end
					end
					HideTip(false)
					if _nSpeed and not dwBox or _nSpeed > nSpeed then
						dwBox, dwX, nSpeed = i, j, _nSpeed
					end
				end
			end
		end
		if dwBox then
			me.ExchangeItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.HORSE)
		end
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Force.PS = {}

-- init panel
_HM_Force.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	-- tian che
	---------------
	ui:Append("Text", { txt = g_tStrings.tForceTitle[3], x = 0, y = 0, font = 27 })
	-- switch actionbar page
	ui:Append("WndCheckBox", { txt = _L["Auto swith actionbar page of horse states (for TC, bind to P.1/3)"], checked = HM_Force.bHorsePage })
	:Pos(10, 28):Click(function(bChecked)
		HM_Force.bHorsePage = bChecked
	end)
	-- hungry
	ui:Append("WndCheckBox", { txt = _L["Alert when horse is hungry"], checked = HM_Force.bFeedHorse })
	:Pos(10, 56):Click(function(bChecked)
		HM_Force.bFeedHorse = bChecked
	end)
	-- wu du
	---------------
	ui:Append("Text", { txt = g_tStrings.tForceTitle[6], x = 0, y = 92, font = 27 })
	-- disappear
	local nX = ui:Append("WndCheckBox", { txt = _L["Alert when pet disappear unexpectedly (for 5D)"], checked = HM_Force.bAlertPet })
	:Pos(10, 120):Click(function(bChecked)
		HM_Force.bAlertPet = bChecked
	end):Pos_()
	-- replace horse
	ui:Append("WndCheckBox", { txt = _L["Replace horse in fighting"], checked = HM_Force.bHorseReplace })
	:Pos(nX + 10, 56):Click(function(bChecked)
		HM_Force.bHorseReplace = bChecked
	end)
	-- mark pet
	ui:Append("WndCheckBox", { txt = _L["Mark pet"], checked = HM_Force.bMarkPet })
	:Pos(nX + 10, 120):Click(function(bChecked)
		HM_Force.bMarkPet = bChecked
		_HM_Force.UpdatePetMark(bChecked)
	end)
	-- guding
	local nX2 = ui:Append("WndCheckBox", { txt = _L["Display GUDING of teammate, change color"], checked = HM_Guding.bEnable })
	:Pos(10, 148):Click(function(bChecked)
		HM_Guding.bEnable = bChecked
	end):Pos_()
	ui:Append("Shadow", "Shadow_Color", { x = nX2 + 2, y = 150, w = 18, h = 18 })
	:Color(unpack(HM_Guding.color)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Shadow_Color"):Color(r, g, b)
			HM_Guding.color = { r, g, b }
		end)
	end)
	ui:Append("WndCheckBox", "Check_Say", { txt = _L["Auto talk in team channel after puting GUDING"], checked = HM_Guding.bAutoSay })
	:Pos(nX + 10, 148):Enable(HM_Guding.bEnable):Click(function(bChecked)
		HM_Guding.bAutoSay = bChecked
		ui:Fetch("Edit_Say"):Enable(bChecked)
	end)
	ui:Append("WndEdit", "Edit_Say", { x = 13, y = 176, multi = true, limit = 512, w = 500, h = 50 })
	:Text(HM_Guding.szSay):Enable(HM_Guding.bAutoSay):Change(function(szText)
		HM_Guding.szSay = szText
	end)
	-- other
	---------------
	ui:Append("Text", { txt = _L["Others"], x = 0, y = 240, font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Show draggable energy bar"], checked = HM_Force.bEngBar })
	:Pos(10, 268):Click(function(bChecked)
		HM_Force.bEngBar = bChecked
		HM_EngBar.Switch(bChecked)
	end)
	-- debuff type num
	local nX2 = ui:Append("WndCheckBox", { txt = _L["Alert when my same type of debuff reached a certain number "], checked = HM_Force.bWarningDebuff })
	:Pos(10, 296):Click(function(bChecked)
		HM_Force.bWarningDebuff = bChecked
		ui:Fetch("Combo_DebuffNum"):Enable(bChecked)
	end):Pos_()
	ui:Append("WndComboBox", "Combo_DebuffNum", { x = nX2 + 10, y = 296, w = 50, h = 25 })
	:Enable(HM_Force.bWarningDebuff):Text(tostring(HM_Force.nDebuffNum)):Menu(function()
		local m0 = {}
		for i = 1, 10 do
			table.insert(m0, { szOption = tostring(i), fnAction = function()
				HM_Force.nDebuffNum = i
				ui:Fetch("Combo_DebuffNum"):Text(tostring(i))
			end })
		end
		return m0
	end)
	-- otaction time
	local nX2 = ui:Append("WndCheckBox", { txt = _L["Show time description of OTActionBar"], checked = HM_Force.bActionTime })
	:Pos(10, 324):Click(function(bChecked)
		HM_Force.bActionTime = bChecked
		if not bChecked then
			_HM_Force.nActionTotal = nil
		end
	end):Pos_()
	-- be wanted alert
	ui:Append("WndCheckBox", { txt = _L["Alert when I am wanted publishing online"], checked = HM_Force.bAlertWanted })
	:Pos(nX2 + 10, 324):Click(function(bChecked)
		HM_Force.bAlertWanted = bChecked
		if bChecked then
			RegisterMsgMonitor(_HM_Force.OnMsgAnnounce, {"MSG_GM_ANNOUNCE"})
		else
			UnRegisterMsgMonitor(_HM_Force.OnMsgAnnounce, {"MSG_GM_ANNOUNCE"})
		end
	end)
end

-- conflict check
_HM_Force.PS.OnConflictCheck = function()
	if Ktemp and HM_Force.bHorsePage then
		Ktemp.bchange = false
	end
	if OTAPlus and HM_Force.bActionTime then
		OTAPlus.bTime = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- horse
HM.RegisterEvent("NPC_ENTER_SCENE", _HM_Force.OnNpcEnter)
HM.RegisterEvent("NPC_LEAVE_SCENE", _HM_Force.OnNpcLeave)
HM.RegisterEvent("NPC_DISPLAY_DATA_UPDATE", _HM_Force.OnNpcUpdate)
HM.RegisterEvent("LOADING_END", 	function()
	local buff = Table_GetBuff(374, 1)
	if buff then
		buff.bShowTime = 1
	end
end)
HM.RegisterEvent("SYNC_ROLE_DATA_END", function()
	_HM_Force.OnRideHorse()
	if HM_Force.bAlertWanted then
		RegisterMsgMonitor(_HM_Force.OnMsgAnnounce, {"MSG_GM_ANNOUNCE"})
	end
	HM_EngBar.Switch(HM_Force.bEngBar)
end)
HM.RegisterEvent("PLAYER_STATE_UPDATE", function()
	if arg0 == GetClientPlayer().dwID then
		_HM_Force.OnRideHorse()
		if _HM_Force.bHasWanted then
			SceneObject_SetTitleEffect(TARGET.PLAYER, arg0, 47)
		end
	end
end)
HM.RegisterEvent("SYS_MSG", function()
	local me = GetClientPlayer()
	-- 读条技能
	if arg0 == "UI_OME_SKILL_CAST_LOG" then
		-- on prepare 任驰骋
		if HM_Force.bHorseReplace and arg1 == me.dwID and arg2 == 433 and me.bFightState then
			_HM_Force.ReplaceHorse()
		end
		-- on prepare 骑乘
		if HM_Force.bFeedHorse and arg1 == me.dwID and (arg2 == 433 or arg2 == 53 or Table_GetSkillName(arg2, 1) == Table_GetSkillName(53, 1)) then
			local it = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.HORSE)
			if it then
				OutputItemTip(UI_OBJECT_ITEM, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.HORSE)
				local hM = Station.Lookup("Topmost1/TipPanel_Normal", "Handle_Message")
				for i = 0, hM:GetItemCount() - 1, 1 do
					local hT = hM:Lookup(i)
					if hT:GetType() == "Text" and hT:GetFontScheme() == 164 then
						local szFullMeasure = HM.Trim(hT:GetText())
						local tDisplay = g_tTable.RideSubDisplay:Search(it.nDetail)
						if tDisplay and szFullMeasure ~= tDisplay.szFullMeasure3 then
							OutputWarningMessage("MSG_WARNING_YELLOW", Table_GetItemName(it.nUiId) .. ": " .. szFullMeasure)
							PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
						end
						break
					end
				end
				HideTip(false)
			end
		end
	end
	-- 重伤后删除头顶效果
	if arg0 == "UI_OME_DEATH_NOTIFY" then
		if _HM_Force.bHasWanted and arg1 == me.dwID then
			_HM_Force.bHasWanted = nil
			SceneObject_SetTitleEffect(TARGET.PLAYER, arg1, 0)
		end
	end
	-- 技能释放失败，再次检查坐骑
	if arg0 == "UI_OME_SKILL_RESPOND" and arg1 == SKILL_RESULT_CODE.FAILED and HM_Force.bHorseReplace then
		if me.bFightState and me.GetKungfuMount().dwSkillID == 10026 then
			_HM_Force.ReplaceHorse()
		end
	end
end)
HM.RegisterEvent("DO_SKILL_CAST", function()
	if arg0 == GetClientPlayer().dwID then
		-- 献祭、各种召唤：2965，2221 ~ 2226
		if arg1 == 2965 or (arg1 >= 2221 and arg1 <= 2226) then
			_HM_Force.nFrameXJ = GetLogicFrameCount()
		end
	end
end)
HM.RegisterEvent("OT_ACTION_PROGRESS_BREAK", function()
	if arg0 == GetClientPlayer().dwID then
		_HM_Force.nActionTotal = nil
	end
end)
HM.RegisterEvent("OT_ACTION_PROGRESS_UPDATE", function()
	if _HM_Force.nActionTotal then
		_HM_Force.nActionTotal = _HM_Force.nActionTotal + arg0
		_HM_Force.nActionEnd = _HM_Force.nActionEnd + arg0
	end
end)
HM.RegisterEvent("DO_SKILL_PREPARE_PROGRESS", function()
	_HM_Force.SaveOTAction(arg0, false)
end)
HM.RegisterEvent("DO_SKILL_CHANNEL_PROGRESS", function()
	_HM_Force.SaveOTAction(arg0, true)
end)
HM.RegisterEvent("DO_SKILL_HOARD_PROGRESS", function()
	_HM_Force.SaveOTAction(arg0, false)
end)
HM.RegisterEvent("DO_PICK_PREPARE_PROGRESS", function()
	_HM_Force.SaveOTAction(arg0, false)
end)
HM.RegisterEvent("DO_CUSTOM_OTACTION_PROGRESS ", function()
	_HM_Force.SaveOTAction(arg0, arg2 ~= 0)
end)
HM.RegisterEvent("DO_RECIPE_PREPARE_PROGRESS", function()
	_HM_Force.SaveOTAction(arg0, false)
end)
HM.RegisterEvent("BUFF_UPDATE", _HM_Force.OnBuffUpdate)
HM.BreatheCall("HM_OTAction", _HM_Force.UpdateOTActionBar)

-- add to HM panel
HM.RegisterPanel(_L["School feature"], 327, nil, _HM_Force.PS)
