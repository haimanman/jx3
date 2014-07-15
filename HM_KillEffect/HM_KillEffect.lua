-- 海鳗插件：PVP斩杀特效、音效
-- 素材及创意源自千渡、斩浪发布的 jx3PVPSound
-- 特别注意：本插件的音效和输出文字只有玩家自己可以听见、看见哦！
--

HM_KillEffect = {
	bSound = true,	-- 播放声音
	bText = true,		-- 浮动文字
}
HM.RegisterCustomData("HM_KillEffect")

--[[
local _, dwID = GetClientPlayer().GetTarget()
--FireUIEvent("KILL_PLAYER_HIGHEST_TITLE", GetClientPlayer().dwID)
FireUIEvent("SYS_MSG", "UI_OME_DEATH_NOTIFY",  dwID, 0, GetClientPlayer().szName)
--]]

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_KillEffect = {
	nLastFrame = 0,
	szSoundPath = "interface\\HM\\HM_KillEffect\\sound\\",
	tNormal = {
		-- male
		[1] = {
			{ _L["Kill"], "male_normal_1.wav" },
			{ _L["Not dead?"], "male_normal_2.wav" },
		},
		-- female
		[2] = {
			{ _L["Kill one"], "female_normal_1.wav" },
			{ _L["Dead!"], "female_normal_2.wav" },
		},
	},
	tCont = {
		-- male
		[1] = {
			{ _L["Kill again"], "male_cont_1.wav" },
			{ _L["Beat again"], "male_cont_2.wav" },
		},
		-- female
		[2] = {
			{ _L["Kill another"], "female_cont_1.wav" },
			{ _L["Beat together"], "female_cont_2.wav" },
		},
	},
}

-- 获取斩杀的文字、音效文件
_HM_KillEffect.GetKillEffect = function()
	local me = GetClientPlayer()
	local tSound = _HM_KillEffect.tNormal[me.nGender]
	local nFrame = GetLogicFrameCount() - _HM_KillEffect.nLastFrame
	_HM_KillEffect.nLastFrame = GetLogicFrameCount()
	if nFrame >= 0 and nFrame < 160 then
		tSound = _HM_KillEffect.tCont[me.nGender]
	end
	if tSound then
		local t = tSound[math.random(1, table.getn(tSound))]
		return t[1], t[2]
	end
end

-- 延迟半秒播放声音，避免嘈杂
_HM_KillEffect.PlaySound = function(szSound)
	if not _HM_KillEffect.szSound then
		HM.DelayCall(500, function()
			PlaySound(SOUND.CHARACTER_SPEAK, _HM_KillEffect.szSoundPath .. _HM_KillEffect.szSound)
			_HM_KillEffect.szSound = nil
		end)
	end
	_HM_KillEffect.szSound = szSound
end

-------------------------------------
-- 事件处理、初始化
-------------------------------------
-- 击杀最高战阶
_HM_KillEffect.OnKillHighestTitle = function()
	local me, tar = GetClientPlayer(), GetPlayer(arg0)
	if not me or not tar then
		return
	end
	-- replace text
	if HM_KillEffect.bText then
		local handle = Station.Lookup("Lowest/CombatTextWnd", "")
		for i = 0, handle:GetItemCount() - 1, 1 do
			local text = handle:Lookup(i)
			if not text.bFree and text.dwOwner == me.dwID
				and string.sub(text:GetText(), 1, string.len(g_tStrings.STR_KILL)) == g_tStrings.STR_KILL
			then
				text:SetText("")
				break
			end
		end
	end
end

-- 死亡通知：要求玩家并且不是最高战阶
_HM_KillEffect.OnDeathNotify = function(dwID, szKiller)
	if not IsPlayer(dwID) then return end
	local me, tar = GetClientPlayer(), GetPlayer(dwID)
	-- clear data on self-death
	if me.szName == szKiller and tar then
		local szTitle, szSound = _HM_KillEffect.GetKillEffect()
		if not szTitle then
			return
		end
		-- play sound
		if HM_KillEffect.bSound then
			_HM_KillEffect.PlaySound(szSound)
		end
		-- show bowled text
		if HM_KillEffect.bText then
			local szInfo = szTitle
			if tar.szTitle and tar.szTitle ~= "" then
				szInfo = szInfo .. " <" .. tar.szTitle .. ">"
			end
			szInfo = szInfo .. " " .. tar.szName
			OnBowledCharacterHeadLog(me.dwID, szInfo, 199)
		end
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_KillEffect.PS = {}

-- init panel
_HM_KillEffect.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { txt = _L["PVP kill effect"], font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Play sound after killing"], x = 10, y = 28, checked = HM_KillEffect.bSound })
	:Click(function(bChecked)
		HM_KillEffect.bSound = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Show red text after killing"], x = 10, y = 56, checked = HM_KillEffect.bText })
	:Click(function(bChecked)
		HM_KillEffect.bText = bChecked
	end)
end

-- check conflict
_HM_KillEffect.PS.OnConflictCheck = function()
	-- copatiable with single version
	if HM_PVPSound then
		HM_PVPSound.bSound = false
		HM_PVPSound.bText = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("KILL_PLAYER_HIGHEST_TITLE", _HM_KillEffect.OnKillHighestTitle)
HM.RegisterEvent("SYS_MSG", function()
	if arg0 == "UI_OME_DEATH_NOTIFY" then
		_HM_KillEffect.OnDeathNotify(arg1, arg3)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["PVP kill effect"], 2573, _L["Battle"], _HM_KillEffect.PS)
