--
-- 海鳗插件：娱乐插件，输入趣味喊话文字
--

HM_Ent = {
	bAutoChat = true,	-- 直接发布聊天
}
HM.RegisterCustomData("HM_Ent")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_Ent = {
	tChat = {
		{ _L["Meteor shower"], _L[".:'* . . ;#:~ ,:'.:. *:. .:'* . . ;#:~ ,:'.:. *:. .:'* . . ;#:~ ,:'.:. *:. .:'* . . ;#:~ ,:'.:. *:."] },
		{ _L["Lara hand"], _L["./o\  /[]v[] lara hand TT TT o"] },
		{ _L["Bubbling"], _L["O`o. `. o popo `o. o `. O`oo. O `o. O`o. `. o gulu `o. o `. O`oo. `. o popo `o. o `. O`oo. O `o.oo"] },
		{ _L["Smile face"], _L["/ * #o(^o^)/~o/``:.(.)! / * #o(^o^)/~o/``:.(.)! / * #o(^o^)/~o/``:.(.)! / * #o(^o^)/~o/``:.(.)!"] },
		{ _L["Gymnastics"], _L["Broadcast gymnastics begin |-(..)-| /-(..)-\\ |-(..)-\\ /-(..)-\\  |-(..)-| |-(..)-\\ /-(..)-| /-(..)-\\."] },
		{ _L["GaGa"], _L["~o1 /|\/|\ \|/ \|/  / nn \ \> . </ /\|/\ /o ga~"] },
		{ _L["Kiss kiss"], _L["~|||||||||||~ (| |||||||||| ) | ^ ^ | ^/\$/\^ kiss you ~"] },
		{ _L["Meteor shower2"], _L["~C2~o3~`/ * '/ % '/ * '/ % '/ * '/ % '/ * '/ % '~C2~o3~`/ * '/ % '/ * '/ % '/ * '/ % '/ * '/ % '/"] },
		{ _L["Eye exes"], _L["15 words eye exercises: (>_>) (^_^) (<_<) (|_|)(>_>) (^_^) (<_<) (|_|)(>_>) (^_^) (<_<) (|_|) ... (T_T) (>_<) ( *_* )"] },
		{ _L["Eye exes2"], _L["Eye exercises enh: (^_|) (>_<)(|_^) (>_<)(^_|) (<_>)(|_^) (>_<)(^_|) ... (o_o) (V_V) (*_*) (@_@)"] },
		{ _L["Eye exes3"], _L["Eye exercises ultra: (/_/) (/_/) (/_\) (\_/) (\_-) (/_|) (|_\) (|_-) (\_\) (\_\) (|_-) (\_>) (/_|) (-_/(|_\) (\_-) ... (?_?)(*_^)(^_*)"] },
	},
}

-- set chat text
_HM_Ent.SetChat = function(szText)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if HM_Ent.bAutoChat then
		local nChannel, szName = EditBox_GetChannel()
		if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
			HM.Talk2(szName, szText)
		else
			HM.Talk2(nChannel, szText)
		end
	else
		edit:ClearText()
		edit:InsertText(szText)
	end
end

-------------------------------------
-- 个人信息发布
-------------------------------------
-- tinfo
_HM_Ent.tInfo = {
	{ szName = _L["Contribution"], nFrame = 17, bChecked = false, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nContribution)
	end },
	{ szName = _L["Justice"], nFrame = 25, bChecked = false, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nJustice)
	end },
	{ szName = _L["ExamPrint"], nFrame = 18, bChecked = false, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nExamPrint)
	end },
	{ szName = _L["ArenaAward"], nFrame = 167, bChecked = true, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nArenaAward)
	end },
	{ szName = _L["Prestige"], nFrame = 22, bChecked = true, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nCurrentPrestige)
	end },
	{ szName = _L["Titlepoint"], nFrame = 24, bChecked = true, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nTitlePoint) .. _L("(%d Title)", GetClientPlayer().nTitle)
	end },
	{ szName = _L["Money"], bChecked = true, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().GetMoney().nGold) .. "G"
	end },
	{ szName = _L["Coin"], nFrame = 15, bChecked = false, fnValue = function()
		return _HM_Ent.ReNum(GetClientPlayer().nCoin) end
	},
	{ szName = _L["Ping"], bChecked = true, fnValue = function()
		return _HM_Ent.ReNum(GetPingValue()/2)
	end },
	{ szName = "FPS",bChecked = true, fnValue = function() return GetFPS() end },
	{ szName = _L["EquipScore"], bChecked = true, fnValue = function()
		return GetClientPlayer().GetTotalEquipScore() end
	},
	{ szName = _L["KillCount"], bChecked = true, fnValue = function()
		return GetClientPlayer().dwKillCount end
	},
}

-- renum
_HM_Ent.ReNum = function(nNum)
	if not nNum then
		return "nil"
	elseif nNum >= 100000 then
		return _L("%.1fw", nNum / 10000)
	elseif nNum >= 10000 then
		return _L("%.2fw", nNum / 10000)
	else
		return string.format("%d", nNum)
	end
end

-- get info menu
_HM_Ent.GetInfoMenu = function()
	local tInfo, m0 = _HM_Ent.tInfo, {}
	for _, v in ipairs(tInfo) do
		local m1 = { szOption = v.szName, bCheck = true, bChecked = v.bChecked }
		--if v.nFrame then
			--m1.szIcon = "ui\\Image\\Common\\Money.UITex"
			--m1.nFrame = v.nFrame
			--m1.szLayer = "ICON_LEFT"
		--end
		m1.fnAction = function() v.bChecked = not v.bChecked end
		table.insert(m0, m1)
	end
	return m0
end

-- show info
_HM_Ent.ShowInfo = function()
	local nChannel, szName = EditBox_GetChannel()
	local szText = _L["@_@ Take look around a comparison, My "]
	for _, v in ipairs(_HM_Ent.tInfo) do
		if v.bChecked then
			szText = szText .. v.szName .. ": " .. v.fnValue() .. _L[", "]
		end
	end
	szText = string.sub(szText, 1, string.len(szText) - 2)
	if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		HM.Talk2(szName, szText)
	else
		HM.Talk2(nChannel, szText)
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_Ent.PS = {}

-- init
_HM_Ent.PS.OnPanelActive = function(frame)
	local ui, nX, nY = HM.UI(frame), 10, 0
	ui:Append("Text", { txt = _L["Fun chat"], x = 0, y = nY, font = 27 })
	ui:Append("WndCheckBox", { txt = _L["Send to current talk channel directly"], x = 10, y = nY + 28, checked = HM_Ent.bAutoChat })
	:Click(function(bChecked)
		HM_Ent.bAutoChat = bChecked
	end)
	nX, nY = 10, nY + 56
	for _, v in ipairs(_HM_Ent.tChat) do
		ui:Append("WndButton", { x = nX, y = nY, txt = v[1] }):Click(function() _HM_Ent.SetChat(v[2]) end)
		nX = nX + 110
		if nX > 400 then
			nX = 10
			nY = nY + 30
		end
	end
	if nX ~= 10 then
		nY = nY + 28
	end
	ui:Append("Text", { txt = _L["Tips: Used to pollute world channel may be reported and led to shield!"], x = 10, y = nY })
	-- info
	ui:Append("Text", { txt = _L["Personal data"], x = 0, y = nY + 36, font = 27 })
	nX = ui:Append("WndComboBox", { txt = _L["Select item"], x = 10, y = nY + 64, h = 25, w = 140 }):Menu(_HM_Ent.GetInfoMenu):Pos_()
	ui:Append("WndButton", { txt = _L["Publish to talk channel"], x = nX + 10, y = nY + 65 }):AutoSize(8):Click(_HM_Ent.ShowInfo)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM collector
HM.RegisterPanel(_L["Entertainment"], 336, _L["Recreation"], _HM_Ent.PS)
