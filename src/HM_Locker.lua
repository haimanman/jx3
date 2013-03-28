--
-- 海鳗插件：目标锁定、TAB 增强
--

HM_Locker = {
	bLockLeave = true,	-- 锁定脱离再回归视线的目标
	bLockFight = true,	-- 战斗中点地面不丢目标
	bLockTiger = true,	-- 虎跑时锁定目标
	bWhisperSel = true,	-- 密聊快速选择，密聊：11 速度选择此人（若在身边）
	tSearchTarget = { OnlyPlayer = false, OnlyNearDis = true, MidAxisFirst = false, Weakness = false },
	bLockScoff = true,	-- 自动还原目标
}

for k, _ in pairs(HM_Locker) do
	RegisterCustomData("HM_Locker." .. k)
end

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Locker = {
	bLeave = false,	-- 目标是否离开视线
	nTigerFrame = 0,	-- 虎跑切目标的帧次
	dwLastID = 0,		-- 最近的目标
	dwPrevID = 0,		-- 上次的目标
	nLastFrame = 0,	-- 最近目标改变帧次
	nLastSys = 0,
	tLocker = {},
	nScoffFrame = 0,	-- 被技能命中的帧次（技能）
	dwScoffer = 0,
	nScoffFrame2 = 0,	-- 嘲讽 BUFF 帧次
	dwScoffer2 = 0,	-- 嘲讽 BUFF 源
}

-- sysmsg
_HM_Locker.Sysmsg = function(szMsg)
	HM.Sysmsg(szMsg, _L["HM_Locker"])
end

-- debug
_HM_Locker.Debug = function(szMsg)
	HM.Debug(szMsg, _L["HM_Locker"])
end

-- set prev target
_HM_Locker.SetPrevTarget = function()
	local nFrame = GetLogicFrameCount() - _HM_Locker.nLastFrame
	if _HM_Locker.dwPrevID ~= 0 and nFrame >= 0 and nFrame < 16 then
		local tar = HM.GetTarget(_HM_Locker.dwPrevID)
		if tar and tar.nMoveState ~= MOVE_STATE.ON_DEATH then
			HM.SetTarget(tar.dwID)
			_HM_Locker.dwPrevID = tar.dwID
			return _HM_Locker.Sysmsg(_L("Restore previous target [%s]", tar.szName))
		end
	end
end

-- check to lock target
-- fnAction = function(dwCurID, dwLastID)
_HM_Locker.AddLocker = function(fnAction)
	table.insert(_HM_Locker.tLocker, fnAction)
end

-- check lock fight
_HM_Locker.CheckLockFight = function(dwCurID, dwLastID)
	local me = GetClientPlayer()
	if HM_Locker.bLockFight and dwCurID == 0 and me.bFightState and me.nMoveState ~= MOVE_STATE.ON_JUMP then
		local nFrame = GetLogicFrameCount()
		if HM.IsDps(me) then
			if IsEnemy(me.dwID, dwLastID) then
				if nFrame < _HM_Locker.nLastSys or (nFrame - _HM_Locker.nLastSys) > 12 then
					_HM_Locker.nLastSys = nFrame
					_HM_Locker.Sysmsg(_L["Keep attack target in fighting"])
				end
				return true
			end
		else
			if not IsEnemy(me.dwID, dwLastID) then
				if nFrame < _HM_Locker.nLastSys or (nFrame - _HM_Locker.nLastSys) > 12 then
					_HM_Locker.nLastSys = nFrame
					_HM_Locker.Sysmsg(_L["Keep heal target in fighting"])
				end
				return true
			end
		end
	end
end

-- check lock tiger run
_HM_Locker.CheckLockTiger = function(dwCurID, dwLastID)
	local nFrame = GetLogicFrameCount() - _HM_Locker.nTigerFrame
	if nFrame >= 0 and nFrame< 16 then
		local tar = HM.GetTarget(dwLastID)
		if tar and HM.GetDistance(tar) < 15 then
			--_HM_Locker.Sysmsg(_L["Keep attack target in HUPAO loops"])
			_HM_Locker.Debug("keep attack taret in hupao loops")
			return true
		end
	end
end

-- check lock scoff
_HM_Locker.CheckLockScoff = function(dwCurID, dwLastID)
	local nFrame = GetLogicFrameCount() - _HM_Locker.nScoffFrame
	if HM_Locker.bLockScoff and nFrame >= 0 and nFrame < 16 and _HM_Locker.dwScoffer == dwCurID then
		_HM_Locker.Debug("ignore changing target for scoff skill hit")
		return true
	end
end

-- check lock scoff2
_HM_Locker.CheckLockScoff2 = function(dwCurID, dwLastID)
	local nFrame = GetLogicFrameCount() - _HM_Locker.nScoffFrame2
	if HM_Locker.bLockScoff and nFrame >= 0 and nFrame < 16 and _HM_Locker.dwScoffer2 == dwCurID then
		_HM_Locker.Debug("ignore changing target for scoff buff")
		return true
	end
end

-- update enemy search options
_HM_Locker.UpdateSearchTarget = function()
	if not SearchTarget_IsOldVerion() then
		for k, v in pairs(HM_Locker.tSearchTarget) do
			SearchTarget_SetOtherSettting(k, v, "Enmey")
			SearchTarget_SetOtherSettting(k, v, "Ally")
		end
	end
end

-- only search player
_HM_Locker.SearchOnlyPlayer = function(bEnable)
	if bEnable == nil then
		bEnable = not  HM_Locker.tSearchTarget.OnlyPlayer
		if _HM_Locker.OnlyPlayerBox then
			return _HM_Locker.OnlyPlayerBox:Check(bEnable)
		end
	end
	HM_Locker.tSearchTarget.OnlyPlayer = bEnable
	_HM_Locker.UpdateSearchTarget()
	if bEnable then
		HM.Sysmsg(_L["Enable TAB only select player"])
	else
		HM.Sysmsg(_L["Disable TAB only select player"])
	end
end

-------------------------------------
-- 事件函数
-------------------------------------
-- update target
_HM_Locker.OnUpdateTarget = function()
	if TargetPanel_GetOpenState() then
		return
	end
	local me = GetClientPlayer()
	local dwType, dwID = me.GetTarget()
	if _HM_Locker.dwLastID ~= dwID then
		_HM_Locker.Debug("update target [#" .. dwType .. "#" .. dwID .. "]")
		-- always allowed to selectself
		if dwID ~= me.dwID and _HM_Locker.dwLastID ~= 0 then
			local tar0 = HM.GetTarget(_HM_Locker.dwLastID)
			if tar0 and tar0.nMoveState ~= MOVE_STATE.ON_DEATH then
				for _, v in ipairs(_HM_Locker.tLocker) do
					if v(dwID, _HM_Locker.dwLastID) then
						return HM.SetTarget(_HM_Locker.dwLastID)
						--return _HM_Locker.Sysmsg(_L("Keep locked target [%s]", tar0.szName))
					end
				end
			end
		end
		-- save new last
		if not _HM_Locker.bLeave or dwID ~= 0 then
			_HM_Locker.bLeave, _HM_Locker.nLastFrame = false, GetLogicFrameCount()
			_HM_Locker.dwPrevID, _HM_Locker.dwLastID = _HM_Locker.dwLastID, dwID
		end
	end
end

-- target levave
 _HM_Locker.OnLeave = function()
	if HM_Locker.bLockLeave and _HM_Locker.dwLastID == arg0 then
		_HM_Locker.Debug("target leave scene [#" .. arg0 .. "]")
		_HM_Locker.bLeave = true
	end
end

-- target enter
_HM_Locker.OnEnter = function()
	if HM_Locker.bLockLeave and _HM_Locker.dwLastID == arg0 then
		_HM_Locker.Debug("locked target enter scene [#" .. arg0 .. "]")
		_HM_Locker.bLeave = false
		HM.SetTarget(_HM_Locker.dwLastID)
	end
end

-- cast tigger switch
_HM_Locker.OnSkillCast = function()
	if HM_Locker.bLockTiger and arg0 == GetClientPlayer().dwID then
		if arg1 == 1592 then
			_HM_Locker.nTigerFrame = GetLogicFrameCount()
		elseif arg1 == 1589 then
			_HM_Locker.Sysmsg(_L["Keep attack target in HUPAO loops"])
		end
	end
end

-- player talk to quick select target
-- arg0：dwTalkerID，arg1：nChannel，arg2：bEcho，arg3：szName
_HM_Locker.OnPlayerTalk = function()
	if not HM_Locker.bWhisperSel then return end
	local me = GetClientPlayer()
	if me and arg0 == me.dwID and arg1 == PLAYER_TALK_CHANNEL.WHISPER and arg2 == true then
		local t = me.GetTalkData()
		if #t == 1 and t[1].type == "text" and t[1].text == "11" then
			local szName = arg3
			for _, v in ipairs(HM.GetAllPlayer()) do
				if v.szName == arg3 then
					HM.SetTarget(TARGET.PLAYER, v.dwID)
					break
				end
			end
		end
	end
end

-- buff update：
-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
-- arg8：nLevel，arg9：dwSkillSrcID
-- 512=定军，761=众佛，1488=执迷，1729=风吹荷，2503=蟾躁，
-- 2707=归去来棍，4059=极乐，4198=慈悲，4147=朝圣，4486=极乐
_HM_Locker.OnBuffUpdate = function()
	local me = GetClientPlayer()
	if arg0 == me.dwID and not arg1 and
		(arg4 == 512 or arg4 == 761 or arg4 == 1488 or arg4 == 1729 or arg4 == 2503
			or arg4 == 2707 or arg4 == 4059 or arg4 == 4198 or arg4 == 4147 or arg4 == 4486)
	then
		local _, tarID = me.GetTarget()
		_HM_Locker.Debug("get scoff buff [" .. HM.GetBuffName(arg4) .. "#" .. arg4 .. "]")
		if tarID == arg9 then
			_HM_Locker.SetPrevTarget()
		end
		_HM_Locker.dwScoffer2 = arg9
		_HM_Locker.nScoffFrame2 = GetLogicFrameCount()
	end
end

-- cast tigger switch --
-- 1665=风吹荷，402=定军，234=万佛朝宗，236=摩诃无量，
-- 2476=蟾躁，2589=归去来棍，3982=慈悲愿，3985=朝圣言，3971=极乐引
_HM_Locker.OnSkillHit = function(dwCaster, dwTarget, dwID, dwLevel)
	if HM_Locker.bLockScoff and dwTarget == GetClientPlayer().dwID then
		if dwID == 234 or dwID == 236 or dwID == 402 or dwID == 1665
			or dwID == 2476 or dwID == 2589 or dwID == 3982 or dwID == 3985 or dwID == 3971
		then
			local _, tarID = GetClientPlayer().GetTarget()
			_HM_Locker.Debug("be hit scoff skill [" .. HM.GetSkillName(dwID) .. "#" .. dwID .. "]")
			if tarID == dwCaster then
				-- FIXME：JJC 可能会因为检测读条导致目标切换不正常
				_HM_Locker.SetPrevTarget()
			end
			_HM_Locker.dwScoffer = dwCaster
			_HM_Locker.nScoffFrame = GetLogicFrameCount()
		end
	end
end

-- register locker
_HM_Locker.AddLocker(_HM_Locker.CheckLockFight)
_HM_Locker.AddLocker(_HM_Locker.CheckLockTiger)
_HM_Locker.AddLocker(_HM_Locker.CheckLockScoff)
_HM_Locker.AddLocker(_HM_Locker.CheckLockScoff2)

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Locker.PS = {}

-- deinit panel
_HM_Locker.PS.OnPanelDeactive = function(frame)
	_HM_Locker.OnlyPlayerBox = nil
end

-- init panel
_HM_Locker.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- locker
	ui:Append("Text", { txt = _L["Target locker"], font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["Lock target when it leave scene"], x = 10, y = 28, checked = HM_Locker.bLockLeave })
	:Click(function(bChecked)
		HM_Locker.bLockLeave = bChecked
	end):Pos_()
	ui:Append("Text", { txt = _L["(Auto select on entering scene)"], x = nX, y = 28, font = 161 })
	ui:Append("WndCheckBox", { x = 10, y = 56, checked = HM_Locker.bLockFight })
	:Text(_L["Keep current attack/heal target in fighting when click ground"]):Click(function(bChecked)
		HM_Locker.bLockFight = bChecked
	end)
	ui:Append("WndCheckBox", { x = 10, y = 84, checked = HM_Locker.bLockTiger })
	:Text(_L["Lock attack target when use HUPAO skill"]):Click(function(bChecked)
		HM_Locker.bLockTiger = bChecked
	end)
	-- tab enhance
	local bNew, tOption = not SearchTarget_IsOldVerion(), HM_Locker.tSearchTarget
	ui:Append("Text", { txt = _L["TAB enhancement (must enable new target policy)"], x = 0, y = 120, font = 27 })
	_HM_Locker.OnlyPlayerBox = ui:Append("WndCheckBox", { x = 10, y = 148, enable = bNew, checked = tOption.OnlyPlayer })
	nX = _HM_Locker.OnlyPlayerBox:Text(_L["Player only (not NPC, "]):Click(_HM_Locker.SearchOnlyPlayer):Pos_()
	nX = ui:Append("Text", { x = nX, y = 148, txt = _L["Hotkey"] }):Click(HM.SetHotKey):Pos_()
	ui:Append("Text", { x = nX , y = 148, txt = HM.GetHotKey("OnlyPlayer") .._L[") "] })
	nX = ui:Append("WndRadioBox", { x = 10, y = 176, checked = tOption.Weakness, group = "tab" })
	:Text(_L["Priority less HP"]):Enable(bNew):Click(function(bChecked)
		tOption.Weakness = bChecked
		_HM_Locker.UpdateSearchTarget()
	end):Pos_()
	nX = ui:Append("WndRadioBox", { x = nX + 20, y = 176, checked = tOption.OnlyNearDis, group = "tab" })
	:Text(_L["Priority closer"]):Enable(bNew):Click(function(bChecked)
		tOption.OnlyNearDis = bChecked
		_HM_Locker.UpdateSearchTarget()
	end):Pos_()
	nX = ui:Append("WndRadioBox", { x = nX + 20, y = 176, checked = tOption.MidAxisFirst, group = "tab" })
	:Text(_L["Priority less face angle"]):Enable(bNew):Click(function(bChecked)
		tOption.MidAxisFirst = bChecked
		_HM_Locker.UpdateSearchTarget()
	end):Pos_()
	-- whisper select
	ui:Append("Text", { txt = _L["Select target by whisper"], x = 0, y = 212, font = 27 })
	ui:Append("WndCheckBox", { x = 10, y = 240, checked = HM_Locker.bWhisperSel })
	:Text(_L["Select as target when you send 11 to around player"]):Click(function(bChecked)
		HM_Locker.bWhisperSel = bChecked
	end)
	-- scoff
	ui:Append("Text", { txt = _L["Restore target"], x = 0, y = 276, font = 27 })
	nX = ui:Append("WndCheckBox", { x = 10, y = 304, checked = HM_Locker.bLockScoff })
	:Text(_L["Auto restore target (hit by some special skills)"]):Click(function(bChecked)
		HM_Locker.bLockScoff = bChecked
	end)
end

-- player menu
_HM_Locker.PS.OnPlayerMenu = function()
	return {
		szOption = _L["Enable TAB select player only"] .. HM.GetHotKey("OnlyPlayer", true),
		bCheck = true, bChecked = HM_Locker.tSearchTarget.OnlyPlayer,
		fnAction = function(d, b) _HM_Locker.SearchOnlyPlayer(b) end
	}
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("SYNC_ROLE_DATA_END", _HM_Locker.UpdateSearchTarget)
HM.RegisterEvent("UPDATE_SELECT_TARGET",  _HM_Locker.OnUpdateTarget)
HM.RegisterEvent("NPC_LEAVE_SCENE", _HM_Locker.OnLeave)
HM.RegisterEvent("PLAYER_LEAVE_SCENE", _HM_Locker.OnLeave)
HM.RegisterEvent("NPC_ENTER_SCENE", _HM_Locker.OnEnter)
HM.RegisterEvent("PLAYER_ENTER_SCENE", _HM_Locker.OnEnter)
HM.RegisterEvent("DO_SKILL_CAST", _HM_Locker.OnSkillCast)
HM.RegisterEvent("PLAYER_TALK", _HM_Locker.OnPlayerTalk)
--HM.RegisterEvent("BUFF_UPDATE", _HM_Locker.OnBuffUpdate)
HM.RegisterEvent("SYS_MSG", function()
	if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
		_HM_Locker.OnSkillHit(arg1, arg2, arg4, arg5)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
		_HM_Locker.OnSkillHit(arg1, arg2, arg5, arg6)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["Lock/Select"], 3353, _L["Target"], _HM_Locker.PS)

-- hotkey
HM.AddHotKey("OnlyPlayer", _L["TAB player only"],  _HM_Locker.SearchOnlyPlayer)
