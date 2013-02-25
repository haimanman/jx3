--
-- ���������������һս��
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
-- ���غ����ͱ���
---------------------------------------------------------------------
local _HM_CampScore = {
	szName = "ս�׼���",
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

_HM_CampScore.Flash = function()
	local frame = Station.Lookup("Normal/CharacterPanel")
	local page_all = frame:Lookup("Page_Main")
	page_all:ActivePage(1)
	local page_camp = page_all:Lookup("Page_Camp")
	local handle = page_camp:Lookup("", "Handle_CampAll/Handle_RankInfo/Handle_RankContent")
	local image = handle:Lookup("Image_Rank2")
	local fPointPercentage = image:GetPercentage()
	HM_CampScore.nTitle = player.nTitle
	local nowpoint,nextpoint = _HM_CampScore.tRequirePoint[HM_CampScore.nTitle], _HM_CampScore.tRequirePoint[HM_CampScore.nTitle + 1]
	HM_CampScore.nPoint = math.floor(nowpoint + (nextpoint - nowpoint) * fPointPercentage + 0.5)
	HM_CampScore.nNeed = 1
	for i = #tRankPoint, 1, -1 do
		if _HM_CampScore.tRankPoint[i][1] > nowpoint - HM_CampScore.nPoint then
			HM_CampScore.nNeed = i
		end
	end
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
		return string.format("ǰ %3d ������", _HM_CampScore.tRankPoint[HM_CampScore.nNeed][2])
	else
		return string.format("ǰ %3d : %2d��%3d%%",
			_HM_CampScore.tRankPoint[i][2], _HM_CampScore.GetLevel(HM_CampScore.nPoint + _HM_CampScore.tRankPoint[i][1]))
	end
end

-------------------------------------
-- ���ý���
-------------------------------------
_HM_CampScore.PS = {}

-- init
_HM_CampScore.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	_HM_CampScore.Flash()
	ui:Append("Text", { txt = "��ѯ��һս��", x = 0, y = 0, font = 27 })
	-- gold
	nX = ui:Append("Text", { txt = string.format("��ǰս��: %2d��%3d%%",_HM_CampScore.GetLevel(HM_CampScore.nPoint)), x = 10, y = 28 }):Pos_()
	nX = ui:Append("WndComboBox", "Combo_Size1", { x = nX, y = 28, w = 100, h = 25 })
	:Text(_HM_CampScore.GetText(HM_CampScore.nDefault)):Menu(function()
		local m0 = {}
		for i = 1, #_HM_CampScore.tRankPoint do
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
	ui:Append("WndButton", { txt = "����", x = nX + 10, y = 28 }):AutoSize()
	:Click(_HM_CampScore.Flash)
end

---------------------------------------------------------------------
-- ע���¼�����ʼ��
---------------------------------------------------------------------
-- add to HM collector
HM.RegisterPanel(_HM_CampScore.szName, 119, _L["Others"], _HM_CampScore.PS)

