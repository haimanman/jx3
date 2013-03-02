--
-- 海鳗插件：计算下一战阶
--
HM_CampScore = {
	nDefault = 0,
	--nTitle = 14,
	--nPoint = 525,
	--nNeed = 1,
}

for k, _ in pairs(HM_CampScore) do
	RegisterCustomData("HM_CampScore." .. k)
end

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_CampScore = {
	szName = "战阶计算",
	tRequirePoint = {
		[0] = 0,
		[1] = 5,
		[2] = 15,
		[3] = 30,
		[4] = 50,
		[5] = 75,
		[6] = 105,
		[7] = 140,
		[8] = 180,
		[9] = 225,
		[10] = 275,
		[11] = 330,
		[12] = 390,
		[13] = 455,
		[14] = 525,
	},
	tRankPoint = {
		--[0] = {"N/A", 0},
		[1] = {70, 3},
		[2] = {65, 10},
		[3] = {60, 20},
		[4] = {55, 40},
		[5] = {50, 70},
		[6] = {45, 110},
		[7] = {40, 150},
	}
}

_HM_CampScore.Debug = function(szMsg)
	HM.Debug(szMsg, "战阶计算")
end

_HM_CampScore.Flash = function()
	local player = GetClientPlayer()
	if not player then return end
	local frame = Station.Lookup("Normal/CharacterPanel")
	local page_all = frame:Lookup("Page_Main")
	page_all:ActivePage("Page_Camp")
	local page_camp = page_all:Lookup("Page_Camp")
	local handle = page_camp:Lookup("", "Handle_CampAll/Handle_RankInfo/Handle_RankContent")
	local image = handle:Lookup("Image_Rank2")
	local fPointPercentage = image:GetPercentage()
	HM_CampScore.nTitle = player.nTitle
	local nowpoint,nextpoint = _HM_CampScore.tRequirePoint[HM_CampScore.nTitle], _HM_CampScore.tRequirePoint[HM_CampScore.nTitle + 1]
	HM_CampScore.nPoint = math.floor(nowpoint + (nextpoint - nowpoint) * fPointPercentage + 0.5)
	HM_CampScore.nNeed = 0
	for i = #_HM_CampScore.tRankPoint, 1, -1 do
		--_HM_CampScore.Debug(_HM_CampScore.tRankPoint[i][1] .. ">" .. (nextpoint - HM_CampScore.nPoint) .. "?")
		if _HM_CampScore.tRankPoint[i][1] >= nextpoint - HM_CampScore.nPoint then
			HM_CampScore.nNeed = i
			break
		end
	end
	_HM_CampScore.Debug(HM_CampScore.nTitle .. "阶(" .. HM_CampScore.nPoint .. ") -> " .. HM_CampScore.nNeed)
end

_HM_CampScore.GetLevel = function(nPoint)
	local level, percent = 14, 100
	for i = 13, 1, -1 do
		if nPoint >= _HM_CampScore.tRequirePoint[i] then
			level = i
			break
		end
	end
	if level ~= 14 then
		local nowpoint,nextpoint = _HM_CampScore.tRequirePoint[level], _HM_CampScore.tRequirePoint[level + 1]
		percent= math.floor((nPoint - nowpoint) / (nextpoint - nowpoint) * 100)
	end
	return level, percent
end

_HM_CampScore.GetText = function(nIndex)
	if nIndex == 0 then
		if HM_CampScore.nNeed == 0 then
			--HM_CampScore.nTitle == 14 
			return string.format("***你已经 %2d 阶了***", HM_CampScore.nTitle)
		else
			return string.format("前 %3d 可升 %2d 阶", _HM_CampScore.tRankPoint[HM_CampScore.nNeed][2], HM_CampScore.nTitle + 1)
		end
	else
		return string.format("前 %3d : %2d阶%3d%%",
			_HM_CampScore.tRankPoint[nIndex][2], _HM_CampScore.GetLevel(HM_CampScore.nPoint + _HM_CampScore.tRankPoint[nIndex][1]))
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_CampScore.PS = {}

-- init
_HM_CampScore.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	_HM_CampScore.Flash()
	ui:Append("Text", { txt = "查询下一战阶", x = 0, y = 0, font = 27 })
	-- gold
	nX = ui:Append("Text", { txt = string.format("当前战阶: %2d阶%3d%%",_HM_CampScore.GetLevel(HM_CampScore.nPoint)), x = 10, y = 28 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size1", { x = 10, y = 56, w = 170, h = 25 })
	:Text(_HM_CampScore.GetText(HM_CampScore.nDefault)):Menu(function()
		local m0 = {}
		for i = 0, #_HM_CampScore.tRankPoint do
			local text = _HM_CampScore.GetText(i)
			table.insert(m0, {
				szOption = text,
				fnAction = function()
					HM_CampScore.nDefault = i
					ui:Fetch("Combo_Size1"):Text(text)
				end,
			})
		end
		return m0
	end):Pos_()
	ui:Append("WndButton", { txt = "更新", x = nX + 10, y = 28 }):AutoSize()
	:Click(_HM_CampScore.Flash)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM collector
HM.RegisterPanel(_HM_CampScore.szName, 119, _L["Others"], _HM_CampScore.PS)

