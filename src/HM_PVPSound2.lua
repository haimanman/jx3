-- 海鳗插件：PVP斩杀特效、音效
-- 素材及创意源自千渡、斩浪发布的 jx3PVPSound
-- 特别注意：本插件的音效和输出文字只有玩家自己可以听见、看见哦！
--

HM_PVPSound2 = {
	bSound = true,	-- 播放声音
	bText = true,		-- 浮动文字
}

RegisterCustomData("HM_PVPSound2.bSound")
RegisterCustomData("HM_PVPSound2.bText")

--[[
local _, dwID = GetClientPlayer().GetTarget()
--FireUIEvent("KILL_PLAYER_HIGHEST_TITLE", GetClientPlayer().dwID)
FireUIEvent("SYS_MSG", "UI_OME_DEATH_NOTIFY",  dwID, 0, _L["HMM1"])
--]]

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_PVPSound2 = {
	nLastFrame = 0,
	szSoundPath = "interface\\HM\\hero\\",
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
_HM_PVPSound2.GetKillEffect = function()
	local me = GetClientPlayer()
	local tSound = _HM_PVPSound2.tNormal[me.nGender]
	local nFrame = GetLogicFrameCount() - _HM_PVPSound2.nLastFrame
	_HM_PVPSound2.nLastFrame = GetLogicFrameCount()
	if nFrame >= 0 and nFrame < 160 then
		tSound = _HM_PVPSound2.tCont[me.nGender]
	end
	if tSound then
		local t = tSound[math.random(1, table.getn(tSound))]
		return t[1], t[2]
	end
end

-- 延迟半秒播放声音，避免嘈杂
_HM_PVPSound2.PlaySound = function(szSound)
	if not _HM_PVPSound2.szSound then
		HM.DelayCall(500, function()
			PlaySound(SOUND.CHARACTER_SPEAK, _HM_PVPSound2.szSoundPath .. _HM_PVPSound2.szSound)
			_HM_PVPSound2.szSound = nil
		end)
	end
	_HM_PVPSound2.szSound = szSound
end

-------------------------------------
-- 事件处理、初始化
-------------------------------------
-- 击杀最高战阶
_HM_PVPSound2.OnKillHighestTitle = function()
	local me, tar = GetClientPlayer(), GetPlayer(arg0)
	if not me or not tar then
		return
	end
	-- replace text
	if HM_PVPSound2.bText then
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
_HM_PVPSound2.OnDeathNotify = function(dwID, szKiller)
	if not IsPlayer(dwID) then return end
	local me, tar = GetClientPlayer(), GetPlayer(dwID)
	-- clear data on self-death
	if me.szName == szKiller and tar then
		local szTitle, szSound = _HM_PVPSound2.GetKillEffect()
		if not szTitle then
			return
		end
		-- play sound
		if HM_PVPSound2.bSound then
			_HM_PVPSound2.PlaySound(szSound)
		end
		-- show bowled text
		if HM_PVPSound2.bText then
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
_HM_PVPSound2.PS = {}

-- init panel
_HM_PVPSound2.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	ui:Append("Text", { txt = _L["PVP kill effect"], font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Play sound after killing"], x = 10, y = 28, checked = HM_PVPSound2.bSound })
	:Click(function(bChecked)
		HM_PVPSound2.bSound = bChecked
	end)
	ui:Append("WndCheckBox", { txt = _L["Show red text after killing"], x = 10, y = 56, checked = HM_PVPSound2.bText })
	:Click(function(bChecked)
		HM_PVPSound2.bText = bChecked
	end)
end

-- check conflict
_HM_PVPSound2.PS.OnConflictCheck = function()
	-- copatiable with single version
	if HM_PVPSound then
		HM_PVPSound.bSound = false
		HM_PVPSound.bText = false
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("KILL_PLAYER_HIGHEST_TITLE", _HM_PVPSound2.OnKillHighestTitle)
HM.RegisterEvent("SYS_MSG", function()
	if arg0 == "UI_OME_DEATH_NOTIFY" then
		_HM_PVPSound2.OnDeathNotify(arg1, arg3)
	end
end)

-- add to HM panel
HM.RegisterPanel(_L["PVP kill effect"], 2573, _L["Battle"], _HM_PVPSound2.PS)
